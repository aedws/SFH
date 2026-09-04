$ErrorActionPreference = "Stop"

$python = Get-Command "python" -ErrorAction SilentlyContinue
if (-not $python) {
    $python = Get-Command "py" -ErrorAction SilentlyContinue
}
if (-not $python) {
    throw "Python 3 is required to audit system modularity."
}

if ($python.Name -eq "py.exe" -or $python.Name -eq "py") {
    & $python.Source -3 (Join-Path $PSScriptRoot "check_system_modularity.py")
}
else {
    & $python.Source (Join-Path $PSScriptRoot "check_system_modularity.py")
}
if ($LASTEXITCODE -ne 0) {
    throw "System modularity audit failed."
}
