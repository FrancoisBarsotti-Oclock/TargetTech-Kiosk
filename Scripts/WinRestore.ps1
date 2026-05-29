# ============================================================
# WinRestore.ps1
# Restaure Windows en mode administrable
# ============================================================

Write-Host "Restauration Windows administrable..."

$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$PoliciesPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"

# Restaurer Explorer.exe comme shell Windows
Set-ItemProperty -Path $WinlogonPath -Name "Shell" -Value "explorer.exe"

# Désactiver l'autologon kiosk
Set-ItemProperty -Path $WinlogonPath -Name "AutoAdminLogon" -Value "0" -Type String

# Supprimer les valeurs d'autologon
Remove-ItemProperty -Path $WinlogonPath -Name "DefaultUserName" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $WinlogonPath -Name "DefaultPassword" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $WinlogonPath -Name "DefaultDomainName" -ErrorAction SilentlyContinue

# Réafficher l'option "Changer d'utilisateur"
Remove-ItemProperty -Path $PoliciesPath -Name "HideFastUserSwitching" -ErrorAction SilentlyContinue

# Supprimer les tâches planifiées TargetTech kiosk
$Tasks = @(
    "TargetTech-KioskSession",
    "TargetTech-KillExplorer",
    "TargetTech-Watchdog",
    "TargetTech-SwitchLauncher-Elevated",
    "TargetTech-LogAdminLogon"
    "TargetTech-KioskLauncher"
    "TargetTech-CleanLauncher"
)

foreach ($Task in $Tasks) {
    schtasks /Delete /TN $Task /F 2>$null
}

# Arrêter les processus kiosk
Get-Process SwitchLauncher -ErrorAction SilentlyContinue | Stop-Process -Force

# Relancer Explorer immédiatement
Start-Process explorer.exe

Write-Host "Restauration terminée."
Write-Host "Redémarre la machine pour valider le retour complet à Windows."
Pause