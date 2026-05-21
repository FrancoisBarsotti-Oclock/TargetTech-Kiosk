# ============================================================
# Common.ps1
# Fonctions communes du projet TargetTech Kiosk
# ============================================================

# Chemins principaux du projet
$Global:TargetTechRoot   = "C:\TargetTech"
$Global:TargetTechApps   = "C:\TargetTech\Apps"
$Global:TargetTechLogs   = "C:\TargetTech\Logs"
$Global:TargetTechConfig = "C:\TargetTech\Config"
$Global:TargetTechBackup = "C:\TargetTech\Backup"

# Fonction de journalisation
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )

    # Création du timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format de ligne de log
    $line = "[$timestamp] [$Level] $Message"

    # Écriture dans le fichier de log
    Add-Content -Path "$Global:TargetTechLogs\deployment.log" -Value $line

    # Affichage dans la console
    Write-Host $line
}