$ErrorActionPreference = "Stop"

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$mapPath = Join-Path $repositoryRoot "docs/assets/knowledge-map.json"
$mkdocsPath = Join-Path $repositoryRoot "mkdocs.yml"
$javascriptPath = Join-Path $repositoryRoot "docs/javascripts/knowledge-map.js"
$stylesheetPath = Join-Path $repositoryRoot "docs/stylesheets/extra.css"
$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path -LiteralPath $mapPath)) {
    throw "Knowledge map data is missing: $mapPath"
}

$map = Get-Content -LiteralPath $mapPath -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $map.root -or -not $map.root.categories) {
    throw "Knowledge map root or categories are missing."
}

$mappedSources = [System.Collections.Generic.List[string]]::new()
$mappedRoutes = [System.Collections.Generic.List[string]]::new()
$groupCount = 0
$siteUrlMatch = [regex]::Match((Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8), '(?m)^site_url:\s*(?<url>\S+)\s*$')
if (-not $siteUrlMatch.Success) {
    throw "MkDocs site_url is required for node route validation."
}
$siteUrl = [Uri]::new($siteUrlMatch.Groups['url'].Value.TrimEnd('/') + '/')

foreach ($category in $map.root.categories) {
    if ([string]::IsNullOrWhiteSpace($category.id) -or [string]::IsNullOrWhiteSpace($category.label)) {
        $errors.Add("Every L2 category needs id and label.")
    }
    if (-not $category.groups -or $category.groups.Count -lt 1) {
        $errors.Add("Category '$($category.label)' has no L3 groups.")
        continue
    }
    foreach ($group in $category.groups) {
        $groupCount += 1
        if ([string]::IsNullOrWhiteSpace($group.id) -or [string]::IsNullOrWhiteSpace($group.label)) {
            $errors.Add("Every L3 group needs id and label.")
        }
        if (-not $group.documents -or $group.documents.Count -lt 1) {
            $errors.Add("Group '$($group.label)' has no L4 documents.")
            continue
        }
        foreach ($documentNode in $group.documents) {
            $source = [string]$documentNode.source
            $route = [string]$documentNode.route
            if ([string]::IsNullOrWhiteSpace($documentNode.label) -or [string]::IsNullOrWhiteSpace($documentNode.summary)) {
                $errors.Add("Document '$source' needs label and summary.")
            }
            if ([string]::IsNullOrWhiteSpace($source)) {
                $errors.Add("Every L4 document needs a source path.")
                continue
            }
            $mappedSources.Add($source)
            $mappedRoutes.Add($route)
            $sourcePath = Join-Path (Join-Path $repositoryRoot "docs") $source
            if (-not (Test-Path -LiteralPath $sourcePath)) {
                $errors.Add("Mapped document does not exist: $source")
            }
            $expectedRoute = if ($source -eq "index.md") {
                ""
            }
            elseif ($source.EndsWith("/index.md")) {
                $source.Substring(0, $source.Length - "index.md".Length)
            }
            else {
                $source.Substring(0, $source.Length - ".md".Length) + "/"
            }
            if ($route -ne $expectedRoute) {
                $errors.Add("Route mismatch for '$source': expected '$expectedRoute', got '$route'.")
            }
            if ($route.StartsWith('/') -or $route.Contains('..') -or $route.Contains('?') -or $route.Contains('#')) {
                $errors.Add("Route must stay canonical and site-root relative for '$source': '$route'.")
            }
            $publishedUrl = [Uri]::new($siteUrl, $route)
            if (-not $publishedUrl.AbsoluteUri.StartsWith($siteUrl.AbsoluteUri, [System.StringComparison]::OrdinalIgnoreCase)) {
                $errors.Add("Route escapes the published wiki root for '$source': '$publishedUrl'.")
            }
        }
    }
}

$duplicateSources = $mappedSources | Group-Object | Where-Object Count -gt 1
foreach ($duplicate in $duplicateSources) {
    $errors.Add("Document is mapped more than once: $($duplicate.Name)")
}
$duplicateRoutes = $mappedRoutes | Group-Object | Where-Object Count -gt 1
foreach ($duplicate in $duplicateRoutes) {
    $errors.Add("Route is mapped more than once: $($duplicate.Name)")
}

$navSources = [System.Collections.Generic.List[string]]::new()
foreach ($line in Get-Content -LiteralPath $mkdocsPath -Encoding UTF8) {
    foreach ($match in [regex]::Matches($line, "([A-Za-z0-9_./-]+\.md)")) {
        $navSources.Add($match.Groups[1].Value)
    }
}

$missingFromMap = $navSources | Where-Object { $_ -notin $mappedSources }
$notInNavigation = $mappedSources | Where-Object { $_ -notin $navSources }
foreach ($source in $missingFromMap) {
    $errors.Add("Navigation document is missing from the L1-L4 map: $source")
}
foreach ($source in $notInNavigation) {
    $errors.Add("Mapped document is missing from MkDocs navigation: $source")
}

$allDocs = Get-ChildItem -LiteralPath (Join-Path $repositoryRoot "docs") -Recurse -Filter "*.md" |
    ForEach-Object { $_.FullName.Substring((Join-Path $repositoryRoot "docs").Length + 1).Replace("\", "/") }
foreach ($source in $allDocs) {
    if ($source -notin $mappedSources) {
        $errors.Add("Repository document is missing from the knowledge map: $source")
    }
}

$javascript = Get-Content -LiteralPath $javascriptPath -Raw -Encoding UTF8
$stylesheet = Get-Content -LiteralPath $stylesheetPath -Raw -Encoding UTF8
$mkdocs = Get-Content -LiteralPath $mkdocsPath -Raw -Encoding UTF8
if ($javascript -notmatch 'data-sfh-knowledge-map' -or $javascript -notmatch 'assets/knowledge-map.json') {
    $errors.Add("Knowledge map JavaScript does not install or load the graph data.")
}
if ($javascript -notmatch 'document\.currentScript' -or
    $javascript -notmatch 'new URL\("\.\./", knowledgeMapScriptUrl\)' -or
    $javascript -notmatch 'getRouteUrl\(documentNode\.route, siteRoot\)') {
    $errors.Add("Knowledge map routes are not anchored to the stable script-derived site root.")
}
if ($javascript -notmatch 'window\.location\.pathname === "/"' -or $javascript -notmatch 'startsWith\("/access/login"\)') {
    $errors.Add("The public home and login page must not request the protected knowledge map.")
}
if ($stylesheet -notmatch '\.sfh-knowledge-map__graph' -or $stylesheet -notmatch '\.sfh-map-node--document') {
    $errors.Add("Knowledge map HUD styles are incomplete.")
}
if (
	$stylesheet -notmatch 'pointer-events:\s*none' -or
	$javascript -notmatch 'aria-labelledby' -or
	$javascript -notmatch 'aria-controls' -or
	$javascript -notmatch 'restored\.focus' -or
	$javascript -match 'rootNode\.disabled\s*=\s*true'
) {
	$errors.Add("Knowledge map accessibility contract is incomplete: non-blocking decoration, named relationships, and focus restoration are required.")
}
if ($mkdocs -notmatch 'javascripts/knowledge-map\.js') {
    $errors.Add("MkDocs does not load knowledge-map.js.")
}

if ($errors.Count -gt 0) {
    throw ($errors -join [Environment]::NewLine)
}

Write-Host "WIKI_KNOWLEDGE_MAP_OK documents=$($mappedSources.Count) categories=$($map.root.categories.Count) groups=$groupCount depth=4"
