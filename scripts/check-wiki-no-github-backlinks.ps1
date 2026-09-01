param(
    [string]$SiteRoot = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot "docs") -Recurse -File |
        Where-Object { $_.Extension -in @(".md", ".html", ".js", ".json", ".yml", ".yaml") }
)
$sourceFiles += Get-Item -LiteralPath (Join-Path $repositoryRoot "mkdocs.yml")

$urlPattern = 'https?://[^\s"''<>]*(github\.com|github\.io|githubusercontent\.com)'
$configPattern = '(?m)^\s*(repo_url|repo_name|edit_uri)\s*:|content\.action\.(edit|view)'
$violations = [System.Collections.Generic.List[string]]::new()

foreach ($file in $sourceFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName)
    if ($content -match $urlPattern -or $content -match $configPattern) {
        $violations.Add($file.FullName)
    }
}

if (-not [string]::IsNullOrWhiteSpace($SiteRoot)) {
    $resolvedSiteRoot = if ([System.IO.Path]::IsPathRooted($SiteRoot)) {
        $SiteRoot
    } else {
        Join-Path $repositoryRoot $SiteRoot
    }
    foreach ($file in Get-ChildItem -LiteralPath $resolvedSiteRoot -Recurse -File -Filter "*.html") {
        if ([System.IO.File]::ReadAllText($file.FullName) -match $urlPattern) {
            $violations.Add($file.FullName)
        }
    }
}

if ($violations.Count -gt 0) {
    throw "GitHub backlink or repository UI configuration remains: $($violations -join ', ')"
}

Write-Host "WIKI_GITHUB_BACKLINKS_OK source=$($sourceFiles.Count) generated=$(-not [string]::IsNullOrWhiteSpace($SiteRoot))"
