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

& $virtualPython -c "import mkdocs" 2>$null
if ($LASTEXITCODE -ne 0) {
    & $virtualPython -m pip install --disable-pip-version-check -r (Join-Path $repositoryRoot "requirements-docs.txt")
}

Push-Location $repositoryRoot
try {
    & (Join-Path $PSScriptRoot "compress-wiki-release-days.ps1") -Check
    & (Join-Path $PSScriptRoot "check-wiki-search.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-play-entry.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-knowledge-map.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-color-contrast.ps1")
    & (Join-Path $PSScriptRoot "check-wiki-responsive.ps1")
    & $virtualPython -m mkdocs $Action --strict
}
finally {
    Pop-Location
}
