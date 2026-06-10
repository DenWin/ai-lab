# PRD — Harden the GitHub repo and GitHub Actions (if applicable)

Status: needs-triage

Quick capture — iron out in scratch-planning, don't action yet.

## Problem Statement

Harden this repo's GitHub posture: repo/branch settings, access, secrets, and — **if applicable** —
GitHub Actions workflows. Goal: a safe default security baseline before more work (and any automated
push/PR flow) lands.

## Areas to cover (for triage, not to action now)

**Repo / branch protection**
- Branch protection on `main`: required PR review, required status checks, no force-push, no direct
  push. Ties into [[gated-work-prd-issue-approval]] (branch-per-issue + PR-before-merge).
- Signed commits / linear history? CODEOWNERS? Restrict who can merge.

**Secrets & supply chain**
- Secret scanning + push protection enabled; Dependabot alerts/updates; pin actions to commit SHAs
  (not floating tags); least-privilege `GITHUB_TOKEN` (`permissions:` block per workflow).

**GitHub Actions — "if applicable" gate**
- First check whether this repo even has/needs Actions. The repo is currently local-first
  (pre-commit via PSScriptAnalyzer, local-markdown tracker, `.scratch` workflow) and may not have a
  remote/CI yet — confirm before designing workflows.
- If Actions are warranted: harden workflow triggers (avoid `pull_request_target` foot-guns), pin
  third-party actions, scope permissions, gate on the pre-commit checks already defined locally.

## Open questions

- Does a GitHub remote exist for this repo yet, and is CI in scope at all right now, or is this
  forward-looking hardening to apply when the remote/PR flow is set up?
- Which controls are free/available for this repo's plan & visibility (private vs public)?

_Solution: Fill in._
