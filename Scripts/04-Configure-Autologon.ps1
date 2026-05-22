# ============================================================
# 04-Configure-Autologon.ps1
# Configuration de l'ouverture automatique du compte kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début de la configuration Autologon kiosk."

$KioskUser = "kiosk"
$KioskPassword = Read-Host "Entrer le mot de passe temporaire du compte kiosk" -AsSecureString
$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

# Vérification du compte kiosk
if (-not (Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue)) {
    Write-Log "Compte kiosk introuvable. Autologon impossible." "ERROR"
    throw "Compte kiosk introuvable."
}

# Récupération du nom de la machine locale
$ComputerName = $env:COMPUTERNAME

# Activation de l'autologon Windows
Set-ItemProperty -Path $WinlogonPath -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $WinlogonPath -Name "DefaultUserName" -Value $KioskUser -Type String
Set-ItemProperty -Path $WinlogonPath -Name "DefaultPassword" -Value $KioskPasswordPlain -Type String
Set-ItemProperty -Path $WinlogonPath -Name "DefaultDomainName" -Value $ComputerName -Type String

Write-Log "Autologon configuré pour l'utilisateur $KioskUser."
Write-Log "Nom machine utilisé comme domaine local : $ComputerName"
Write-Log "Configuration Autologon terminée."