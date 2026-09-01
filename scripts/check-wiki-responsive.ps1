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

$roleRoutes = @(
    'href="development-status/"',
    'href="architecture/module-rules/"',
    'href="quality/wiki-responsive-e2e/"',
    'href="#sfh-knowledge-map"'
)
foreach ($route in $roleRoutes) {
    if ($index -notmatch [regex]::Escape($route)) {
        $errors.Add("Home role navigation route is missing: $route")
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
if ($playScript -notmatch 'GAMEPLAY_ORIGIN = "https://sfh-game\.vstock-market\.workers\.dev"') {
    $errors.Add("Browser play does not use the distinct gameplay Worker origin.")
}
if ($mkdocs -notmatch 'quality/wiki-responsive-e2e\.md') {
    $errors.Add("MkDocs navigation does not expose the responsive wiki E2E document.")
}
if ($index -notmatch 'search:\s*\r?\n\s+exclude:\s*true') {
    $errors.Add("The dashboard home must be excluded from the wiki search index.")
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "WIKI_RESPONSIVE_OK viewports=4 role_routes=$($roleRoutes.Count) search=100dvh touch=44px"
