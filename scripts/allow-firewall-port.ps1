# Concord PowerShell Windows Firewall Rule Helper
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Configuring Windows Defender Firewall..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$ruleName = "Concord Auth Server (Port 8080 LAN)"

try {
    $existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "✅ Firewall rule '$ruleName' already exists." -ForegroundColor Green
    } else {
        Write-Host "[FIREWALL] Adding Inbound Rule for Port 8080..." -ForegroundColor Yellow
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow -Profile Any
        Write-Host "✅ Port 8080 opened successfully for LAN access!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Run this script as Administrator to auto-allow Port 8080 in Windows Firewall." -ForegroundColor Yellow
    Write-Host "Alternative manual command (run in Admin PowerShell):" -ForegroundColor Gray
    Write-Host "New-NetFirewallRule -DisplayName '$ruleName' -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow" -ForegroundColor Gray
}
