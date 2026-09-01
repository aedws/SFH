param(
    [ValidateSet("sync", "check")]
    [string]$Command = "check"
)

$arguments = @((Join-Path $PSScriptRoot "sync_item_lifecycle.py"))
if ($Command -eq "check") {
    $arguments += "--check"
}
python @arguments
exit $LASTEXITCODE
