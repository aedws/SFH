# Offline regression tests: no real WSL, scheduled task or GitHub writes.
$ErrorActionPreference = 'Stop'
$global:SFHTestcalls = [System.Collections.Generic.List[string]]::new()
$global:SFHTestbusy = $false
$global:SFHTestapiFailure = $false
$global:SFHTestautomatic = $false
function gh {
    $global:LASTEXITCODE = 0
    $global:SFHTestcalls.Add('gh ' + ($args -join ' '))
    if ($args[0] -eq 'api') {
        if ($global:SFHTestapiFailure) { $global:LASTEXITCODE = 1; return }
        return (@{ runners = @(@{ name = 'sfh-wsl-build'; status = 'online'; busy = $global:SFHTestbusy }) } | ConvertTo-Json -Depth 4 -Compress)
    }
}
function wsl.exe { $global:LASTEXITCODE = 0; $global:SFHTestcalls.Add('wsl ' + ($args -join ' ')) }
function Get-ScheduledTask {
    param($TaskName)
    [pscustomobject]@{ TaskName = $TaskName; State = 'Ready'; Triggers = $(if ($global:SFHTestautomatic) { 'timer' } else { $null }) }
}
function Start-ScheduledTask { param($TaskName); $global:SFHTestcalls.Add("start $TaskName") }
function Stop-ScheduledTask { param($TaskName); $global:SFHTestcalls.Add("stop $TaskName") }
function Assert-True($Condition, $Message) { if (-not $Condition) { throw $Message } }
$control = Join-Path $PSScriptRoot 'sfh-runner.ps1'
foreach ($file in @('sfh-runner.ps1', 'sfh-runner-heartbeat.ps1', 'install-sfh-runner-heartbeat.ps1')) {
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file), [ref]$null, [ref]$parseErrors)
    Assert-True ($parseErrors.Count -eq 0) "Syntax error: $file"
}
& $control status | Out-Null
Assert-True (($global:SFHTestcalls -join '|') -eq 'wsl --list --running') 'Status must not wake WSL or contact GitHub.'
$global:SFHTestcalls.Clear()
& $control start
Assert-True ($global:SFHTestcalls.Contains('start SFH Linux Runner Host')) 'Manual start must keep WSL alive.'
Assert-True ($global:SFHTestcalls[-1] -match 'SFH_SELF_HOSTED_ENABLED.*true') 'Enable routing only after readiness.'
$global:SFHTestcalls.Clear()
& $control stop
Assert-True ($global:SFHTestcalls[0] -match 'SFH_SELF_HOSTED_ENABLED.*false') 'Stop must disable new routing first.'
Assert-True ($global:SFHTestcalls[-1] -eq 'wsl --terminate Ubuntu-24.04') 'Stop only the dedicated distribution.'
foreach ($failure in @('busy', 'api')) {
    $global:SFHTestcalls.Clear()
    $global:SFHTestbusy = $failure -eq 'busy'
    $global:SFHTestapiFailure = $failure -eq 'api'
    $caught = $false
    try { & $control stop } catch { $caught = $true }
    Assert-True $caught "Must refuse unsafe stop: $failure"
    Assert-True (-not ($global:SFHTestcalls -match '^wsl|^stop ')) "Unsafe termination: $failure"
}
$global:SFHTestapiFailure = $false
$global:SFHTestbusy = $false
$global:SFHTestautomatic = $true
$global:SFHTestcalls.Clear()
$caught = $false
try { & $control start } catch { $caught = $true }
Assert-True ($caught -and $global:SFHTestcalls.Count -eq 0) 'Legacy automatic tasks must be rejected before startup.'
$installer = Get-Content (Join-Path $PSScriptRoot 'install-sfh-runner-heartbeat.ps1') -Raw
Assert-True ($installer -notmatch 'New-ScheduledTaskTrigger|Start-ScheduledTask|\s-Trigger\s') 'Installer must never schedule or start WSL.'
Write-Output 'SFH_RUNNER_CONTROLS_PASS: syntax, read-only status, manual start/stop, busy/API guards, legacy guard, no auto-start.'
