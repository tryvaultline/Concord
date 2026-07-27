# Concord PowerShell Reset Script
Write-Host "Resetting Concord Local Environment..." -ForegroundColor Red

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

& "$scriptPath\stop-local.ps1"

if (Test-Path ".env.local") {
    Remove-Item ".env.local" -Force
}

& "$scriptPath\bootstrap-local.ps1"

Write-Host "[RESET] Environment fully reset!" -ForegroundColor Green
