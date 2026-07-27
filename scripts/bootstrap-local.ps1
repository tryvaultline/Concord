# Concord PowerShell Bootstrap Script
Write-Host "========================================" -ForegroundColor Cipher
Write-Host "Bootstrapping Concord Local Stack..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cipher

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

if (-not (Test-Path ".env.local")) {
    Write-Host "[CONFIG] Creating .env.local from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env.local"
} else {
    Write-Host "[CONFIG] .env.local already exists." -ForegroundColor Green
}

Write-Host "[NPM] Installing Concord Auth Service dependencies..." -ForegroundColor Yellow
Set-Location "services\concord-auth"
npm install
Set-Location "..\.."

Write-Host "[BOOTSTRAP] Concord environment initialized successfully!" -ForegroundColor Green
