$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$roadmapPath = Join-Path $repositoryRoot "docs\assets\post-p7-roadmap.json"
$snapshotPath = Join-Path $repositoryRoot "docs\assets\notion-source-snapshot.json"
$errors = [System.Collections.Generic.List[string]]::new()

$roadmap = Get-Content -LiteralPath $roadmapPath -Raw -Encoding UTF8 | ConvertFrom-Json
$snapshot = Get-Content -LiteralPath $snapshotPath -Raw -Encoding UTF8 | ConvertFrom-Json
$sourceIds = @{}
foreach ($block in $snapshot.blocks) { $sourceIds[[string]$block.id] = $true }

if ($roadmap.source.root_version -ne $snapshot.root_version -or $roadmap.source.content_sha256 -ne $snapshot.content_sha256) {
    $errors.Add("P7 roadmap source revision does not match the committed Notion snapshot.")
}
if ($roadmap.source.notion_phase_max -ne 6 -or [string]::IsNullOrWhiteSpace($roadmap.source.numbering_note)) {
    $errors.Add("P7+ must be identified as an internal lane after official Notion Phase 1-6.")
}
if (($roadmap.module_layers -join ",") -ne "definition,policy,service,provider,presenter") {
    $errors.Add("P7+ modular layer contract is incomplete.")
}

$laneIds = [System.Collections.Generic.HashSet[string]]::new()
$packetIds = [System.Collections.Generic.HashSet[string]]::new()
$allowedDataGates = @("none", "sheet_if_catalog", "planner_decision", "server_provider")
foreach ($lane in $roadmap.lanes) {
    if ([string]$lane.id -notmatch '^P(?:7|8|9|10)$' -or -not $laneIds.Add([string]$lane.id)) {
        $errors.Add("Invalid or duplicate P7+ lane: $($lane.id)")
    }
    if (-not $lane.source_anchors -or -not $lane.packets) {
        $errors.Add("Lane $($lane.id) needs source anchors and packets.")
    }
    foreach ($anchor in $lane.source_anchors) {
        if (-not $sourceIds.ContainsKey([string]$anchor)) {
            $errors.Add("Lane $($lane.id) references unknown Notion block: $anchor")
        }
    }
    foreach ($packet in $lane.packets) {
        if ([string]$packet.id -notmatch ('^' + [regex]::Escape([string]$lane.id) + '-\d{2}$') -or -not $packetIds.Add([string]$packet.id)) {
            $errors.Add("Invalid or duplicate packet id: $($packet.id)")
        }
        if ($packet.state -notin @("planned", "in_progress")) {
            $errors.Add("P7+ must not claim unverified completion: $($packet.id)")
        }
        if ($packet.state -eq "in_progress") {
            if (-not $packet.completed_scope -or -not $packet.remaining_scope -or -not $packet.evidence) {
                $errors.Add("In-progress packet needs completed/remaining scope and evidence: $($packet.id)")
            }
            foreach ($evidence in $packet.evidence) {
                if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $evidence) -PathType Leaf)) {
                    $errors.Add("Missing packet evidence: $evidence")
                }
            }
        }
        if ([string]$packet.data_gate -notin $allowedDataGates) {
            $errors.Add("Unknown data gate on $($packet.id): $($packet.data_gate)")
        }
        if (-not $packet.modules -or [string]::IsNullOrWhiteSpace($packet.player_outcome) -or [string]::IsNullOrWhiteSpace($packet.e2e)) {
            $errors.Add("Packet $($packet.id) needs modules, player outcome, and E2E causality.")
        }
    }
}

$raw = Get-Content -LiteralPath $roadmapPath -Raw -Encoding UTF8
if ($raw -match '(?i)payment[_ -]?activation|paid[_ -]?plan[_ -]?activation|billing[_ -]?activation') {
    $errors.Add("P7+ setup must not activate payment or paid infrastructure plans.")
}
if ($errors.Count -gt 0) { throw ($errors -join [Environment]::NewLine) }

Write-Host "P7_ROADMAP_OK lanes=$($laneIds.Count) packets=$($packetIds.Count) notion_v=$($snapshot.root_version)"
