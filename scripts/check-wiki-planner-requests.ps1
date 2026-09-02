param(
    [string]$SiteRoot = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $repositoryRoot "docs\assets\planner-requests.json"
$plannerPath = Join-Path $repositoryRoot "docs\access\planner.md"
$scriptPath = Join-Path $repositoryRoot "docs\javascripts\planner-requests.js"
$stylePath = Join-Path $repositoryRoot "docs\stylesheets\extra.css"
$workflowPath = Join-Path $repositoryRoot "docs\design\planner-request-workflow.md"
$snapshotPath = Join-Path $repositoryRoot "docs\assets\notion-source-snapshot.json"
$proposalScriptPath = Join-Path $repositoryRoot "docs\javascripts\planner-proposal.js"

$data = Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8 | ConvertFrom-Json
$plannerContent = Get-Content -LiteralPath $plannerPath -Raw -Encoding UTF8
$javascript = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8
$stylesheet = Get-Content -LiteralPath $stylePath -Raw -Encoding UTF8
$workflow = Get-Content -LiteralPath $workflowPath -Raw -Encoding UTF8
$snapshot = Get-Content -LiteralPath $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
$proposalScript = Get-Content -LiteralPath $proposalScriptPath -Raw -Encoding UTF8

if ($data.notion_url -notmatch '^https://[^/]+\.notion\.site/') {
    throw "Planner request Notion URL is invalid."
}
if ($data.version -lt 3 -or $data.source.sync_mode -ne "ci_verified_public_snapshot" -or [string]::IsNullOrWhiteSpace($data.source.content_sha256)) {
    throw "Planner request source freshness contract is missing."
}
if ($snapshot.content_sha256 -ne $data.source.content_sha256 -or $snapshot.root_version -ne $data.source.root_version) {
    throw "Planner request source does not match the committed Notion snapshot."
}
$sourceBlockIds = @{}
foreach ($block in $snapshot.blocks) { $sourceBlockIds[$block.id] = $true }
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
    if ($item.state -notin @("needs_planner", "ready_for_dev", "in_implementation", "provisional_implemented", "implemented_verified", "accepted")) {
        throw "Unsupported planner request state: $($item.state)"
    }
    if ($null -eq $item.blocking -or $item.acceptance.Count -lt 1 -or $item.evidence.Count -lt 1) {
        throw "$($item.id) requires blocking, acceptance, and evidence fields."
    }
	foreach ($field in @("decision_id", "source_anchor", "source_revision")) {
		if ([string]::IsNullOrWhiteSpace($item.$field)) { throw "$($item.id) has an empty $field field." }
	}
	if (-not $sourceBlockIds.ContainsKey($item.source_anchor) -or $item.source_revision -ne $snapshot.root_version) {
		throw "$($item.id) source anchor or revision is not in the verified Notion snapshot."
	}
	if ($null -eq $item.supersedes -or $null -eq $item.conflicts_with) {
		throw "$($item.id) requires supersedes and conflicts_with arrays."
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
    $plannerContent -notmatch 'data-sfh-planner-requests' -or
    $plannerContent -notmatch 'data-sfh-planner-request-grid' -or
    $plannerContent -notmatch 'data-sfh-planner-filters' -or
    $plannerContent -notmatch 'data-sfh-planner-source'
) {
    throw "Protected planner workspace request hub is missing."
}
if (
    $javascript -notmatch 'planner-requests\.json' -or
    $javascript -notmatch 'document\.currentScript' -or
    $javascript -notmatch 'new URL\("\.\./assets/planner-requests\.json", plannerRequestScriptUrl\)' -or
    $javascript -notmatch 'sfh-planner-request__notion' -or
    $javascript -notmatch 'ownerRole' -or
	$javascript -notmatch 'installFilters' -or
	$javascript -notmatch 'source_anchor' -or
	$javascript -notmatch 'decision_id'
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
if ($plannerContent -notmatch 'data-sfh-proposal-composer' -or $proposalScript -notmatch 'navigator\.clipboard' -or $proposalScript -notmatch 'data-sfh-proposal-output') {
	throw "Safe local proposal composer contract is missing."
}
if (-not [string]::IsNullOrWhiteSpace($SiteRoot)) {
    $resolvedSite = Join-Path $repositoryRoot $SiteRoot
    $sitePlanner = Get-Content -LiteralPath (Join-Path $resolvedSite "access\planner\index.html") -Raw -Encoding UTF8
    $siteDataPath = Join-Path $resolvedSite "assets\planner-requests.json"
    $siteScriptPath = Join-Path $resolvedSite "javascripts\planner-requests.js"
    if (
        $sitePlanner -notmatch 'data-sfh-planner-requests' -or
        -not (Test-Path -LiteralPath $siteDataPath) -or
        -not (Test-Path -LiteralPath $siteScriptPath)
    ) {
        throw "Generated protected planner request hub or data is missing."
    }
}

Write-Output "WIKI_PLANNER_REQUESTS_OK items=$($data.items.Count) schema_v3 owners states blocking acceptance evidence notion_snapshot_hash source_anchor decision_lineage role_filters safe_local_proposal responsive touch_44px sheet_extension_authorized"
