$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Require-Pattern {
    param(
        [string]$Content,
        [string]$Pattern,
        [string]$Message
    )
    if ($Content -notmatch $Pattern) {
        throw $Message
    }
}

$preMain = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot ".github\workflows\backup-main.yml")
$restore = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot ".github\workflows\restore-main.yml")
$deploy = Get-Content -Raw -LiteralPath (Join-Path $repositoryRoot ".github\workflows\deploy-wiki.yml")

Require-Pattern $preMain 'github\.event\.before' "Previous-main snapshot must use the pre-push commit."
Require-Pattern $preMain 'backup/pre-main/\$PREVIOUS_MAIN_SHA' "Previous-main snapshot must use a commit-addressed branch."
Require-Pattern $preMain 'contents:\s*write' "Previous-main snapshot requires scoped contents write permission."
Require-Pattern $deploy 'backup-verified-main:' "Verified deployment must create a post-E2E backup."
Require-Pattern $deploy 'needs:\s*\r?\n\s*- cloudflare-deploy' "Verified backup must wait for Cloudflare E2E."
Require-Pattern $deploy "needs\.cloudflare-deploy\.outputs\.deployed == 'true'" "Verified backup must not run when Cloudflare deployment credentials are absent."
Require-Pattern $deploy 'backup/verified-main/\$GITHUB_SHA' "Verified backup must use the exact main commit."
Require-Pattern $restore 'backup/\(pre-main\|verified-main\)/\[0-9a-f\]\{40\}' "Recovery input must restrict backup namespaces and full SHA."
Require-Pattern $restore 'git restore --source="\$expected_sha" --staged --worktree -- \.' "Recovery must create a tree-restoring commit instead of resetting main."
Require-Pattern $restore 'gh pr create' "Recovery must return through a pull request."

Write-Host "BACKUP_WORKFLOWS_OK pre_main=1 verified_main=1 recovery_pr=1"
