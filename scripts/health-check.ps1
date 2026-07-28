# Concord PowerShell Health Check Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running Concord Health Checks..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    $res = Invoke-RestMethod -Uri "http://localhost:8080/v1/health" -Method Get
    if ($res.status -eq "OK") {
        Write-Host "✅ Concord Auth Service: HEALTHY" -ForegroundColor Green
        Write-Host "   Service: $($res.service)" -ForegroundColor Gray
        Write-Host "   Authentication: $($res.authentication)" -ForegroundColor Gray
        Write-Host "   Seeded Accounts Loaded: $($res.seededAccountCount)" -ForegroundColor Gray
        Write-Host "   Signal Protocol Integration: $($res.signalProtocolIntegration)" -ForegroundColor Gray
        Exit 0
    } else {
        Write-Host "❌ Concord Auth Service: UNHEALTHY" -ForegroundColor Red
        Exit 1
    }
} catch {
    Write-Host "❌ Could not connect to Concord Auth Service on port 8080." -ForegroundColor Red
    Exit 1
}
