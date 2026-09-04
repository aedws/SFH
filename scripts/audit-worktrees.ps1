[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

function Invoke-GitLines {
    param(
        [Parameter(Mandatory = $true)][string]$WorkDir,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = & git -C $WorkDir @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed in $WorkDir`n$($output -join [Environment]::NewLine)"
    }
    return @($output)
}

$null = Invoke-GitLines -WorkDir $RepositoryRoot -Arguments @('rev-parse', '--verify', 'origin/main')
$porcelain = Invoke-GitLines -WorkDir $RepositoryRoot -Arguments @('worktree', 'list', '--porcelain')
$worktrees = @()
$current = $null

foreach ($line in $porcelain) {
    if ($line -like 'worktree *') {
        if ($null -ne $current) { $worktrees += [pscustomobject]$current }
        $current = [ordered]@{ Path = $line.Substring(9); Head = ''; Branch = '(detached)' }
    }
    elseif ($null -ne $current -and $line -like 'HEAD *') {
        $current.Head = $line.Substring(5)
    }
    elseif ($null -ne $current -and $line -like 'branch refs/heads/*') {
        $current.Branch = $line.Substring(18)
    }
}
if ($null -ne $current) { $worktrees += [pscustomobject]$current }

$rootPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\')
$results = foreach ($worktree in $worktrees) {
    $resolved = (Resolve-Path -LiteralPath $worktree.Path).Path.TrimEnd('\')
    $status = @(Invoke-GitLines -WorkDir $resolved -Arguments @('status', '--porcelain'))
    $dirtyCount = @($status | Where-Object { $_ -ne '' }).Count

    & git -C $resolved merge-base --is-ancestor $worktree.Head origin/main 2>$null
    $ancestor = $LASTEXITCODE -eq 0
    $cherry = @(& git -C $resolved cherry origin/main $worktree.Head 2>$null)
    if ($LASTEXITCODE -ne 0) { throw "git cherry failed in $resolved" }
    $uniquePatchCount = @($cherry | Where-Object { $_ -like '+ *' }).Count
    $included = $ancestor -or $uniquePatchCount -eq 0

    $decision = if ($resolved -eq $rootPath) {
        'KEEP-PRIMARY'
    }
    elseif ($dirtyCount -gt 0) {
        'HOLD-DIRTY'
    }
    elseif (-not $included) {
        'HOLD-UNMERGED'
    }
    else {
        'REMOVE-CANDIDATE'
    }

    [pscustomobject]@{
        Decision = $decision
        Branch = $worktree.Branch
        Dirty = $dirtyCount
        UniquePatches = $uniquePatchCount
        Path = $resolved
    }
}

$results | Sort-Object Decision, Path | Format-Table -AutoSize

if (@($results | Where-Object { $_.Decision -like 'HOLD-*' }).Count -gt 0) {
    Write-Output 'HOLD 항목은 커밋·푸시 또는 main 포함 여부를 확인하기 전 삭제하지 마세요.'
}
