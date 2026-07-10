#!/usr/bin/env bash

declare -a git_cmd=(git)

base=""
head=""
repo_root=""
output_count=0
full_scan=0
disable_default_excludes=0

declare -a includes=()
declare -a excludes=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base="${2:-}"
      shift 2
      ;;
    --head)
      head="${2:-}"
      shift 2
      ;;
    --repo-root)
      repo_root="${2:-}"
      shift 2
      ;;
    --include)
      includes+=("${2:-}")
      shift 2
      ;;
    --exclude)
      excludes+=("${2:-}")
      shift 2
      ;;
    --disable-default-excludes)
      disable_default_excludes=1
      shift
      ;;
    --full-scan)
      full_scan=1
      shift
      ;;
    --output-count)
      output_count=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "${base}" || -z "${head}" ]]; then
  echo "Both --base and --head are required." >&2
  exit 2
fi

if [[ -z "${repo_root}" ]]; then
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -z "${repo_root}" ]]; then
    echo "Unable to resolve repo root. Run inside a git repository or pass --repo-root." >&2
    exit 1
  fi
fi

if ! "${git_cmd[@]}" -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v git.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    repo_root_win="$(wslpath -w "$repo_root" 2>/dev/null || true)"
    if [[ -n "$repo_root_win" ]] && git.exe -C "$repo_root_win" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      git_cmd=(git.exe)
      repo_root="$repo_root_win"
    fi
  fi
fi

if ! "${git_cmd[@]}" -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Unable to resolve a working git repository from '$repo_root'." >&2
  exit 1
fi

if [[ ${#includes[@]} -eq 0 ]]; then
  includes=("*")
fi

if [[ "$disable_default_excludes" -ne 1 ]]; then
  need_artefacts=1
  need_artifacts=1
  for pattern in "${excludes[@]}"; do
    [[ "$pattern" == ".scratch/*/artefacts/**" ]] && need_artefacts=0
    [[ "$pattern" == ".scratch/*/artifacts/**" ]] && need_artifacts=0
  done
  [[ "$need_artefacts" -eq 1 ]] && excludes+=(".scratch/*/artefacts/**")
  [[ "$need_artifacts" -eq 1 ]] && excludes+=(".scratch/*/artifacts/**")
fi

auto_full_scan=0
if [[ "${GITHUB_EVENT_NAME:-}" == "push" && "${GITHUB_REF:-}" == "refs/heads/main" ]]; then
  auto_full_scan=1
fi

use_full_scan=0
if [[ "$full_scan" -eq 1 || "$auto_full_scan" -eq 1 ]]; then
  use_full_scan=1
fi

declare -a pathspecs=()
for pattern in "${includes[@]}"; do
  [[ -n "$pattern" ]] && pathspecs+=("$pattern")
done
for pattern in "${excludes[@]}"; do
  [[ -n "$pattern" ]] && pathspecs+=(":(exclude)$pattern")
done

if [[ "$use_full_scan" -eq 1 ]]; then
  mapfile -t files < <("${git_cmd[@]}" -C "$repo_root" ls-files -- "${pathspecs[@]}")
else
  mapfile -t files < <("${git_cmd[@]}" -C "$repo_root" diff --name-only --diff-filter=ACMRTUXB "$base" "$head" -- "${pathspecs[@]}")
fi

cleaned=()
for f in "${files[@]}"; do
  [[ -n "$f" ]] && cleaned+=("$f")
done

if [[ "$output_count" -eq 1 ]]; then
  echo "${#cleaned[@]}"
  exit 0
fi

for f in "${cleaned[@]}"; do
  echo "$f"
done
