# Run as the Windows owner after registering the dedicated WSL runner.
# Does not create credentials or change billing settings.
$ErrorActionPreference = 'Stop'
# Reconfiguration must not silently interrupt an active CI session.
if (@(Get-ScheduledTask -TaskName 'SFH Linux Runner*' -ErrorAction SilentlyContinue | Where-Object State -eq 'Running').Count) {
    throw 'Stop the SFH runner before reinstalling its manual controls.'
}
$runnerHome = Join-Path $env:USERPROFILE 'SFHRunner'
New-Item -ItemType Directory -Force -Path $runnerHome | Out-Null
$heartbeatPath = Join-Path $runnerHome 'heartbeat.ps1'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sfh-runner-heartbeat.ps1') -Destination $heartbeatPath
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sfh-runner.ps1') -Destination (Join-Path $runnerHome 'sfh-runner.ps1')
$arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& ''{0}''"' -f $heartbeatPath.Replace("'", "''")
$action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $arguments -WorkingDirectory $runnerHome
$settings = New-ScheduledTaskSettingsSet -Hidden -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
# WSL systemd services alone do not keep the distribution alive. Hold a foreground
# Linux process in a hidden scheduled task so idle shutdown cannot kill a CI job.
$hostAction = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument '-NoProfile -NonInteractive -WindowStyle Hidden -Command "& wsl.exe -d Ubuntu-24.04 -u sfh-runner --exec /bin/sleep infinity"'
$hostSettings = New-ScheduledTaskSettingsSet -Hidden -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
# No triggers: neither login, boot nor a timer may start WSL.
Register-ScheduledTask -TaskName 'SFH Linux Runner Host' -Action $hostAction -Settings $hostSettings -Principal $principal -Description 'SFH WSL host: manual start only, no automatic triggers' -Force | Out-Null
Register-ScheduledTask -TaskName 'SFH Linux Runner Heartbeat' -Action $action -Settings $settings -Principal $principal -Description 'SFH manual session lease; stops on sign-out/reboot' -Force | Out-Null
$shortcutShell = New-Object -ComObject WScript.Shell
foreach ($command in @('start', 'stop', 'status')) {
    $shortcut = $shortcutShell.CreateShortcut((Join-Path $runnerHome "SFH Runner $command.lnk"))
    $shortcut.TargetPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    $shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -NoExit -File "{0}" {1}' -f (Join-Path $runnerHome 'sfh-runner.ps1'), $command
    $shortcut.WorkingDirectory = $runnerHome
    $shortcut.Save()
}
Write-Output "SFH_RUNNER_MANUAL_CONTROLS_INSTALLED $runnerHome (not started)"
