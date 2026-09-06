# Manual lifecycle for the dedicated SFH WSL runner. Never changes billing.
param([ValidateSet('start', 'stop', 'status')][string]$Action = 'status')
$ErrorActionPreference = 'Stop'
$repository = 'aedws/SFH'
$distribution = 'Ubuntu-24.04'
$taskNames = @('SFH Linux Runner Heartbeat', 'SFH Linux Runner Host')

function Set-RunnerVariable([string]$Name, [string]$Value) {
    & gh variable set $Name --repo $repository --body $Value
    if ($LASTEXITCODE -ne 0) { throw "Cannot update GitHub variable: $Name" }
}

function Get-RemoteRunner {
    $raw = & gh api "repos/$repository/actions/runners"
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify runner activity. No WSL shutdown performed.' }
    return @((($raw -join "`n") | ConvertFrom-Json).runners | Where-Object name -eq 'sfh-wsl-build')
}

if ($Action -eq 'status') {
    # Listing distributions does not boot them. Never run a Linux command here.
    & wsl.exe --list --running
    Get-ScheduledTask -TaskName $taskNames | Select-Object TaskName, State
    exit 0
}

if ($Action -eq 'stop') {
    # Block newly planned jobs first; refuse to kill a running build.
    Set-RunnerVariable 'SFH_SELF_HOSTED_ENABLED' 'false'
    if (@(Get-RemoteRunner | Where-Object busy -eq $true).Count) {
        throw 'A build is running. New local jobs are disabled; retry stop after it finishes.'
    }
    Stop-ScheduledTask -TaskName $taskNames[0]
    Set-RunnerVariable 'SFH_SELF_HOSTED_READY_UNTIL' '0'
    Stop-ScheduledTask -TaskName $taskNames[1]
    & wsl.exe --terminate $distribution
    if ($LASTEXITCODE -ne 0) { throw 'WSL termination failed.' }
    Write-Output 'SFH_RUNNER_STOPPED. Linux files preserved. Other distributions untouched.'
    exit 0
}

foreach ($name in $taskNames) {
    $task = Get-ScheduledTask -TaskName $name
    if (@($task.Triggers | Where-Object { $null -ne $_ }).Count -gt 0) { throw 'Automatic triggers found. Reinstall manual controls first.' }
}
Set-RunnerVariable 'SFH_SELF_HOSTED_ENABLED' 'false'
Set-RunnerVariable 'SFH_SELF_HOSTED_READY_UNTIL' '0'
try {
    Start-ScheduledTask -TaskName $taskNames[1]
    # Initial readiness handshake; periodic renewal starts only after success.
    $heartbeat = Join-Path $PSScriptRoot 'heartbeat.ps1'
    if (-not (Test-Path -LiteralPath $heartbeat)) { $heartbeat = Join-Path $PSScriptRoot 'sfh-runner-heartbeat.ps1' }
    & $heartbeat -Once
    $online = @(Get-RemoteRunner | Where-Object status -eq 'online')
    if ($online.Count -ne 1) { throw 'Runner is not online yet. Retry start shortly, or use stop.' }
    Start-ScheduledTask -TaskName $taskNames[0]
    Set-RunnerVariable 'SFH_SELF_HOSTED_ENABLED' 'true'
    Write-Output 'SFH_RUNNER_STARTED. Use stop when finished. No boot/login auto-start.'
} catch {
    # Leave routing disabled; retain the host for a retry rather than killing work.
    Write-Warning 'Startup did not complete. Local host may be running; retry start or use stop.'
    throw
}
