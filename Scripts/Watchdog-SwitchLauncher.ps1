# ============================================================
# Watchdog-SwitchLauncher.ps1
# Surveille SwitchLauncher et relance la tâche élevée si besoin
# ============================================================

$LogPath = "C:\TargetTech\Logs\watchdog.log"
$LauncherTaskName = "TargetTech-KioskLauncher"

function Write-WatchdogLog {
    param([string]$Message)

    $Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$Date] $Message"
}

Write-WatchdogLog "Watchdog démarré."

while ($true) {

    $Launcher = Get-Process -Name "SwitchLauncher" -ErrorAction SilentlyContinue

    if ($null -eq $Launcher) {
        Write-WatchdogLog "SwitchLauncher absent. Relance via tâche $LauncherTaskName."

        schtasks /Run /TN $LauncherTaskName | Out-Null

        Start-Sleep -Seconds 5
    }

    Start-Sleep -Seconds 3
}