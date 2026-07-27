# Concord PowerShell E2E Test Suite Runner
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Concord E2E Integration Suite..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

# Ensure Auth service is running
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/v1/health" -Method Get
} catch {
    Write-Host "[AUTO-START] Concord Auth Service not running. Starting now..." -ForegroundColor Yellow
    & "$scriptPath\start-local.ps1"
    Start-Sleep -Seconds 3
}

# Execute node test script
node scripts/test-concord-e2e.js
