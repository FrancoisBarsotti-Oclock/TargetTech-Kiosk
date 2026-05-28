# ============================================================
# Watchdog-SwitchLauncher.ps1
# Surveille SwitchLauncher.exe et le relance si nécessaire
# ============================================================

$LauncherPath = "C:\TargetTech\Apps\SwitchLauncher.exe"
$LogPath = "C:\TargetTech\Logs\watchdog.log"

function Write-WatchdogLog {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$timestamp] $Message"
}

Write-WatchdogLog "Watchdog démarré."

while ($true) {
    # Vérifie si SwitchLauncher tourne déjà
    $process = Get-Process -Name "SwitchLauncher" -ErrorAction SilentlyContinue

    if ($null -eq $process) {
        Write-WatchdogLog "SwitchLauncher absent. Relance en cours."

        try {
            schtasks /Run /TN "TargetTech-SwitchLauncher-Elevated" | Out-Null
            Write-WatchdogLog "Tâche SwitchLauncher-Elevated exécutée."
        }
        catch {
            Write-WatchdogLog "Erreur relance SwitchLauncher : $($_.Exception.Message)"
        }
    }

    Start-Sleep -Seconds 3
}