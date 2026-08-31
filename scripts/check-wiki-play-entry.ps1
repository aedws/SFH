$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $repositoryRoot "docs\index.md"
$scriptPath = Join-Path $repositoryRoot "docs\javascripts\play-entry.js"
$stylePath = Join-Path $repositoryRoot "docs\stylesheets\extra.css"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"

foreach ($requiredPath in @($indexPath, $scriptPath, $stylePath, $mkdocsPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Wiki play entry dependency is missing: $requiredPath"
    }
}

$index = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
$script = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
$style = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8

if ($index -notmatch 'class="sfh-operation-play" href="play/"') {
    throw "The home build card does not expose the browser play entry."
}
if ($script -notmatch 'data-sfh-global-play' -or $script -notmatch 'document\$\.subscribe') {
    throw "The global browser play entry does not support Material instant navigation."
}
if ($script -notmatch 'document\.currentScript' -or $script -notmatch 'new URL\("\.\./play/", playEntryScriptUrl\)') {
    throw "The global browser play entry must resolve from the stable script-derived site root."
}
if ($style -notmatch 'a\.sfh-global-play' -or $style -notmatch '\.sfh-operation-play') {
    throw "The browser play entry styles are missing."
}
if ($mkdocs -notmatch 'javascripts/play-entry\.js') {
    throw "mkdocs.yml does not load the global browser play entry."
}

Write-Host "WIKI_PLAY_ENTRY_OK home_card=1 global_header=1"
