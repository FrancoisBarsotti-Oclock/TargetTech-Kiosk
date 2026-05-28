# ============================================================
# 14-Log-AdminLogon.ps1
# Journalise les connexions des comptes administrateurs
# ============================================================

$LogPath = "C:\TargetTech\Logs\admin-logon.log"

# Crée le dossier Logs si nécessaire
New-Item -ItemType Directory -Force -Path "C:\TargetTech\Logs" | Out-Null

# Récupération de l'utilisateur connecté
$User = "$env:USERDOMAIN\$env:USERNAME"
$Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Vérifie si l'utilisateur courant est administrateur local
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

$IsAdmin = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Si l'utilisateur est admin, écrire dans le log
if ($IsAdmin) {
    Add-Content -Path $LogPath -Value "[$Date] Connexion administrateur détectée : $User"
}