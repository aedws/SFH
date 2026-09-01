param(
    [ValidateSet("sync", "check")]
    [string]$Command = "check"
)

$arguments = @((Join-Path $PSScriptRoot "sync_loot_table.py"))
if ($Command -eq "check") {
    $arguments += "--check"
}
python @arguments
exit $LASTEXITCODE
