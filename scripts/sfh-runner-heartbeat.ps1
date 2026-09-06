# Executed as the Windows owner on login and periodically while logged in.
# Only the existing local gh credential can update the short-lived readiness lease.
param([switch]$Once)
$ErrorActionPreference = 'Stop'
$repository = 'aedws/SFH'
do {
    try {
        & wsl.exe -d Ubuntu-24.04 -u root -- /usr/bin/systemctl start docker
        if ($LASTEXITCODE -ne 0) { throw 'WSL Docker unavailable' }
        & wsl.exe -d Ubuntu-24.04 -u root -- /bin/bash -lc 'systemctl start actions.runner.aedws-SFH.sfh-wsl-build.service'
        if ($LASTEXITCODE -ne 0) { throw 'Runner service unavailable' }
        $runners = & gh api "repos/$repository/actions/runners" | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'Runner status unavailable' }
        $ready = @($runners.runners | Where-Object { $_.name -eq 'sfh-wsl-build' -and $_.status -eq 'online' }).Count -eq 1
        if ($ready) {
            $until = [DateTimeOffset]::UtcNow.AddMinutes(3).ToUnixTimeSeconds().ToString()
            & gh variable set SFH_SELF_HOSTED_READY_UNTIL --repo $repository --body $until
            if ($LASTEXITCODE -ne 0) { throw 'Lease update failed' }
        }
    }
    catch {
        Write-Warning $_.Exception.Message
        # No renewal: newly planned workflows use hosted after lease expiry.
        # Already assigned jobs require cancellation and rerun if the PC fails.
    }
    if (-not $Once) { Start-Sleep -Seconds 60 }
} while (-not $Once)
