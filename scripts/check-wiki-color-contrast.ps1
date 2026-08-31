$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$stylesheetPath = Join-Path $repositoryRoot "docs/stylesheets/extra.css"
$stylesheet = Get-Content -LiteralPath $stylesheetPath -Raw -Encoding UTF8

function Get-CssVariables {
    param([Parameter(Mandatory)][string]$Block)

    $variables = @{}
    foreach ($match in [regex]::Matches($Block, '--(?<name>sfh-[a-z0-9-]+)\s*:\s*(?<value>#[0-9a-fA-F]{6})\s*;')) {
        $variables[$match.Groups['name'].Value] = $match.Groups['value'].Value.ToLowerInvariant()
    }
    return $variables
}

function Get-RelativeLuminance {
    param([Parameter(Mandatory)][string]$HexColor)

    $hex = $HexColor.TrimStart('#')
    $channels = for ($index = 0; $index -lt 6; $index += 2) {
        $value = [Convert]::ToInt32($hex.Substring($index, 2), 16) / 255.0
        if ($value -le 0.04045) { $value / 12.92 } else { [Math]::Pow(($value + 0.055) / 1.055, 2.4) }
    }
    return (0.2126 * $channels[0]) + (0.7152 * $channels[1]) + (0.0722 * $channels[2])
}

function Get-ContrastRatio {
    param(
        [Parameter(Mandatory)][string]$Foreground,
        [Parameter(Mandatory)][string]$Background
    )

    $foregroundLuminance = Get-RelativeLuminance $Foreground
    $backgroundLuminance = Get-RelativeLuminance $Background
    $lighter = [Math]::Max($foregroundLuminance, $backgroundLuminance)
    $darker = [Math]::Min($foregroundLuminance, $backgroundLuminance)
    return ($lighter + 0.05) / ($darker + 0.05)
}

$rootMatch = [regex]::Match($stylesheet, '(?s):root\s*\{(?<body>.*?)\}')
$defaultMatch = [regex]::Match($stylesheet, '(?s)\[data-md-color-scheme="default"\]\s*\{(?<body>.*?)\}')
if (-not $rootMatch.Success -or -not $defaultMatch.Success) {
    throw "Wiki color token blocks are missing."
}

$rootVariables = Get-CssVariables $rootMatch.Groups['body'].Value
$defaultVariables = @{}
foreach ($key in $rootVariables.Keys) { $defaultVariables[$key] = $rootVariables[$key] }
foreach ($entry in (Get-CssVariables $defaultMatch.Groups['body'].Value).GetEnumerator()) { $defaultVariables[$entry.Key] = $entry.Value }

$requiredVariables = @('sfh-bg', 'sfh-panel', 'sfh-panel-raised', 'sfh-line', 'sfh-text', 'sfh-text-soft', 'sfh-muted', 'sfh-dim', 'sfh-cyan', 'sfh-cyan-bright', 'sfh-green', 'sfh-violet', 'sfh-amber', 'sfh-red')
$checks = @(
    @{ Foreground = 'sfh-text'; Background = 'sfh-bg'; Minimum = 7.0; Label = 'primary text' },
    @{ Foreground = 'sfh-text-soft'; Background = 'sfh-bg'; Minimum = 7.0; Label = 'body text' },
    @{ Foreground = 'sfh-muted'; Background = 'sfh-bg'; Minimum = 7.0; Label = 'secondary text' },
    @{ Foreground = 'sfh-dim'; Background = 'sfh-bg'; Minimum = 4.5; Label = 'tertiary text' },
    @{ Foreground = 'sfh-cyan'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'accent' },
    @{ Foreground = 'sfh-cyan-bright'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'focus' },
    @{ Foreground = 'sfh-line'; Background = 'sfh-panel'; Minimum = 3.0; Label = 'boundary' },
    @{ Foreground = 'sfh-green'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'build status' },
    @{ Foreground = 'sfh-violet'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'change status' },
    @{ Foreground = 'sfh-amber'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'fix status' },
    @{ Foreground = 'sfh-red'; Background = 'sfh-panel'; Minimum = 7.0; Label = 'danger status' }
)

$errors = [System.Collections.Generic.List[string]]::new()
$schemeVariables = @{ slate = $rootVariables; default = $defaultVariables }
foreach ($scheme in $schemeVariables.Keys) {
    $variables = $schemeVariables[$scheme]
    foreach ($required in $requiredVariables) {
        if (-not $variables.ContainsKey($required)) { $errors.Add("$scheme is missing --$required.") }
    }
    foreach ($check in $checks) {
        if (-not $variables.ContainsKey($check.Foreground) -or -not $variables.ContainsKey($check.Background)) { continue }
        $ratio = Get-ContrastRatio $variables[$check.Foreground] $variables[$check.Background]
        if ($ratio -lt $check.Minimum) {
            $errors.Add("$scheme $($check.Label) contrast is $([Math]::Round($ratio, 2)):1; expected $($check.Minimum):1.")
        }
    }
}

if ($rootVariables['sfh-cyan'] -ne '#02e5e1') {
    $errors.Add("The SFH base accent must remain #02e5e1.")
}
if ($stylesheet -notmatch '/\* Readability calibration') {
    $errors.Add("The shared readability layer is missing.")
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "WIKI_COLOR_CONTRAST_OK schemes=2 checks=$($checks.Count * 2) base=$($rootVariables['sfh-cyan'])"
