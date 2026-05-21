# ============================================================
# 02-Install-SwitchLauncher.ps1
# Installation et vérification de SwitchLauncher.exe
# ============================================================

# Chargement des fonctions communes
. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début de l'installation de SwitchLauncher."

# Chemin attendu de l'application
$SwitchLauncherPath = "$Global:TargetTechApps\SwitchLauncher.exe"

# Vérification de la présence du fichier
if (-not (Test-Path $SwitchLauncherPath)) {
    Write-Log "SwitchLauncher.exe introuvable : $SwitchLauncherPath" "ERROR"
    throw "Installation impossible : SwitchLauncher.exe est absent."
}

Write-Log "SwitchLauncher.exe trouvé : $SwitchLauncherPath"

# Vérification simple de l'exécutable
try {
    $fileInfo = Get-Item $SwitchLauncherPath
    Write-Log "Taille du fichier : $($fileInfo.Length) octets"
    Write-Log "Date de modification : $($fileInfo.LastWriteTime)"
}
catch {
    Write-Log "Impossible de lire les informations du fichier SwitchLauncher.exe" "ERROR"
    throw
}

# Création d'un fichier de configuration simple
$ConfigPath = "$Global:TargetTechConfig\launcher-config.json"

$ConfigContent = @"
{
  "LauncherPath": "C:\\TargetTech\\Apps\\SwitchLauncher.exe",
  "SiteUrl": "https://target-tech.fr",
  "ChromePath": "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  "Mode": "Debug"
}
"@

Set-Content -Path $ConfigPath -Value $ConfigContent -Encoding UTF8
Write-Log "Fichier de configuration créé : $ConfigPath"

Write-Log "Installation de SwitchLauncher terminée."