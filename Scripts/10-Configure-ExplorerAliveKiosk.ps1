# ============================================================
# 10-Configure-ExplorerAliveKiosk.ps1
# Stratégie stable : Explorer reste actif mais l'utilisateur kiosk est verrouillé
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration Explorer vivant mais verrouillé."

$KioskUser = "kiosk"
$LauncherPath = "C:\TargetTech\Apps\SwitchLauncher.exe"
$TaskName = "TargetTech-KioskLauncher"
$HiveName = "KioskTempHive"
$NtUserDat = "C:\Users\$KioskUser\NTUSER.DAT"

# Vérification du launcher
if (-not (Test-Path $LauncherPath)) {
    Write-Log "SwitchLauncher introuvable : $LauncherPath" "ERROR"
    throw "SwitchLauncher absent."
}

# ------------------------------------------------------------
# 1. Nettoyer les anciennes tâches TargetTech
# ------------------------------------------------------------

$OldTasks = @(
    "TargetTech-SwitchLauncher-Elevated",
    "TargetTech-Watchdog",
    "TargetTech-KillExplorer",
    "TargetTech-KioskSession",
    "TargetTech-SwitchLauncher",
    "TargetTech-KioskLauncher"
)

foreach ($Task in $OldTasks) {
    schtasks /Delete /TN $Task /F 2>$null | Out-Null
    Write-Log "Suppression demandée pour tâche : $Task"
}

# ------------------------------------------------------------
# 2. Créer une tâche unique pour lancer SwitchLauncher au logon
# ------------------------------------------------------------

schtasks /Create `
    /TN $TaskName `
    /TR "`"$LauncherPath`"" `
    /SC ONLOGON `
    /RU $KioskUser `
    /RL HIGHEST `
    /IT `
    /F

Write-Log "Tâche de lancement kiosk créée : $TaskName"

# ------------------------------------------------------------
# 3. Charger le registre utilisateur kiosk
# ------------------------------------------------------------

if (-not (Test-Path $NtUserDat)) {
    Write-Log "Profil kiosk non initialisé : $NtUserDat" "ERROR"
    throw "Connecte-toi au moins une fois avec kiosk avant d'appliquer ce script."
}

reg unload "HKU\$HiveName" 2>$null | Out-Null
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {
    $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $SystemPolicy   = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\System"
    $WinlogonOld    = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"

    New-Item -Path $ExplorerPolicy -Force | Out-Null
    New-Item -Path $SystemPolicy -Force | Out-Null

    # --------------------------------------------------------
    # 4. Retirer les anciennes tentatives de remplacement shell utilisateur
    # --------------------------------------------------------

    Remove-ItemProperty -Path $WinlogonOld -Name "Shell" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $SystemPolicy -Name "Shell" -ErrorAction SilentlyContinue

    Write-Log "Anciennes clés Shell utilisateur nettoyées."

    # --------------------------------------------------------
    # 5. Restrictions Explorer / interface utilisateur
    # --------------------------------------------------------

    # Empêche Win+R / boîte Exécuter
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoRun" -Type DWord -Value 1

    # Désactive la plupart des raccourcis Windows avec la touche Win
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoWinKeys" -Type DWord -Value 1

    # Désactive clic droit dans Explorer / bureau
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoViewContextMenu" -Type DWord -Value 1

    # Désactive clic droit sur barre des tâches
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoTrayContextMenu" -Type DWord -Value 1

    # Masque les icônes du bureau
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoDesktop" -Type DWord -Value 1

    # Bloque accès panneau de configuration / paramètres classiques
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoControlPanel" -Type DWord -Value 1

    # --------------------------------------------------------
    # 6. Restrictions système utilisateur
    # --------------------------------------------------------

    # Désactive le Gestionnaire des tâches
    Set-ItemProperty -Path $SystemPolicy -Name "DisableTaskMgr" -Type DWord -Value 1

    # Désactive verrouillage de session
    Set-ItemProperty -Path $SystemPolicy -Name "DisableLockWorkstation" -Type DWord -Value 1

    # Désactive changement de mot de passe
    Set-ItemProperty -Path $SystemPolicy -Name "DisableChangePassword" -Type DWord -Value 1

    Write-Log "Restrictions utilisateur kiosk appliquées."
}
finally {
    reg unload "HKU\$HiveName" | Out-Null
    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Configuration Explorer vivant mais verrouillé terminée."