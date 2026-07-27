# Concord PowerShell Stop Script
Write-Host "Stopping Concord Local Services..." -ForegroundColor Yellow

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

if (Test-Path ".concord-auth.pid") {
    $pidNum = Get-Content ".concord-auth.pid"
    Stop-Process -Id $pidNum -Force -ErrorAction SilentlyContinue
    Remove-Item ".concord-auth.pid" -Force
    Write-Host "[STOPPED] Concord Auth process ($pidNum) terminated." -ForegroundColor Green
} else {
    Write-Host "[INFO] No PID file found. Killing node processes matching concord..." -ForegroundColor Yellow
    Get-Process node -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*concord-auth*" } | Stop-Process -Force
}
