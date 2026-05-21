# ============================================================
# 01-Prepare-TargetTech.ps1
# Préparation de l'arborescence TargetTech
# ============================================================

# Chargement des fonctions communes
. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début de la préparation TargetTech."

# Création des dossiers nécessaires
$folders = @(
    $Global:TargetTechRoot,
    $Global:TargetTechApps,
    $Global:TargetTechLogs,
    $Global:TargetTechConfig,
    $Global:TargetTechBackup
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
        Write-Log "Dossier créé : $folder"
    }
    else {
        Write-Log "Dossier déjà présent : $folder"
    }
}

Write-Log "Préparation TargetTech terminée."