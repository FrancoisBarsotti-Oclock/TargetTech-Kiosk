# ============================================================
# 09-Configure-KioskShell.ps1
# Configure le shell personnalisé du compte kiosk
# via la stratégie utilisateur "Custom User Interface"
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration shell kiosk."

$KioskUser = "kiosk"
$LauncherPath = "C:\TargetTech\Apps\SwitchLauncher.exe"
$HiveName = "KioskTempHive"
$HiveRoot = "Registry::HKEY_USERS\$HiveName"
$NtUserDat = "C:\Users\$KioskUser\NTUSER.DAT"

# Vérification du launcher
if (-not (Test-Path $LauncherPath)) {
    Write-Log "SwitchLauncher introuvable : $LauncherPath" "ERROR"
    throw "SwitchLauncher absent."
}

# Vérification du profil kiosk
if (-not (Test-Path $NtUserDat)) {
    Write-Log "NTUSER.DAT introuvable : $NtUserDat" "ERROR"
    throw "Profil kiosk non initialisé. Connecte-toi au moins une fois avec kiosk."
}

# Décharger l'éventuelle ancienne ruche temporaire
reg unload "HKU\$HiveName" 2>$null | Out-Null

# Charger la ruche registre de l'utilisateur kiosk
Write-Log "Chargement de la ruche utilisateur kiosk."
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {
    # Chemin de la stratégie utilisateur
    $PolicyPath = "$HiveRoot\Software\Microsoft\Windows\CurrentVersion\Policies\System"

    # Créer la clé si nécessaire
    New-Item -Path $PolicyPath -Force | Out-Null

    # Définir le shell personnalisé
    Set-ItemProperty `
        -Path $PolicyPath `
        -Name "Shell" `
        -Value $LauncherPath `
        -Type String

    Write-Log "Shell kiosk configuré via Policies\System : $LauncherPath"
}
finally {
    # Décharger proprement la ruche
    Write-Log "Déchargement de la ruche utilisateur kiosk."
    reg unload "HKU\$HiveName" | Out-Null
}

Write-Log "Configuration shell kiosk terminée."