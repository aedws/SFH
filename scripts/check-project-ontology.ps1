$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$python = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command "py" -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 is required to verify the project ontology."
}

if ($python.Name -eq "py.exe" -or $python.Name -eq "py") {
    & $python.Source -3 (Join-Path $PSScriptRoot "generate_project_ontology.py") --check
}
else {
    & $python.Source (Join-Path $PSScriptRoot "generate_project_ontology.py") --check
}
if ($LASTEXITCODE -ne 0) {
    throw "The generated project ontology is stale."
}

$ontologyPath = Join-Path $repositoryRoot "docs/assets/project-ontology.json"
$registryPath = Join-Path $repositoryRoot "docs/assets/owner-decision-registry.json"
$pagePath = Join-Path $repositoryRoot "docs/architecture/project-ontology.md"
$developerPath = Join-Path $repositoryRoot "docs/access/developer.md"
$javascriptPath = Join-Path $repositoryRoot "docs/javascripts/owner-decision-console.js"
$stylesheetPath = Join-Path $repositoryRoot "docs/stylesheets/extra.css"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"

$ontology = Get-Content -LiteralPath $ontologyPath -Raw -Encoding UTF8 | ConvertFrom-Json
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$page = Get-Content -LiteralPath $pagePath -Raw -Encoding UTF8
$developer = Get-Content -LiteralPath $developerPath -Raw -Encoding UTF8
$javascript = Get-Content -LiteralPath $javascriptPath -Raw -Encoding UTF8
$stylesheet = Get-Content -LiteralPath $stylesheetPath -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8
$errors = [System.Collections.Generic.List[string]]::new()

if ($ontology.schema_version -ne 2 -or $ontology.summary.tracked -lt 7) {
    $errors.Add("Project ontology schema or initial decision coverage is missing.")
}
if ($ontology.authority.id -ne "authority:project-owner" -or $ontology.authority.label -ne "프로젝트 오너") {
    $errors.Add("Project owner must be the final decision authority.")
}
foreach ($contributor in $ontology.contributors) {
    if ($contributor.can_finalize) {
        $errors.Add("Planner and developer contributors must not finalize owner decisions: $($contributor.id)")
    }
}

$ids = @($ontology.objects | ForEach-Object { $_.id })
if ($ids.Count -ne @($ids | Sort-Object -Unique).Count) {
    $errors.Add("Project ontology object IDs must be unique.")
}
foreach ($item in $registry.objects) {
    if ($item.type -in @("principle", "decision", "risk", "work_item") -and $item.decision_owner -ne "authority:project-owner") {
        $errors.Add("Governed object does not belong to the project owner: $($item.id)")
    }
    if ([string]::IsNullOrWhiteSpace($item.summary) -or [string]::IsNullOrWhiteSpace($item.next_action)) {
        $errors.Add("Tracked object must explain current meaning and next action: $($item.id)")
    }
}
foreach ($requiredType in @("principle", "decision", "risk", "work_item", "module", "document", "source", "authority", "contributor")) {
    if ($requiredType -notin @($ontology.object_types | ForEach-Object { $_.id })) {
        $errors.Add("Operational ontology object type is missing: $requiredType")
    }
}
foreach ($requiredInterface in @("owner_decidable", "traceable", "verifiable")) {
    if ($requiredInterface -notin @($ontology.interfaces | ForEach-Object { $_.id })) {
        $errors.Add("Operational ontology interface is missing: $requiredInterface")
    }
}
if ($ontology.summary.sources -lt 6 -or $ontology.summary.actions -lt 5 -or $ontology.lifecycle.Count -ne 5) {
    $errors.Add("Operational source, action, or lifecycle coverage is incomplete.")
}
foreach ($action in $ontology.action_types) {
    if ([string]::IsNullOrWhiteSpace($action.actor) -or [string]::IsNullOrWhiteSpace($action.input) -or [string]::IsNullOrWhiteSpace($action.output) -or [string]::IsNullOrWhiteSpace($action.guard)) {
        $errors.Add("Action contract must declare actor, input, output, and guard: $($action.id)")
    }
}
foreach ($relation in $ontology.relations) {
    if ($relation.from -notin $ids -or $relation.to -notin $ids) {
        $errors.Add("Broken project ontology relation: $($relation.from) -> $($relation.to)")
    }
}
if ($ontology.summary.modules -lt 50 -or $ontology.summary.documents -lt 80 -or $ontology.summary.relations -lt 20) {
    $errors.Add("Generated implementation or evidence coverage is unexpectedly small.")
}
if ($developer -notmatch 'data-sfh-owner-decision-console-host') {
    $errors.Add("Developer workspace does not expose the owner decision console.")
}
$ownerPosition = $developer.IndexOf('data-sfh-owner-decision-console-host')
$codePosition = $developer.IndexOf('data-sfh-code-module-map-host')
if ($ownerPosition -lt 0 -or $codePosition -lt 0 -or $ownerPosition -gt $codePosition) {
    $errors.Add("Owner decision console must appear before the code module map.")
}
foreach ($required in @(
    'assets/project-ontology.json',
    'SFH OPERATIONAL ONTOLOGY // READ ONLY',
    'aria-pressed',
    '프로젝트 오너',
    'credentials: "same-origin"',
    '판단 대기열',
    '객체 탐색',
    '관계·계보',
    '행동·관측'
)) {
    if ($javascript -notmatch [regex]::Escape($required)) {
        $errors.Add("Owner decision console client contract is missing: $required")
    }
}
if ($stylesheet -notmatch '\.sfh-owner-console__workspace' -or $stylesheet -notmatch '\.sfh-owner-lineage' -or $stylesheet -notmatch '\.sfh-owner-action-grid') {
    $errors.Add("Owner decision console responsive CSS contract is missing.")
}
if ($page -notmatch '최종 판단 주체는 기획자나 AI 개발자가 아니라 프로젝트 오너' -or $page -notmatch '읽기 전용' -or $page -notmatch '판단 폐루프') {
    $errors.Add("Project ontology authority or read-only boundary is undocumented.")
}
if ($mkdocs -notmatch 'javascripts/owner-decision-console\.js' -or $mkdocs -notmatch 'architecture/project-ontology\.md') {
    $errors.Add("MkDocs does not expose the project ontology runtime and document.")
}

$node = Get-Command "node" -ErrorAction SilentlyContinue
if ($node) {
    & $node.Source --check $javascriptPath
    if ($LASTEXITCODE -ne 0) {
        $errors.Add("Owner decision console JavaScript syntax check failed.")
    }
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "PROJECT_ONTOLOGY_WIKI_OK tracked=$($ontology.summary.tracked) objects=$($ontology.objects.Count) relations=$($ontology.summary.relations)"
