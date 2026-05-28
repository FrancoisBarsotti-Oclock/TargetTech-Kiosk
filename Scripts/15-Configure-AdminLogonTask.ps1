# ============================================================
# 15-Configure-AdminLogonTask.ps1
# Crée une tâche planifiée qui journalise les connexions admin
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration tâche log admin."

$TaskName = "TargetTech-LogAdminLogon"
$ScriptPath = "C:\TargetTech\Scripts\14-Log-AdminLogon.ps1"
$PowerShellPath = "C:\Program Files\PowerShell\7\pwsh.exe"

# Vérifie que le script existe
if (-not (Test-Path $ScriptPath)) {
    Write-Log "Script de log admin introuvable : $ScriptPath" "ERROR"
    throw "Script de log admin absent."
}

# Vérifie PowerShell 7
if (-not (Test-Path $PowerShellPath)) {
    Write-Log "PowerShell 7 introuvable : $PowerShellPath" "ERROR"
    throw "PowerShell 7 absent."
}

# Supprime l'ancienne tâche si elle existe
schtasks /Delete /TN $TaskName /F 2>$null

# Crée une tâche au logon de n'importe quel utilisateur
schtasks /Create `
    /TN $TaskName `
    /TR "`"$PowerShellPath`" -ExecutionPolicy Bypass -File `"$ScriptPath`"" `
    /SC ONLOGON `
    /RL HIGHEST `
    /F

Write-Log "Tâche log admin créée : $TaskName"
Write-Log "Configuration tâche log admin terminée."