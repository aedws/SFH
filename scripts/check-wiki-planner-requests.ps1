param(
    [string]$SiteRoot = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $repositoryRoot "docs\assets\planner-requests.json"
$homePath = Join-Path $repositoryRoot "docs\index.md"
$scriptPath = Join-Path $repositoryRoot "docs\javascripts\planner-requests.js"
$stylePath = Join-Path $repositoryRoot "docs\stylesheets\extra.css"
$workflowPath = Join-Path $repositoryRoot "docs\design\planner-request-workflow.md"

$data = Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$wikiHomeContent = Get-Content -LiteralPath $homePath -Raw -Encoding UTF8
$javascript = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
$stylesheet = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$workflow = Get-Content -LiteralPath $workflowPath -Raw -Encoding UTF8

if ($data.notion_url -notmatch '^https://[^/]+\.notion\.site/') {
    throw "Planner request Notion URL is invalid."
}
if ($data.version -lt 2 -or $data.source.sync_mode -ne "manual_verified_snapshot" -or [string]::IsNullOrWhiteSpace($data.source.last_checked_at)) {
    throw "Planner request source freshness contract is missing."
}
if ($data.items.Count -lt 3) {
    throw "Planner request hub requires request, data, and complete states."
}
$ids = @{}
$statuses = @{}
foreach ($item in $data.items) {
    if ([string]::IsNullOrWhiteSpace($item.id) -or $ids.ContainsKey($item.id)) {
        throw "Planner request ID is empty or duplicated: $($item.id)"
    }
    $ids[$item.id] = $true
    if ($item.status -notin @("request", "data", "complete")) {
        throw "Unsupported planner request status: $($item.status)"
    }
    if ($item.owner_role -notin @("planner", "ai_developer")) {
        throw "Unsupported planner request owner: $($item.owner_role)"
    }
    if ($item.state -notin @("needs_planner", "ready_for_dev", "in_implementation", "implemented_verified", "accepted")) {
        throw "Unsupported planner request state: $($item.state)"
    }
    if ($null -eq $item.blocking -or $item.acceptance.Count -lt 1 -or $item.evidence.Count -lt 1) {
        throw "$($item.id) requires blocking, acceptance, and evidence fields."
    }
    $statuses[$item.status] = $true
    foreach ($field in @("tag", "title", "summary", "basis", "notion_prompt")) {
        if ([string]::IsNullOrWhiteSpace($item.$field)) {
            throw "$($item.id) has an empty $field field."
        }
    }
}
foreach ($requiredStatus in @("request", "data", "complete")) {
    if (-not $statuses.ContainsKey($requiredStatus)) {
        throw "Planner request status is missing: $requiredStatus"
    }
}
if (
    $wikiHomeContent -notmatch 'data-sfh-planner-requests' -or
    $wikiHomeContent -notmatch 'data-sfh-planner-request-grid' -or
    $wikiHomeContent -notmatch 'data-sfh-planner-filters' -or
    $wikiHomeContent -notmatch 'data-sfh-planner-source'
) {
    throw "Wiki home planner request hub is missing."
}
if (
    $javascript -notmatch 'planner-requests\.json' -or
    $javascript -notmatch 'sfh-planner-request__notion' -or
    $javascript -notmatch 'ownerRole' -or
    $javascript -notmatch 'installFilters'
) {
    throw "Planner request renderer is not linked to data and Notion action."
}
if (
    $stylesheet -notmatch '\.sfh-planner-requests__grid' -or
    $stylesheet -notmatch '\.sfh-planner-filters' -or
    $stylesheet -notmatch '\.sfh-planner-source' -or
    $stylesheet -notmatch 'grid-template-columns:\s*1fr' -or
    $stylesheet -notmatch 'min-height:\s*44px'
) {
    throw "Planner request hub responsive or touch-target styles are missing."
}
if ($workflow -notmatch 'sfh-standing-sheet-extension: authorized-without-separate-approval') {
    throw "Standing Google Sheet extension authorization is not documented."
}
if (-not [string]::IsNullOrWhiteSpace($SiteRoot)) {
    $resolvedSite = Join-Path $repositoryRoot $SiteRoot
    $siteHome = Get-Content -LiteralPath (Join-Path $resolvedSite "index.html") -Raw -Encoding UTF8
    $siteDataPath = Join-Path $resolvedSite "assets\planner-requests.json"
    $siteScriptPath = Join-Path $resolvedSite "javascripts\planner-requests.js"
    if (
        $siteHome -notmatch 'data-sfh-planner-requests' -or
        -not (Test-Path -LiteralPath $siteDataPath) -or
        -not (Test-Path -LiteralPath $siteScriptPath)
    ) {
        throw "Generated wiki planner request hub or data is missing."
    }
}

Write-Output "WIKI_PLANNER_REQUESTS_OK items=$($data.items.Count) schema_v2 owners states blocking acceptance evidence source_freshness role_filters notion_link responsive touch_44px sheet_extension_authorized"
