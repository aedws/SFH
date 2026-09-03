$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $repositoryRoot "docs\index.md"
$scriptPath = Join-Path $repositoryRoot "docs\javascripts\play-entry.js"
$stylePath = Join-Path $repositoryRoot "docs\stylesheets\extra.css"
$headerStylePath = Join-Path $repositoryRoot "docs\stylesheets\header-actions.css"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"

foreach ($requiredPath in @($indexPath, $scriptPath, $stylePath, $headerStylePath, $mkdocsPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Wiki play entry dependency is missing: $requiredPath"
    }
}

$index = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
$script = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
$style = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$headerStyle = Get-Content -LiteralPath $headerStylePath -Raw -Encoding UTF8
$searchScript = Get-Content -LiteralPath (Join-Path $repositoryRoot "docs/javascripts/search-dashboard.js") -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8

if ($index -notmatch 'class="[^"]*sfh-operation-play[^"]*" data-sfh-surface="gameplay" href="https://sfh-game\.vstock-market\.workers\.dev/"') {
    throw "The home build card does not expose the distinct gameplay Worker entry."
}
if ($script -notmatch 'data-sfh-global-play' -or $script -notmatch 'document\$\.subscribe') {
    throw "The global browser play entry does not support Material instant navigation."
}
if ($script -notmatch 'GAMEPLAY_ORIGIN = "https://sfh-game\.vstock-market\.workers\.dev"' -or $script -notmatch 'target = "_blank"' -or $script -notmatch 'noopener noreferrer') {
    throw "The global browser play entry must open the distinct gameplay Worker safely."
}
if ($script -notmatch 'deployment-surfaces\.json' -or $script -notmatch 'cutover_status === "ready"' -or $script -notmatch 'desired_origin') {
    throw "The play entry does not implement the DNS-gated play-preview.dev cutover contract."
}
if ($headerStyle -notmatch 'a\.sfh-global-play' -or $style -notmatch '\.sfh-operation-play') {
    throw "The browser play entry styles are missing."
}
if ($script -notmatch '<svg class="sfh-play-icon"' -or $script -match '<i[^>]*>▶' -or $style -match '\.sfh-global-play i::before') {
    throw "Play must use one centered SVG without a font glyph or blinking pseudo-element."
}
if ($script -notmatch '게임 플레이 \(새 탭\)' -or $script -notmatch 'sfh-play-label' -or $searchScript -notmatch '문서 검색 열기' -or $searchScript -notmatch 'sfh-search-label') {
    throw "Play and search must have distinct visible and accessible labels."
}
if ($mkdocs -notmatch 'stylesheets/header-actions\.css' -or $headerStyle -notmatch 'min-height: 44px' -or $headerStyle -notmatch ':focus-visible') {
    throw "Header actions require the shared responsive, touch and focus styles."
}
if ($mkdocs -notmatch 'javascripts/play-entry\.js') {
    throw "mkdocs.yml does not load the global browser play entry."
}

Write-Host "WIKI_PLAY_ENTRY_OK home_card=1 global_header=1 effective_origin=1 desired_origin_dns_gated=1 labeled_actions=2 svg_icon=1 REAL_BROWSER_REQUIRED"
