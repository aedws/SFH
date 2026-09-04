$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Read-RequiredFile {
    param([string]$RelativePath)
    $path = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Deployment boundary dependency is missing: $RelativePath"
    }
    return Get-Content -Raw -LiteralPath $path -Encoding UTF8
}

$surfaceRaw = Read-RequiredFile "docs/assets/deployment-surfaces.json"
$surface = $surfaceRaw | ConvertFrom-Json
$wikiOrigin = [Uri]$surface.wiki.public_origin
$gameOrigin = [Uri]$surface.game.public_origin
$desiredGameOrigin = [Uri]$surface.game.desired_origin
$effectiveGameOrigin = [Uri]$surface.game.effective_origin
$runtimePrefix = ([string]$surface.storage.runtime_prefix).Trim('/')
$downloadPrefix = ([string]$surface.storage.download_prefix).Trim('/')

if ($surface.schema_version -ne 1) { throw "Unsupported deployment surface schema." }
if ($wikiOrigin.Scheme -ne "https" -or $gameOrigin.Scheme -ne "https") { throw "Public surfaces must use HTTPS." }
if ($wikiOrigin.Host -eq $gameOrigin.Host) { throw "Wiki and gameplay must use different public hosts." }
if ($desiredGameOrigin.Host -ne "sfh-game.play-preview.dev" -or $effectiveGameOrigin.AbsoluteUri -ne $gameOrigin.AbsoluteUri) {
    throw "Desired and effective gameplay origins are not separated correctly."
}
if ($surface.game.cutover_status -notin @("blocked_domain_unregistered", "ready") -or $surface.game.billing_touched -ne $false) {
    throw "Game domain cutover status or no-billing guard is invalid."
}
if ($surface.wiki.project -eq $surface.game.service -or $surface.game.service -eq $surface.storage.bucket -or $surface.wiki.project -eq $surface.storage.bucket) {
    throw "Pages, Worker, and R2 identifiers must be distinct."
}
if ($surface.storage.public_origin -ne $null -or $surface.storage.access -ne "worker-binding-only") {
    throw "R2 must remain private and Worker-bound."
}
if (-not $runtimePrefix -or -not $downloadPrefix -or $runtimePrefix -eq $downloadPrefix -or $runtimePrefix.StartsWith("$downloadPrefix/") -or $downloadPrefix.StartsWith("$runtimePrefix/")) {
    throw "Runtime and download R2 prefixes must be non-empty and disjoint."
}

$index = Read-RequiredFile "docs/index.md"
$playScript = Read-RequiredFile "docs/javascripts/play-entry.js"
$redirects = Read-RequiredFile "docs/_redirects"
$workflow = Read-RequiredFile ".github/workflows/deploy-wiki.yml"
$wrangler = Read-RequiredFile "cloudflare/wrangler.jsonc"
$worker = Read-RequiredFile "cloudflare/worker/src/index.mjs"
$uploader = Read-RequiredFile "scripts/deploy_cloudflare_assets.py"

$gameHref = 'href="' + $gameOrigin.AbsoluteUri + '"'
if ($index -notmatch [regex]::Escape($gameHref) -or $index -notmatch 'data-sfh-surface="gameplay"') {
    throw "Wiki home must link directly to the gameplay Worker and label the surface."
}
if ($playScript -notmatch [regex]::Escape($gameOrigin.GetLeftPart([UriPartial]::Authority)) -or $playScript -notmatch 'target = "_blank"' -or $playScript -notmatch 'noopener noreferrer') {
    throw "Global gameplay entry must use the external Worker origin safely."
}
if ($redirects -notmatch [regex]::Escape($gameOrigin.GetLeftPart([UriPartial]::Authority)) -or $surface.compatibility.status -ne "legacy-redirect-only") {
    throw "The wiki /play route must remain compatibility-only and target gameplay."
}
if ($workflow -notmatch 'Verify documentation-only Pages artifact' -or $workflow -notmatch 'test ! -e \.wiki-site/play/index\.wasm' -or $workflow -match 'Add browser game to wiki site') {
    throw "The deployed wiki artifact must not contain the game runtime."
}
foreach ($required in @($surface.wiki.project, $surface.game.service, $surface.storage.bucket, $runtimePrefix, $downloadPrefix)) {
    if ($workflow -notmatch [regex]::Escape([string]$required) -and $wrangler -notmatch [regex]::Escape([string]$required)) {
        throw "Deployment configuration does not expose required surface value: $required"
    }
}
if ($worker -notmatch 'x-sfh-surface' -or $worker -notmatch 'private_worker_binding' -or $uploader -notmatch 'runtime and download prefixes must be disjoint') {
    throw "Worker or uploader does not enforce the declared storage boundary."
}

$workflowFiles = Get-ChildItem -LiteralPath (Join-Path $repositoryRoot ".github/workflows") -Filter "*.yml" -File
foreach ($workflowFile in $workflowFiles) {
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $workflowFile.FullName -Encoding UTF8) {
        $lineNumber += 1
        if ($line -match '^\s*uses:\s*([^\s@]+)@([^\s#]+)') {
            $reference = $Matches[2]
            if ($reference -notmatch '^[0-9a-f]{40}$') {
                throw "Unpinned GitHub Action in $($workflowFile.Name):$lineNumber ($reference)"
            }
        }
    }
}
if ($workflow -notmatch 'CLOUDFLARE_API_TOKEN:\s*\$\{\{\s*secrets\.CLOUDFLARE_API_TOKEN\s*\}\}') {
    throw "Cloudflare credentials must be provided only through GitHub Secrets."
}
foreach ($artifactName in @("game-web", "wiki-site", "SFH-Windows-x64-")) {
    if ($workflow -notmatch "(?s)name:\s*$([regex]::Escape($artifactName)).{0,420}retention-days:\s*1") {
        throw "Temporary Actions artifact must use one-day retention: $artifactName"
    }
}
if (
    $workflow -notmatch 'prune-actions-artifacts:' -or
    $workflow -notmatch 'actions:\s*write' -or
    $workflow -notmatch 'workflow_run\.id' -or
    $workflow -notmatch 'ACTIONS_ARTIFACT_RETENTION_OK' -or
    $workflow -notmatch 'artifact_run_id" = "\$GITHUB_RUN_ID'
) {
    throw "Latest-only Actions artifact retention guard is missing."
}

Write-Host "DEPLOYMENT_BOUNDARIES_OK wiki=$($wikiOrigin.Host) game=$($gameOrigin.Host) desired=$($desiredGameOrigin.Host) cutover=$($surface.game.cutover_status) billing_untouched=true r2=private prefixes=2 actions=sha-pinned artifacts=latest-verified-only"
