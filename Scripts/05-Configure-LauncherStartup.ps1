# ============================================================
# 05-Configure-LauncherStartup.ps1
# Lancement automatique de SwitchLauncher au logon kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration lancement automatique SwitchLauncher."

$LauncherPath = "C:\TargetTech\Apps\SwitchLauncher.exe"
$StartupFolder = "C:\Users\kiosk\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
$ShortcutPath = Join-Path $StartupFolder "SwitchLauncher.lnk"

if (-not (Test-Path $LauncherPath)) {
    Write-Log "SwitchLauncher introuvable : $LauncherPath" "ERROR"
    throw "SwitchLauncher.exe absent."
}

# Création du dossier Startup du profil kiosk si nécessaire
New-Item -ItemType Directory -Force -Path $StartupFolder | Out-Null
Write-Log "Dossier Startup vérifié : $StartupFolder"

# Création du raccourci Windows
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = $LauncherPath
$Shortcut.WorkingDirectory = "C:\TargetTech\Apps"
$Shortcut.Description = "Lancement automatique TargetTech SwitchLauncher"
$Shortcut.Save()

Write-Log "Raccourci de démarrage créé : $ShortcutPath"
Write-Log "Configuration lancement automatique terminée."