# ============================================================
# 14-Log-AdminLogon.ps1
# Journalise les connexions des comptes administrateurs
# ============================================================

$LogPath = "C:\TargetTech\Logs\admin-logon.log"

# Crée le dossier Logs si nécessaire
New-Item -ItemType Directory -Force -Path "C:\TargetTech\Logs" | Out-Null

# Récupération de l'utilisateur connecté
$User = $env:USERNAME
$UserFull = "$env:USERDOMAIN\$env:USERNAME"
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Journaliser toute connexion différente de kiosk
if ($User -ne "kiosk") {

    Add-Content `
        -Path $LogPath `
        -Value "[$Date] Connexion hors kiosk détectée : $UserFull"

}