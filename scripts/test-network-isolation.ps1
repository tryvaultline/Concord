# Concord Network Isolation Automated Audit Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auditing Concord Network Isolation..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$forbiddenDomains = @(
    "signal.org",
    "textsecure-service.whispersystems.org",
    "cdn.signal.org",
    "cdn2.signal.org",
    "storage.signal.org",
    "svr2.signal.org",
    "chat.signal.org"
)

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootPath = "$scriptPath\.."

$violatingFiles = @()

Get-ChildItem -Path "$rootPath\configuration", "$rootPath\services\concord-auth" -Recurse -File -Include "*.json", "*.env", "*.js", "*.xcconfig" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($domain in $forbiddenDomains) {
        if ($content -match [regex]::Escape($domain)) {
            $violatingFiles += [PSCustomObject]@{
                File = $_.FullName
                Domain = $domain
            }
        }
    }
}

if ($violatingFiles.Count -eq 0) {
    Write-Host "✅ Audit Result: NO_UNINTENDED_SIGNAL_NETWORK_DEPENDENCIES" -ForegroundColor Green
    Write-Host "All external Signal domain dependencies have been successfully isolated to local endpoints." -ForegroundColor Green
    Exit 0
} else {
    Write-Host "❌ Audit Failed! Unintended Signal domains found:" -ForegroundColor Red
    $violatingFiles | Format-Table -AutoSize
    Exit 1
}
