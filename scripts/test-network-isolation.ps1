# Concord Network Isolation Readiness Audit Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auditing Concord Network-Isolation Readiness..." -ForegroundColor Cyan
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

$matches = Get-ChildItem -Path "$rootPath\clients\ios" -Recurse -File -Include "*.swift", "*.m", "*.mm", "*.plist", "*.xcconfig" |
    Select-String -Pattern ($forbiddenDomains -join '|')

if ($matches) {
    Write-Host "NOT_READY: upstream Signal endpoint references remain in the iOS source." -ForegroundColor Yellow
    $matches | Select-Object -First 50 Path, LineNumber, Line | Format-Table -AutoSize
    Exit 1
}

Write-Host "SOURCE_SCAN_PASSED; runtime traffic capture is still required before claiming network isolation." -ForegroundColor Yellow
