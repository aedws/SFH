param(
    [switch]$RequireReady
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$surfacePath = Join-Path $repositoryRoot "docs/assets/deployment-surfaces.json"
$surface = Get-Content -LiteralPath $surfacePath -Raw -Encoding UTF8 | ConvertFrom-Json
$desired = [uri]$surface.game.desired_origin
$effective = [uri]$surface.game.effective_origin

if ($desired.Scheme -ne "https" -or $desired.Host -ne "sfh-game.play-preview.dev") {
    throw "Desired game origin contract is invalid: $desired"
}
if ($effective.Scheme -ne "https" -or [string]::IsNullOrWhiteSpace($effective.Host)) {
    throw "Effective fallback origin contract is invalid: $effective"
}

$addresses = @()
try {
    $addresses = [System.Net.Dns]::GetHostAddresses($desired.Host)
}
catch [System.Net.Sockets.SocketException] {
    $addresses = @()
}

if ($addresses.Count -eq 0) {
    if ($surface.game.cutover_status -ne "blocked_domain_unregistered") {
        throw "DNS is unavailable but the registry does not declare a blocked cutover."
    }
    if ($RequireReady) {
        throw "CUTOVER_NOT_READY host=$($desired.Host) reason=domain_unregistered_or_dns_missing"
    }
    Write-Output "GAME_DOMAIN_CUTOVER_BLOCKED desired=$($desired.AbsoluteUri) effective=$($effective.AbsoluteUri) billing_untouched=true"
    exit 0
}

if ($surface.game.cutover_status -ne "ready") {
    throw "DNS is ready but deployment-surfaces.json is not explicitly approved for cutover."
}
Write-Output "GAME_DOMAIN_CUTOVER_READY desired=$($desired.AbsoluteUri) addresses=$($addresses.Count)"
