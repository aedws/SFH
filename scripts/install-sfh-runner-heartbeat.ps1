# Run as the Windows owner after registering the dedicated WSL runner.
# Does not create credentials or change billing settings.
$ErrorActionPreference = 'Stop'
$runnerHome = Join-Path $env:USERPROFILE 'SFHRunner'
New-Item -ItemType Directory -Force -Path $runnerHome | Out-Null
$heartbeatPath = Join-Path $runnerHome 'heartbeat.ps1'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sfh-runner-heartbeat.ps1') -Destination $heartbeatPath
$arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& ''{0}'' -Once"' -f $heartbeatPath.Replace("'", "''")
$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $arguments -WorkingDirectory $runnerHome
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(10) -RepetitionInterval (New-TimeSpan -Minutes 1)
$settings = New-ScheduledTaskSettingsSet -Hidden -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
# WSL systemd services alone do not keep the distribution alive. Hold a foreground
# Linux process in a hidden scheduled task so idle shutdown cannot kill a CI job.
$hostAction = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-NoProfile -NonInteractive -WindowStyle Hidden -Command "& wsl.exe -d Ubuntu-24.04 -u sfh-runner --exec /bin/sleep infinity"'
$hostSettings = New-ScheduledTaskSettingsSet -Hidden -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName 'SFH Linux Runner Host' -Action $hostAction -Trigger $trigger -Settings $hostSettings -Principal $principal -Description 'Keep dedicated WSL host alive while Windows owner is logged in' -Force | Out-Null
Start-ScheduledTask -TaskName 'SFH Linux Runner Host'
Register-ScheduledTask -TaskName 'SFH Linux Runner Heartbeat' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description 'SFH dedicated WSL runner readiness lease; no billing changes' -Force | Out-Null
Start-ScheduledTask -TaskName 'SFH Linux Runner Heartbeat'
Write-Output 'SFH_RUNNER_HEARTBEAT_INSTALLED interval=1min lease=3min interactive_owner=true'
