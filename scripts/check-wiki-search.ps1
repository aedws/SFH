$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $repositoryRoot "docs\assets\search-priorities.json"
$scriptPath = Join-Path $repositoryRoot "docs\javascripts\search-dashboard.js"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"

$config = Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($config.version -lt 1) {
    throw "Search priority schema version must be at least 1."
}
if ($config.rankings.Count -lt 10) {
    throw "At least 10 ranked search entries are required."
}

$queries = @($config.rankings | ForEach-Object { [string]$_.query })
$duplicates = @($queries | Group-Object | Where-Object Count -gt 1)
if ($duplicates.Count -gt 0) {
    throw "Ranked search queries must be unique."
}
foreach ($ranking in $config.rankings) {
    if (
        [string]::IsNullOrWhiteSpace([string]$ranking.query) -or
        [string]::IsNullOrWhiteSpace([string]$ranking.label) -or
        [int]$ranking.priority -le 0
    ) {
        throw "Every ranked search entry requires query, label, and positive priority."
    }
}
if ($config.planner_groups.Count -lt 4) {
    throw "At least four planner search groups are required."
}
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "The search dashboard script is missing."
}
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw
if ($mkdocs -notmatch 'javascripts/search-dashboard\.js') {
    throw "mkdocs.yml does not load the search dashboard script."
}

Write-Host "WIKI_SEARCH_OK rankings=$($config.rankings.Count) planner_groups=$($config.planner_groups.Count)"
