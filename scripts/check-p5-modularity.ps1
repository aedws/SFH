$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$python = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command "py" -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python executable not found." }
& $python.Source (Join-Path $PSScriptRoot "check_p5_modularity.py")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
