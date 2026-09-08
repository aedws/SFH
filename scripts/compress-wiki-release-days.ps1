param(
    [switch]$Check,
    [switch]$Normalize
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

function Get-DayCounts([string]$Content) {
    $counts = @{ BUILD = 0; IMPROVE = 0; CHANGE = 0; FIX = 0 }
    $labels = @{ '구현'='BUILD'; '개선'='IMPROVE'; '수정'='CHANGE'; '버그픽스'='FIX' }
    $headings = [regex]::Matches([System.Net.WebUtility]::HtmlDecode($Content), '<div class="sfh-group"><h3>[^<]*?(?<label>구현|개선|수정|버그픽스)[^<]*?(?<count>\d+)</h3>')
    if ($headings.Count) {
        foreach ($heading in $headings) { $counts[$labels[$heading.Groups['label'].Value]] += [int]$heading.Groups['count'].Value }
    } else {
        foreach ($pair in @(@('BUILD','is-build'),@('IMPROVE','is-improve'),@('CHANGE','is-change'),@('FIX','is-fix'))) {
            $counts[$pair[0]] = [regex]::Matches($Content, "sfh-badge $($pair[1])").Count
        }
    }
    return $counts
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

    if ($Normalize) {
        foreach ($block in $blocks) {
            $content = $block.Lines -join "`n"
            $numbers = [regex]::Matches($content, '<small>UPDATE (?<number>\d+)</small>')
            if (-not $numbers.Count) { continue }
            $maximum = ($numbers | ForEach-Object { [int]$_.Groups['number'].Value } | Measure-Object -Maximum).Maximum
            $counts = Get-DayCounts $content
            for ($i=$block.Start; $i -le $block.End; $i++) {
                if ($lines[$i] -match '<details class="sfh-bundle"') {
                    $nextNumber = [regex]::Match($lines[$i+1], '<small>UPDATE (?<number>\d+)</small>')
                    $opening = if ($nextNumber.Success -and [int]$nextNumber.Groups['number'].Value -eq $maximum) { '<details class="sfh-bundle" open>' } else { '<details class="sfh-bundle">' }
                    $lines[$i] = $lines[$i] -replace '<details class="sfh-bundle"(?: open)?>', $opening
                }
                if ($lines[$i] -match 'sfh-day-title') {
                    foreach ($kind in @('BUILD','IMPROVE','CHANGE','FIX')) { $lines[$i] = $lines[$i] -replace "$kind \d+", "$kind $($counts[$kind])" }
                }
                if ($lines[$i] -match 'sfh-daily-overview') {
                    foreach ($kind in @('BUILD','IMPROVE','CHANGE','FIX')) { $lines[$i] = $lines[$i] -replace "<b>\d+</b><small>$kind</small>", "<b>$($counts[$kind])</b><small>$kind</small>" }
                }
            }
        }
        [System.IO.File]::WriteAllLines($path, $lines, [System.Text.UTF8Encoding]::new($false))
        Write-Host "DAILY_RELEASE_NOTES_NORMALIZED $([System.IO.Path]::GetFileName($path))"
        continue
    }

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
            $actualNumbers = @($numberMatches | ForEach-Object { [int]$_.Groups['number'].Value })
            if ((($actualNumbers | Sort-Object) -join ',') -ne ((1..$bundleMatches.Count) -join ',')) { throw "Duplicate or missing daily update IDs ($path / $($block.Date))." }
            for ($numberIndex = 0; $numberIndex -lt $numberMatches.Count; $numberIndex += 1) {
                $descending = $isHomePage -or [int]$numberMatches[0].Groups['number'].Value -eq $numberMatches.Count
                $expectedNumber = if ($descending) {
                    $numberMatches.Count - $numberIndex
                } else {
                    $numberIndex + 1
                }
                if ($isHomePage -and [int]$numberMatches[$numberIndex].Groups['number'].Value -ne $expectedNumber) {
                    throw "Daily bundle numbering does not match the page order ($path / $($block.Date))."
                }
            }
            $openBundles = @($bundleMatches | Where-Object { $_.Groups['open'].Success })
            $expectedOpenIndex = [array]::IndexOf($actualNumbers, $bundleMatches.Count)
            if ($openBundles.Count -gt 1 -or ($openBundles.Count -eq 1 -and -not $bundleMatches[$expectedOpenIndex].Groups['open'].Success)) {
                throw "Only the latest daily bundle may be expanded by default ($path / $($block.Date))."
            }
            $badgeSummary = @(
                @{ Label = 'BUILD'; Class = 'is-build'; GroupIndex = 0 },
                @{ Label = 'IMPROVE'; Class = 'is-improve'; GroupIndex = 1 },
                @{ Label = 'CHANGE'; Class = 'is-change'; GroupIndex = 2 },
                @{ Label = 'FIX'; Class = 'is-fix'; GroupIndex = 3 }
            )
            $counts = Get-DayCounts $blockContent
            foreach ($badge in $badgeSummary) {
                $actualBadgeCount = $counts[$badge.Label]
                $declaredBadgeCount = [regex]::Match($blockContent, "$($badge.Label) (?<count>\d+)")
                if ((-not $declaredBadgeCount.Success) -or ([int]$declaredBadgeCount.Groups['count'].Value -ne $actualBadgeCount)) {
                    throw "The $($badge.Label) daily total is stale ($path / $($block.Date)): declared=$($declaredBadgeCount.Groups['count'].Value) actual=$actualBadgeCount."
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
