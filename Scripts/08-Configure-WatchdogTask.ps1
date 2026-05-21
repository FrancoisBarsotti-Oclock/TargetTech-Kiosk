# ============================================================
# 08-Configure-WatchdogTask.ps1
# Création de la tâche planifiée du watchdog
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration tâche planifiée Watchdog."

$TaskName = "TargetTech-Watchdog"
$WatchdogScript = "C:\TargetTech\Scripts\Watchdog-SwitchLauncher.ps1"
$PowerShellPath = "C:\Program Files\PowerShell\7\pwsh.exe"

if (-not (Test-Path $WatchdogScript)) {
    Write-Log "Script watchdog introuvable : $WatchdogScript" "ERROR"
    throw "Script watchdog absent."
}

if (-not (Test-Path $PowerShellPath)) {
    Write-Log "PowerShell 7 introuvable : $PowerShellPath" "ERROR"
    throw "PowerShell 7 absent."
}

# Supprime l'ancienne tâche si elle existe
schtasks /Delete /TN $TaskName /F 2>$null

# Crée une tâche élevée au logon kiosk
schtasks /Create `
    /TN $TaskName `
    /TR "`"$PowerShellPath`" -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatchdogScript`"" `
    /SC ONLOGON `
    /RU kiosk `
    /RL HIGHEST `
    /IT `
    /F

Write-Log "Tâche watchdog créée : $TaskName"
Write-Log "Configuration watchdog terminée."