# ============================================================
# WinRestore.ps1
# Restaure Explorer.exe comme shell Windows par défaut
# ============================================================

Set-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" `
  -Name "Shell" `
  -Value "explorer.exe"

Write-Host "Explorer.exe restauré comme shell Windows."
Write-Host "Redémarre la machine."
Pause