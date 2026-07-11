#Requires -Version 7.0
#Requires -PSEdition Core
# RuntimePolicy: core-first

[CmdletBinding()]
param(
  [string]$RepoRoot = "",
  [string]$OutputPath = "REPO_INDEX.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRootPath {
  param([string]$Candidate)

  if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
    return (Resolve-Path -LiteralPath $Candidate).Path
  }

  return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
}

function Get-RelativePathText {
  param(
    [string]$BasePath,
    [string]$TargetPath
  )

  $resolvedBase = (Resolve-Path -LiteralPath $BasePath).Path
  $resolvedTarget = (Resolve-Path -LiteralPath $TargetPath).Path
  return [System.IO.Path]::GetRelativePath($resolvedBase, $resolvedTarget).Replace('\\', '/')
}

function Format-TableCell {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return ""
  }

  return $Value.Replace("|", "\\|").Replace("`r", " ").Replace("`n", " ").Trim()
}

function Get-Frontmatter {
  param([string]$Path)

  $raw = Get-Content -LiteralPath $Path -Raw
  if (-not $raw.StartsWith("---`n") -and -not $raw.StartsWith("---`r`n")) {
    return @{}
  }

  $lines = $raw -split "`r?`n"
  if ($lines.Count -lt 3 -or $lines[0] -ne '---') {
    return @{}
  }

  $map = @{}
  for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ($line -eq '---') {
      break
    }

    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }

    if ($line -match '^([A-Za-z0-9_.-]+):\s*(.*)$') {
      $key = $Matches[1]
      $value = $Matches[2].Trim()
      $map[$key] = $value
    }
  }

  return $map
}

$resolvedRepoRoot = Resolve-RepoRootPath -Candidate $RepoRoot
$outputFile = Join-Path $resolvedRepoRoot $OutputPath

$artifactRoots = @(
  @{ Name = 'skills'; Path = 'ai-artifacts/skills' },
  @{ Name = 'instructions'; Path = 'ai-artifacts/instructions' },
  @{ Name = 'hooks'; Path = 'ai-artifacts/hooks' },
  @{ Name = 'mcp-config'; Path = 'ai-artifacts/mcp-config' },
  @{ Name = 'output-styles'; Path = 'ai-artifacts/output-styles' },
  @{ Name = 'agents'; Path = 'ai-artifacts/agents' },
  @{ Name = 'prompts'; Path = 'ai-artifacts/prompts' },
  @{ Name = 'plugins'; Path = 'ai-artifacts/plugins' },
  @{ Name = 'harness-docs'; Path = 'docs/harnesses' },
  @{ Name = 'scratch'; Path = '.scratch' },
  @{ Name = 'scripts'; Path = 'scripts' }
)

$artifactRows = foreach ($root in $artifactRoots) {
  $abs = Join-Path $resolvedRepoRoot $root.Path
  if (-not (Test-Path -LiteralPath $abs -PathType Container)) {
    continue
  }

  $count = @(Get-ChildItem -LiteralPath $abs -Recurse -File).Count
  [PSCustomObject]@{
    Name = $root.Name
    Path = $root.Path
    FileCount = $count
  }
}

$skillRows = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRepoRoot 'ai-artifacts/skills') -Recurse -File -Filter 'SKILL.md' |
  Sort-Object FullName |
  ForEach-Object {
    $fm = Get-Frontmatter -Path $_.FullName
    [PSCustomObject]@{
      Name = if ($fm.ContainsKey('name')) { $fm['name'] } else { $_.Directory.Name }
      Description = if ($fm.ContainsKey('description')) { $fm['description'] } else { '' }
      Version = if ($fm.ContainsKey('version')) { $fm['version'] } else { '' }
      Path = Get-RelativePathText -BasePath $resolvedRepoRoot -TargetPath $_.FullName
    }
  })

$metadataRows = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRepoRoot 'ai-artifacts/skills') -Recurse -File -Filter 'METADATA.md' |
  Sort-Object FullName |
  ForEach-Object {
    $fm = Get-Frontmatter -Path $_.FullName
    [PSCustomObject]@{
      Title = if ($fm.ContainsKey('title')) { $fm['title'] } else { '' }
      Type = if ($fm.ContainsKey('type')) { $fm['type'] } else { '' }
      Path = Get-RelativePathText -BasePath $resolvedRepoRoot -TargetPath $_.FullName
    }
  })

$frontmatterCandidates = @(
  Get-ChildItem -LiteralPath (Join-Path $resolvedRepoRoot 'ai-artifacts') -Recurse -File -Filter '*.md'
  Get-ChildItem -LiteralPath $resolvedRepoRoot -File -Filter '*.md'
  Get-ChildItem -LiteralPath (Join-Path $resolvedRepoRoot 'docs') -Recurse -File -Filter '*.md'
) | Sort-Object FullName -Unique

$frontmatterRows = foreach ($file in $frontmatterCandidates) {
  $fm = Get-Frontmatter -Path $file.FullName
  if ($fm.Count -eq 0) {
    continue
  }

  [PSCustomObject]@{
    Path = Get-RelativePathText -BasePath $resolvedRepoRoot -TargetPath $file.FullName
    NameOrTitle = if ($fm.ContainsKey('title')) { $fm['title'] } elseif ($fm.ContainsKey('name')) { $fm['name'] } else { '' }
    Type = if ($fm.ContainsKey('type')) { $fm['type'] } else { '' }
    Version = if ($fm.ContainsKey('version')) { $fm['version'] } else { '' }
    Tags = if ($fm.ContainsKey('tags')) { $fm['tags'] } else { '' }
  }
}

$workflowRows = @(Get-ChildItem -LiteralPath (Join-Path $resolvedRepoRoot '.github/workflows') -File -Filter '*.yml' |
  Sort-Object Name |
  ForEach-Object {
    $workflowName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $executorRel = ".github/workflows/scripts/$workflowName/execute-workflow-$workflowName.ps1"
    $executorAbs = Join-Path $resolvedRepoRoot $executorRel

    [PSCustomObject]@{
      Workflow = Get-RelativePathText -BasePath $resolvedRepoRoot -TargetPath $_.FullName
      LocalExecutor = if (Test-Path -LiteralPath $executorAbs -PathType Leaf) { $executorRel } else { '' }
    }
  })

$configPaths = @(
  '.markdownlint.json',
  '.yamllint',
  '.asciidoctor-lint.yml',
  '.github/workflows',
  '.github/workflows/scripts',
  '.githooks/pre-commit',
  'coding-policies/polyglot-policy.yaml',
  'coding-policies/usage-policy.yaml',
  'scripts/setup-repo.ps1',
  'scripts/simulate-workflows.ps1'
)

$generatedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('---')
$lines.Add('type: Reference')
$lines.Add('title: Repository Index')
$lines.Add('description: Generated register of repository artifacts, workflows, and frontmatter metadata.')
$lines.Add('tags: [index, generated, repository, ai-lab]')
$lines.Add("generated_at: $generatedAt")
$lines.Add('generator: scripts/generate-repo-index.ps1')
$lines.Add('---')
$lines.Add('')
$lines.Add('# Repository Index (Generated)')
$lines.Add('')
$lines.Add('This file is auto-generated. Do not edit manually; run `pwsh scripts/generate-repo-index.ps1`.')
$lines.Add('')
$lines.Add('## Scope Note')
$lines.Add('')
$lines.Add('The `ai-artifacts/skills/shared` source + generated mirror pattern (`.claude/commands`, `.agents/skills`, `.github/skills`) is specific to this repository because it is both source-of-truth and consumer.')
$lines.Add('External repositories can consume copied skills directly and do not need this mirror workflow.')
$lines.Add('')
$lines.Add('<!-- markdownlint-disable MD060 -->')
$lines.Add('')
$lines.Add('## Artifact Roots')
$lines.Add('')
$lines.Add('| Artifact | Path | File count |')
$lines.Add('| --- | --- | ---: |')
foreach ($row in $artifactRows) {
  $lines.Add("| $(Format-TableCell $row.Name) | $(Format-TableCell $row.Path) | $($row.FileCount) |")
}
$lines.Add('')
$lines.Add('## Skills (`SKILL.md`)')
$lines.Add('')
$lines.Add('| Skill | Version | Path | Description |')
$lines.Add('| --- | --- | --- | --- |')
foreach ($row in $skillRows) {
  $lines.Add("| $(Format-TableCell $row.Name) | $(Format-TableCell $row.Version) | $(Format-TableCell $row.Path) | $(Format-TableCell $row.Description) |")
}
$lines.Add('')
$lines.Add('## Skill Metadata (`METADATA.md`)')
$lines.Add('')
$lines.Add('| Title | Type | Path |')
$lines.Add('| --- | --- | --- |')
foreach ($row in $metadataRows) {
  $lines.Add("| $(Format-TableCell $row.Title) | $(Format-TableCell $row.Type) | $(Format-TableCell $row.Path) |")
}
$lines.Add('')
$lines.Add('## Frontmatter Catalog (Markdown)')
$lines.Add('')
$lines.Add('| Path | Name/Title | Type | Version | Tags |')
$lines.Add('| --- | --- | --- | --- | --- |')
foreach ($row in ($frontmatterRows | Sort-Object Path)) {
  $lines.Add("| $(Format-TableCell $row.Path) | $(Format-TableCell $row.NameOrTitle) | $(Format-TableCell $row.Type) | $(Format-TableCell $row.Version) | $(Format-TableCell $row.Tags) |")
}
$lines.Add('')
$lines.Add('## GitHub Workflows and Local Executors')
$lines.Add('')
$lines.Add('| Workflow | Local executor |')
$lines.Add('| --- | --- |')
foreach ($row in $workflowRows) {
  $executor = if ([string]::IsNullOrWhiteSpace($row.LocalExecutor)) { 'n/a' } else { $row.LocalExecutor }
  $lines.Add("| $(Format-TableCell $row.Workflow) | $(Format-TableCell $executor) |")
}
$lines.Add('')
$lines.Add('## Key Config and Entry Files')
$lines.Add('')
foreach ($path in $configPaths) {
  if (Test-Path -LiteralPath (Join-Path $resolvedRepoRoot $path)) {
    $lines.Add(('- `{0}`' -f $path))
  }
}
$lines.Add('')
$lines.Add('<!-- markdownlint-enable MD060 -->')

$content = ($lines -join "`n") + "`n"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outputFile, $content, $utf8NoBom)

Write-Output "Generated $OutputPath"
