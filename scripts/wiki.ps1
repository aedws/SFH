param(
    [ValidateSet("serve", "build")]
    [string]$Action = "serve"
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$virtualEnvironment = Join-Path $repositoryRoot ".venv"
$virtualPython = Join-Path $virtualEnvironment "Scripts\python.exe"

if (-not (Test-Path -LiteralPath $virtualPython)) {
    $pythonCommand = Get-Command "python" -ErrorAction SilentlyContinue
    $pythonLauncher = Get-Command "py" -ErrorAction SilentlyContinue

    if ($pythonCommand) {
        & $pythonCommand.Source -m venv $virtualEnvironment
    }
    elseif ($pythonLauncher) {
        & $pythonLauncher.Source -3 -m venv $virtualEnvironment
    }
    else {
        throw "Python 3를 찾지 못했습니다. Python을 설치한 뒤 이 명령을 다시 실행하세요."
    }
}

$previousNativePreference = $PSNativeCommandUseErrorActionPreference
$previousErrorPreference = $ErrorActionPreference
$PSNativeCommandUseErrorActionPreference = $false
$ErrorActionPreference = "SilentlyContinue"
& $virtualPython -c "import mkdocs" 2>$null
$mkdocsImportExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorPreference
$PSNativeCommandUseErrorActionPreference = $previousNativePreference
if ($mkdocsImportExitCode -ne 0) {
    & $virtualPython -m pip install --disable-pip-version-check -r (Join-Path $repositoryRoot "requirements-docs.txt")
}

Push-Location $repositoryRoot
try {
    & (Join-Path $PSScriptRoot "compress-wiki-release-days.ps1") -Check
    & (Join-Path $PSScriptRoot "check-wiki-search.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-play-entry.ps1")
	& (Join-Path $PSScriptRoot "check-game-domain-cutover.ps1")
    & (Join-Path $PSScriptRoot "check-deployment-boundaries.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-knowledge-map.ps1")
    & (Join-Path $PSScriptRoot "check-code-module-map.ps1")
    & (Join-Path $PSScriptRoot "check-project-ontology.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-color-contrast.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-responsive.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-no-github-backlinks.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-planner-requests.ps1")
	& (Join-Path $PSScriptRoot "check-wiki-role-auth.ps1")
	& (Join-Path $PSScriptRoot "check-p7-roadmap.ps1")
	& $virtualPython (Join-Path $PSScriptRoot "snapshot_notion_source.py") --check
	if ($LASTEXITCODE -ne 0) { throw "Notion GDD snapshot failed." }
	& $virtualPython (Join-Path $PSScriptRoot "snapshot_notion_tracker.py")
	if ($LASTEXITCODE -ne 0) { throw "Notion tracker snapshot failed." }
	& $virtualPython (Join-Path $PSScriptRoot "check_notion_audit.py")
	if ($LASTEXITCODE -ne 0) { throw "Notion/code crosswalk failed." }
	& $virtualPython (Join-Path $PSScriptRoot "test_notion_snapshot.py")
	if ($LASTEXITCODE -ne 0) { throw "Notion checkbox regression failed." }
    & $virtualPython -m mkdocs $Action --strict
    if ($Action -eq "build") {
        Copy-Item -LiteralPath (Join-Path $repositoryRoot "cloudflare/wiki-auth/_worker.js") -Destination (Join-Path $repositoryRoot ".wiki-site/_worker.js") -Force
        & (Join-Path $PSScriptRoot "check-wiki-no-github-backlinks.ps1") -SiteRoot ".wiki-site"
        & (Join-Path $PSScriptRoot "check-wiki-planner-requests.ps1") -SiteRoot ".wiki-site"
        & (Join-Path $PSScriptRoot "check-wiki-role-auth.ps1") -SiteRoot ".wiki-site"
        & $virtualPython (Join-Path $PSScriptRoot "test_wiki_articles.py") ".wiki-site"
        if ($LASTEXITCODE -ne 0) { throw "Article hierarchy verification failed." }
    }
}
finally {
    Pop-Location
}
