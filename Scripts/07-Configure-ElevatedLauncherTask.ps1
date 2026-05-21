# ============================================================
# 07-Configure-ElevatedLauncherTask.ps1
# Lance SwitchLauncher avec privilèges élevés au logon kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Création tâche planifiée élevée SwitchLauncher."

$TaskName = "TargetTech-SwitchLauncher-Elevated"
$LauncherPath = "C:\TargetTech\Apps\SwitchLauncher.exe"

if (-not (Test-Path $LauncherPath)) {
    Write-Log "SwitchLauncher introuvable : $LauncherPath" "ERROR"
    throw "SwitchLauncher introuvable."
}

# Supprimer ancienne tâche si elle existe
schtasks /Delete /TN $TaskName /F 2>$null

# Créer une tâche interactive au logon kiosk, avec niveau le plus élevé
schtasks /Create `
    /TN $TaskName `
    /TR "`"$LauncherPath`"" `
    /SC ONLOGON `
    /RU kiosk `
    /RL HIGHEST `
    /IT `
    /F

Write-Log "Tâche planifiée élevée créée : $TaskName"