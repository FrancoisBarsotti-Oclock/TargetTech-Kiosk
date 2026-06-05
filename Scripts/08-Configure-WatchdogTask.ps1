# ============================================================
# 08-Configure-WatchdogTask.ps1
# Création de la tâche planifiée du watchdog
# Lance le watchdog via VBS pour éviter toute fenêtre PowerShell visible
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration tâche planifiée Watchdog."

$TaskName = "TargetTech-Watchdog"
$WatchdogVbs = "C:\TargetTech\Scripts\Run-Watchdog.vbs"

# Vérifie que le lanceur VBS existe
if (-not (Test-Path $WatchdogVbs)) {
    Write-Log "VBS watchdog introuvable : $WatchdogVbs" "ERROR"
    throw "VBS watchdog absent."
}

# Supprime l'ancienne tâche si elle existe
schtasks /Delete /TN $TaskName /F 2>$null | Out-Null

# Crée une tâche élevée au logon kiosk
# wscript.exe lance le watchdog sans fenêtre visible
schtasks /Create `
    /TN $TaskName `
    /TR "`"wscript.exe`" `"$WatchdogVbs`"" `
    /SC ONLOGON `
    /RU kiosk `
    /RL HIGHEST `
    /IT `
    /F

Write-Log "Tâche watchdog créée : $TaskName"
Write-Log "Configuration watchdog terminée."