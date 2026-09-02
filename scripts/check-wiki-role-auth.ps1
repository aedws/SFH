param(
    [string]$SiteRoot = ""
)

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot

function Read-RequiredFile([string]$RelativePath) {
    $path = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing wiki role auth file: $RelativePath"
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$worker = Read-RequiredFile "cloudflare/wiki-auth/_worker.js"
$config = Read-RequiredFile "cloudflare/wiki-auth/wrangler.jsonc"
$script = Read-RequiredFile "docs/javascripts/role-auth.js"
$mkdocs = Read-RequiredFile "mkdocs.yml"
$architecture = Read-RequiredFile "docs/architecture/wiki-role-auth.md"
$seedScript = Read-RequiredFile "scripts/seed_wiki_auth.mjs"

foreach ($required in @(
    'HttpOnly; Secure; SameSite=Strict',
    'PBKDF2-SHA256',
    'credential_version',
    'x-csrf-token',
    'cf-connecting-ip',
    'private, no-store',
    'users/planner.json',
    'users/developer.json'
)) {
    if ($worker -notmatch [regex]::Escape($required)) {
        throw "Wiki auth worker contract is missing: $required"
    }
}

if ($config -notmatch '"binding":\s*"WIKI_AUTH"' -or $config -notmatch '"bucket_name":\s*"sfh-wiki-auth"') {
    throw "Wiki auth must use its isolated private R2 binding."
}
if ($mkdocs -notmatch 'javascripts/role-auth\.js' -or $mkdocs -notmatch 'architecture/wiki-role-auth\.md') {
    throw "Wiki navigation or role auth script is not registered."
}
foreach ($page in @("login", "account", "planner", "developer")) {
    $source = Read-RequiredFile "docs/access/$page.md"
    if ($source -notmatch '(?ms)search:\s*\r?\n\s*exclude:\s*true') {
        throw "Protected access page must be excluded from public search: $page"
    }
}
if ($script -notmatch '/api/auth' -or $script -notmatch 'data-sfh-auth-account') {
    throw "Role auth client does not expose login and protected account controls."
}
if ($architecture -notmatch 'Notion' -or $architecture -notmatch 'Google Sheet' -or $architecture -notmatch 'PR') {
    throw "Role auth documentation must preserve the collaboration sources of truth."
}
if ($seedScript -notmatch 'pepperFingerprint' -or $seedScript -notmatch 'pepper\.json') {
    throw "Wiki auth deployment must guard against accidental pepper rotation."
}

$forbiddenPatterns = @(
    '(?i)planner[_ -]?password\s*[:=]\s*["''][^"'']+',
    '(?i)developer[_ -]?password\s*[:=]\s*["''][^"'']+',
    '(?i)AUTH_PEPPER\s*[:=]\s*["''][^"'']+'
)
$trackedAuthText = $worker + "`n" + $script + "`n" + $architecture
foreach ($pattern in $forbiddenPatterns) {
    if ($trackedAuthText -match $pattern) {
        throw "A credential-like value was found in tracked wiki auth sources."
    }
}

if ($SiteRoot) {
    $resolvedSite = Resolve-Path -LiteralPath $SiteRoot
    foreach ($relative in @("_worker.js", "access/login/index.html", "access/account/index.html", "access/planner/index.html", "access/developer/index.html")) {
        if (-not (Test-Path -LiteralPath (Join-Path $resolvedSite $relative))) {
            throw "Built wiki auth artifact is missing: $relative"
        }
    }
    $searchIndexPath = Join-Path $resolvedSite "search/search_index.json"
    $searchIndex = Get-Content -LiteralPath $searchIndexPath -Raw -Encoding UTF8
    foreach ($protectedRoute in @("access/planner/", "access/developer/", "access/account/")) {
        if ($searchIndex.Contains($protectedRoute)) {
            throw "Protected page leaked into the public search index: $protectedRoute"
        }
    }
}

Write-Output "WIKI_ROLE_AUTH_CONTRACT_OK"
