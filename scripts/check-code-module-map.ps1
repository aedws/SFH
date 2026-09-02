$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$python = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command "py" -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 is required to verify the code module map."
}

if ($python.Name -eq "py.exe" -or $python.Name -eq "py") {
    & $python.Source -3 (Join-Path $PSScriptRoot "generate_code_module_map.py") --check
}
else {
    & $python.Source (Join-Path $PSScriptRoot "generate_code_module_map.py") --check
}
if ($LASTEXITCODE -ne 0) {
    throw "The generated code module map is stale."
}

$mapPath = Join-Path $repositoryRoot "docs/assets/code-module-map.json"
$pagePath = Join-Path $repositoryRoot "docs/architecture/code-module-map.md"
$scriptPath = Join-Path $repositoryRoot "docs/javascripts/code-module-map.js"
$stylePath = Join-Path $repositoryRoot "docs/stylesheets/extra.css"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"
$map = Get-Content -LiteralPath $mapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$page = Get-Content -LiteralPath $pagePath -Raw -Encoding UTF8
$javascript = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
$stylesheet = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8
$errors = [System.Collections.Generic.List[string]]::new()

if ($map.summary.modules -lt 10 -or $map.summary.named_classes -lt 20 -or $map.summary.relationships -lt 10) {
    $errors.Add("Code map coverage is unexpectedly small.")
}
if ($map.modules.id.Count -ne ($map.modules.id | Sort-Object -Unique).Count) {
    $errors.Add("Code map module IDs must be unique.")
}
foreach ($edge in $map.edges) {
    if ($edge.from -notin $map.modules.id -or $edge.to -notin $map.modules.id) {
        $errors.Add("Relationship references a missing module: $($edge.from) -> $($edge.to)")
    }
}
if ($page -notmatch 'data-sfh-code-module-map-host') {
    $errors.Add("The architecture page does not expose the code map host.")
}
if ($javascript -notmatch 'assets/code-module-map\.json' -or $javascript -notmatch 'aria-pressed') {
    $errors.Add("The code map JavaScript does not load data or expose selection state.")
}
if ($stylesheet -notmatch '\.sfh-code-map__workspace' -or $stylesheet -notmatch 'max-width:\s*24em') {
    $errors.Add("The code map responsive CSS contract is missing.")
}
if ($mkdocs -notmatch 'architecture/code-module-map\.md' -or $mkdocs -notmatch 'javascripts/code-module-map\.js') {
    $errors.Add("MkDocs does not expose the code map page and runtime.")
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "CODE_MODULE_MAP_WIKI_OK modules=$($map.summary.modules) classes=$($map.summary.named_classes) relationships=$($map.summary.relationships)"
