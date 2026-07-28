# Concord PowerShell Start Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Concord Local Service Stack..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location "$scriptPath\.."

if (Test-Path -LiteralPath ".env.local") {
    Get-Content -LiteralPath ".env.local" | ForEach-Object {
        if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
            Set-Item -Path "Env:$($matches[1])" -Value $matches[2]
        }
    }
} else {
    Write-Host "[ERROR] .env.local is required for the two local seed accounts." -ForegroundColor Red
    Exit 1
}

if (Test-Path -LiteralPath ".concord-auth.pid") {
    $existingProcessId = Get-Content -LiteralPath ".concord-auth.pid" -ErrorAction SilentlyContinue
    if ($existingProcessId -and (Get-Process -Id $existingProcessId -ErrorAction SilentlyContinue)) {
        Write-Host "[ERROR] Concord Auth is already running (PID $existingProcessId)." -ForegroundColor Red
        Exit 1
    }
    Remove-Item -LiteralPath ".concord-auth.pid" -Force
}

# Local development only: permits a test iPhone on the same private LAN to
# reach the service. Production deployments must use HTTPS and a restricted
# network policy.
$env:CONCORD_AUTH_BIND_HOST = "0.0.0.0"

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
