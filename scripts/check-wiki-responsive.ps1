$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$stylePath = Join-Path $repositoryRoot "docs/stylesheets/extra.css"
$indexPath = Join-Path $repositoryRoot "docs/index.md"
$e2ePath = Join-Path $repositoryRoot "docs/quality/wiki-responsive-e2e.md"
$searchScriptPath = Join-Path $repositoryRoot "docs/javascripts/search-dashboard.js"
$playScriptPath = Join-Path $repositoryRoot "docs/javascripts/play-entry.js"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"

foreach ($path in @($stylePath, $indexPath, $e2ePath, $searchScriptPath, $playScriptPath, $mkdocsPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Responsive wiki dependency is missing: $path"
    }
}

$style = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$index = Get-Content -LiteralPath $indexPath -Raw -Encoding UTF8
$e2e = Get-Content -LiteralPath $e2ePath -Raw -Encoding UTF8
$searchScript = Get-Content -LiteralPath $searchScriptPath -Raw -Encoding UTF8
$playScript = Get-Content -LiteralPath $playScriptPath -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8
$errors = [System.Collections.Generic.List[string]]::new()

$requiredStylePatterns = [ordered]@{
    "dynamic viewport search" = 'height:\s*100dvh'
    "safe area support" = 'env\(safe-area-inset-'
    "coarse pointer targets" = '@media\s*\(pointer:\s*coarse\)'
	"44px coarse pointer target" = '@media\s*\(pointer:\s*coarse\)[\s\S]*min-height:\s*2\.75rem'
	"non-blocking decoration" = 'pointer-events:\s*none'
	"closed search click passthrough" = '\.md-search__output\s*\{[\s\S]*pointer-events:\s*none'
	"active search click restore" = '\.md-search__inner:focus-within\s+\.md-search__output[\s\S]*pointer-events:\s*auto'
    "desktop ontology lifecycle rail" = '\.sfh-owner-console__lifecycle\s*\{[\s\S]*grid-template-columns:\s*repeat\(5'
    "mobile ontology lifecycle scroll" = '@media screen and \(max-width:\s*48em\)[\s\S]*\.sfh-owner-console__lifecycle\s*\{[\s\S]*width:\s*max-content'
    "reduced motion" = '@media\s*\(prefers-reduced-motion:\s*reduce\)'
    "high contrast focus" = '@media\s*\(prefers-contrast:\s*more\)'
    "mobile breakpoint" = '@media screen and \(max-width:\s*48em\)'
    "small phone breakpoint" = '@media screen and \(max-width:\s*24em\)'
    "table local scrolling" = '\.md-typeset__table[\s\S]*overflow-x:\s*auto'
    "code local scrolling" = '\.md-typeset pre[\s\S]*overflow-x:\s*auto'
    "role navigation" = '\.sfh-role-nav'
    "mobile search output" = '\.md-search__output[\s\S]*bottom:\s*0'
}
foreach ($entry in $requiredStylePatterns.GetEnumerator()) {
    if ($style -notmatch $entry.Value) {
        $errors.Add("Responsive CSS contract missing: $($entry.Key)")
    }
}

$publicRoutes = @(
    'data-sfh-surface="gameplay"',
    'data-sfh-surface="windows-download"',
    'href="access/login/?return=%2Ffeatures%2F"'
)
foreach ($route in $publicRoutes) {
    if ($index -notmatch [regex]::Escape($route)) {
        $errors.Add("Public home route is missing: $route")
    }
}

foreach ($viewportName in @('320x568', '390x844', '768x1024', '1440x900')) {
    if ($e2e -notmatch [regex]::Escape($viewportName)) {
        $errors.Add("Required browser E2E viewport is undocumented: $viewportName")
    }
}
if ($e2e -notmatch 'REAL_BROWSER_REQUIRED') {
    $errors.Add("The E2E contract must require real browser validation.")
}
if ($searchScript -notmatch 'new URL\("\.\./assets/search-priorities\.json", searchDashboardScriptUrl\)') {
    $errors.Add("Search data does not use the stable script-derived site root.")
}
if ($searchScript -notmatch 'input\.dispatchEvent\(new KeyboardEvent\("keyup"') {
    $errors.Add("Search recommendations do not dispatch the Material search keyup event.")
}
if ($searchScript -notmatch 'window\.location\.pathname === "/"' -or $searchScript -notmatch 'startsWith\("/access/login"\)') {
    $errors.Add("Public surfaces must not request protected search data.")
}
if ($playScript -notmatch 'GAMEPLAY_ORIGIN = "https://sfh-game\.vstock-market\.workers\.dev"') {
    $errors.Add("Browser play does not use the distinct gameplay Worker origin.")
}
if ($mkdocs -notmatch 'quality/wiki-responsive-e2e\.md') {
    $errors.Add("MkDocs navigation does not expose the responsive wiki E2E document.")
}
if ($index -notmatch 'search:\s*\r?\n\s+exclude:\s*true') {
    $errors.Add("The dashboard home must be excluded from the wiki search index.")
}
foreach ($forbiddenPublicContent in @('data-sfh-planner-requests', 'data-sfh-proposal-composer', 'sfh-knowledge-map', 'sfh-progress-panel')) {
    if ($index -match [regex]::Escape($forbiddenPublicContent)) {
        $errors.Add("Public home leaks internal collaboration content: $forbiddenPublicContent")
    }
}
foreach ($publicFeature in @('NO AIM FATIGUE', 'ROOM LOCKDOWN', 'RISK · REWARD', 'LOOT IDENTITY', 'TACTICAL VISION', 'PC · MOBILE')) {
    if ($index -notmatch [regex]::Escape($publicFeature)) {
        $errors.Add("Public home player feature is missing: $publicFeature")
    }
}
foreach ($internalLeak in @('owner-decision-registry', 'P9-01', '코드 모듈', '서버 위변조')) {
    if ($index -match [regex]::Escape($internalLeak)) {
        $errors.Add("Public home exposes internal delivery information: $internalLeak")
    }
}
if ($index -match '<details class="sfh-day"\s+open>') {
    $errors.Add("Wiki home must keep the daily release detail collapsed by default.")
}
if ($style -notmatch '\.sfh-public-test-guide' -or $style -notmatch '\.sfh-public-showcase' -or $style -notmatch '\.sfh-plain-loop') {
    $errors.Add("Public and planner responsive layouts are missing.")
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "WIKI_RESPONSIVE_OK viewports=4 public_routes=$($publicRoutes.Count) search=100dvh touch=44px home=playtest_only"
