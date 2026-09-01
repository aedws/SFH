param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$targetFiles = @(
    (Join-Path $repositoryRoot "docs\index.md"),
    (Join-Path $repositoryRoot "docs\development-status.md")
)

function Get-DayBlocks {
    param([string[]]$Lines)

    $blocks = [System.Collections.Generic.List[object]]::new()
    $index = 0
    while ($index -lt $Lines.Count) {
        if ($Lines[$index] -notmatch '^<details class="sfh-day"') {
            $index += 1
            continue
        }

        $start = $index
        $depth = 0
        do {
            $depth += ([regex]::Matches($Lines[$index], '<details\b')).Count
            $depth -= ([regex]::Matches($Lines[$index], '</details>')).Count
            $index += 1
        } while ($index -lt $Lines.Count -and $depth -gt 0)

        if ($depth -ne 0) {
            throw "Unclosed sfh-day block at line index $start."
        }

        $end = $index - 1
        $blockLines = @($Lines[$start..$end])
        $header = [regex]::Match(
            ($blockLines -join "`n"),
            '<span class="sfh-day-title"><b>(?<date>[^<]+)</b>.*?<small>(?<topic>.*?)</small>',
            [System.Text.RegularExpressions.RegexOptions]::Singleline
        )
        if (-not $header.Success) {
            throw "Could not read the sfh-day date or topic at line index $start."
        }

        $blocks.Add([pscustomobject]@{
            Start = $start
            End = $end
            Date = $header.Groups['date'].Value
            Topic = $header.Groups['topic'].Value
            Lines = $blockLines
            IsOpen = $blockLines[0] -match '\sopen[ >]'
            IsLatest = ($blockLines -join "`n") -match 'sfh-latest'
        })
    }
    return $blocks
}

function Get-LabelCount {
    param(
        [object[]]$Blocks,
        [string]$BadgeClass
    )
    $content = ($Blocks | ForEach-Object { $_.Lines -join "`n" }) -join "`n"
    return ([regex]::Matches($content, "sfh-badge $([regex]::Escape($BadgeClass))")).Count
}

function Convert-DayGroup {
    param([object[]]$Blocks)

    $date = $Blocks[0].Date
    $buildCount = Get-LabelCount -Blocks $Blocks -BadgeClass "is-build"
    $improveCount = Get-LabelCount -Blocks $Blocks -BadgeClass "is-improve"
    $changeCount = Get-LabelCount -Blocks $Blocks -BadgeClass "is-change"
    $fixCount = Get-LabelCount -Blocks $Blocks -BadgeClass "is-fix"
    $latestBadge = if (@($Blocks | Where-Object { $_.IsLatest }).Count -gt 0) {
        '<i class="sfh-latest">&#xCD5C;&#xC2E0;</i>'
    } else {
        ''
    }
    $openAttribute = if (@($Blocks | Where-Object { $_.IsOpen }).Count -gt 0) { ' open' } else { '' }
    $summaryParts = @("$($Blocks.Count) UPDATE BUNDLES")
    if ($buildCount -gt 0) { $summaryParts += "BUILD $buildCount" }
    if ($improveCount -gt 0) { $summaryParts += "IMPROVE $improveCount" }
    if ($changeCount -gt 0) { $summaryParts += "CHANGE $changeCount" }
    if ($fixCount -gt 0) { $summaryParts += "FIX $fixCount" }

    $result = [System.Collections.Generic.List[string]]::new()
    $result.Add("<details class=`"sfh-day`"$openAttribute>")
    $result.Add("  <summary><span class=`"sfh-day-title`"><b>$date</b>$latestBadge<small>$($summaryParts -join ' &middot; ')</small></span><em class=`"sfh-chevron`">&#x2303;</em></summary>")
    $result.Add('  <div class="sfh-day-body">')
    $result.Add('    <div class="sfh-daily-overview">')
    $result.Add("      <span><b>$($Blocks.Count)</b><small>UPDATE BUNDLES</small></span>")
    $result.Add("      <span><b>$buildCount</b><small>BUILD</small></span>")
    $result.Add("      <span><b>$improveCount</b><small>IMPROVE</small></span>")
    $result.Add("      <span><b>$changeCount</b><small>CHANGE</small></span>")
    $result.Add("      <span><b>$fixCount</b><small>FIX</small></span>")
    $result.Add('    </div>')

    for ($bundleIndex = 0; $bundleIndex -lt $Blocks.Count; $bundleIndex += 1) {
        $block = $Blocks[$bundleIndex]
        $bodyStart = -1
        for ($lineIndex = 0; $lineIndex -lt $block.Lines.Count; $lineIndex += 1) {
            if ($block.Lines[$lineIndex] -match '^\s*<div class="sfh-day-body">\s*$') {
                $bodyStart = $lineIndex
                break
            }
        }
        if ($bodyStart -lt 0 -or $block.Lines[$block.Lines.Count - 2] -notmatch '^\s*</div>\s*$') {
            throw "Could not read the sfh-day body: $($block.Date) / $($block.Topic)"
        }

        $result.Add('    <details class="sfh-bundle">')
        $result.Add("      <summary><span><small>UPDATE $($bundleIndex + 1)</small><b>$($block.Topic)</b></span><em class=`"sfh-chevron`">&#x2304;</em></summary>")
        $result.Add('      <div class="sfh-bundle-body">')
        if ($bodyStart + 1 -le $block.Lines.Count - 3) {
            foreach ($bodyLine in $block.Lines[($bodyStart + 1)..($block.Lines.Count - 3)]) {
                if ([string]::IsNullOrWhiteSpace($bodyLine)) {
                    $result.Add('')
                    continue
                }
                $relativeLine = if ($bodyLine.StartsWith('    ')) { $bodyLine.Substring(4) } else { $bodyLine }
                $result.Add("        $relativeLine")
            }
        }
        $result.Add('      </div>')
        $result.Add('    </details>')
    }

    $result.Add('  </div>')
    $result.Add('</details>')
    return $result
}

foreach ($path in $targetFiles) {
    $lines = [System.IO.File]::ReadAllLines($path)
    $blocks = @(Get-DayBlocks -Lines $lines)
    $duplicates = @($blocks | Group-Object Date | Where-Object Count -gt 1)
	$isHomePage = [System.IO.Path]::GetFileName($path) -eq "index.md"

    if ($Check) {
		if ($isHomePage -and $blocks.Count -ne 1) {
			throw "The wiki home must contain exactly the latest one-day release block: found $($blocks.Count)."
		}
        if ($duplicates.Count -gt 0) {
            $duplicateSummary = ($duplicates | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
            throw "More than one sfh-day card exists for a date ($path): $duplicateSummary. Run compress-wiki-release-days.ps1."
        }
        foreach ($block in $blocks) {
            $blockContent = $block.Lines -join "`n"
            $bundleMatches = [regex]::Matches($blockContent, '<details class="sfh-bundle"(?<open> open)?>')
            if ($bundleMatches.Count -eq 0) {
                continue
            }
            $declaredCount = [regex]::Match($blockContent, '<small>(?<count>\d+) UPDATE BUNDLES')
            if (-not $declaredCount.Success -or [int]$declaredCount.Groups['count'].Value -ne $bundleMatches.Count) {
                throw "The daily bundle total is stale ($path / $($block.Date))."
            }
            $numberMatches = [regex]::Matches($blockContent, '<small>UPDATE (?<number>\d+)</small>')
            for ($numberIndex = 0; $numberIndex -lt $numberMatches.Count; $numberIndex += 1) {
                if ([int]$numberMatches[$numberIndex].Groups['number'].Value -ne $numberIndex + 1) {
                    throw "Daily bundle numbering is not sequential ($path / $($block.Date))."
                }
            }
            $openBundles = @($bundleMatches | Where-Object { $_.Groups['open'].Success })
            if ($openBundles.Count -gt 1 -or ($openBundles.Count -eq 1 -and -not $bundleMatches[$bundleMatches.Count - 1].Groups['open'].Success)) {
                throw "Only the latest daily bundle may be expanded by default ($path / $($block.Date))."
            }
            $badgeSummary = @(
                @{ Label = 'BUILD'; Class = 'is-build'; GroupIndex = 0 },
                @{ Label = 'IMPROVE'; Class = 'is-improve'; GroupIndex = 1 },
                @{ Label = 'CHANGE'; Class = 'is-change'; GroupIndex = 2 },
                @{ Label = 'FIX'; Class = 'is-fix'; GroupIndex = 3 }
            )
            $headingMatches = [regex]::Matches($blockContent, '<div class="sfh-group"><h3>[^<]*?(?<count>\d+)</h3>')
            foreach ($badge in $badgeSummary) {
                if ($openBundles.Count -gt 0 -and $headingMatches.Count -gt 0) {
                    $actualBadgeCount = 0
                    for ($headingIndex = [int]$badge.GroupIndex; $headingIndex -lt $headingMatches.Count; $headingIndex += 4) {
                        $actualBadgeCount += [int]$headingMatches[$headingIndex].Groups['count'].Value
                    }
                } else {
                    $actualBadgeCount = ([regex]::Matches($blockContent, "sfh-badge $($badge.Class)")).Count
                }
                $declaredBadgeCount = [regex]::Match($blockContent, "$($badge.Label) (?<count>\d+)")
                if ((-not $declaredBadgeCount.Success) -or ([int]$declaredBadgeCount.Groups['count'].Value -ne $actualBadgeCount)) {
                    throw "The $($badge.Label) daily total is stale ($path / $($block.Date)): declared=$($declaredBadgeCount.Groups['count'].Value) actual=$actualBadgeCount headings=$($headingMatches.Count)."
                }
            }
        }
        Write-Host "DAILY_RELEASE_NOTES_OK $([System.IO.Path]::GetFileName($path))"
        continue
    }

	if ($isHomePage -and $blocks.Count -gt 1) {
		$result = [System.Collections.Generic.List[string]]::new()
		if ($blocks[0].Start -gt 0) {
			foreach ($line in $lines[0..($blocks[0].Start - 1)]) { $result.Add($line) }
		}
		foreach ($line in $blocks[0].Lines) { $result.Add($line) }
		$afterLastBlock = $blocks[$blocks.Count - 1].End + 1
		if ($afterLastBlock -lt $lines.Count) {
			foreach ($line in $lines[$afterLastBlock..($lines.Count - 1)]) { $result.Add($line) }
		}
		$output = ($result -join [Environment]::NewLine) + [Environment]::NewLine
		[System.IO.File]::WriteAllText($path, $output, [System.Text.UTF8Encoding]::new($false))
		Write-Host "HOME_RELEASE_NOTES_TRIMMED latest_date=$($blocks[0].Date) removed_days=$($blocks.Count - 1)"
		continue
	}

    if ($duplicates.Count -eq 0) {
        Write-Host "DAILY_RELEASE_NOTES_ALREADY_COMPRESSED $([System.IO.Path]::GetFileName($path))"
        continue
    }

    $result = [System.Collections.Generic.List[string]]::new()
    $cursor = 0
    $blockIndex = 0
    while ($blockIndex -lt $blocks.Count) {
        $group = [System.Collections.Generic.List[object]]::new()
        $group.Add($blocks[$blockIndex])
        $nextIndex = $blockIndex + 1
        while ($nextIndex -lt $blocks.Count -and $blocks[$nextIndex].Date -eq $blocks[$blockIndex].Date) {
            $group.Add($blocks[$nextIndex])
            $nextIndex += 1
        }

        if ($cursor -le $blocks[$blockIndex].Start - 1) {
            foreach ($line in $lines[$cursor..($blocks[$blockIndex].Start - 1)]) {
                $result.Add($line)
            }
        }

        if ($group.Count -gt 1) {
            foreach ($line in (Convert-DayGroup -Blocks $group.ToArray())) {
                $result.Add($line)
            }
        } else {
            foreach ($line in $group[0].Lines) {
                $result.Add($line)
            }
        }

        $cursor = $group[$group.Count - 1].End + 1
        $blockIndex = $nextIndex
    }

    if ($cursor -lt $lines.Count) {
        foreach ($line in $lines[$cursor..($lines.Count - 1)]) {
            $result.Add($line)
        }
    }

    $output = ($result -join [Environment]::NewLine) + [Environment]::NewLine
    [System.IO.File]::WriteAllText($path, $output, [System.Text.UTF8Encoding]::new($false))
    Write-Host "DAILY_RELEASE_NOTES_COMPRESSED $([System.IO.Path]::GetFileName($path))"
}
