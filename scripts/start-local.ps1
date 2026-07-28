# Concord PowerShell Start Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Concord Local Service Stack..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

# Start Auth Service in background process or node directly
Write-Host "[SERVICE] Starting Concord Auth Server..." -ForegroundColor Yellow
$process = Start-Process node -ArgumentList "services/concord-auth/server.js" -PassThru -WindowStyle Hidden
$process.Id | Out-File -FilePath ".concord-auth.pid" -Encoding ascii

Start-Sleep -Seconds 2

# Check Health
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/v1/health" -Method Get
    Write-Host "[HEALTH] Auth Service is LIVE!" -ForegroundColor Green
    Write-Host "[HEALTH] Status: $($health.status) | Signal Protocol: $($health.signalProtocolIntegration)" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Could not reach Concord Auth Service." -ForegroundColor Red
}
