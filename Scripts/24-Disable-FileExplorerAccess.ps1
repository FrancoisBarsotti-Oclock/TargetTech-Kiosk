# ============================================================
# 24-Disable-FileExplorerAccess.ps1
# Masque l'accès à l'Explorateur de fichiers pour kiosk
# Sans tuer Explorer.exe
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début masquage Explorateur de fichiers."

# ------------------------------------------------------------
# Détection du vrai profil kiosk
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable." "ERROR"
    throw "Profil kiosk introuvable."
}

$KioskProfilePath = $KioskProfile.LocalPath
$HiveName = "KioskTempHive"
$NtUserDat = Join-Path $KioskProfilePath "NTUSER.DAT"

if (-not (Test-Path $NtUserDat)) {
    Write-Log "NTUSER.DAT kiosk introuvable : $NtUserDat" "ERROR"
    throw "NTUSER.DAT introuvable."
}

Write-Log "Profil kiosk détecté : $KioskProfilePath"

# ------------------------------------------------------------
# 1. Supprimer les raccourcis visibles vers l'Explorateur
# ------------------------------------------------------------

$ExplorerShortcuts = @(
    "$KioskProfilePath\Desktop\File Explorer.lnk",
    "$KioskProfilePath\Desktop\Explorateur de fichiers.lnk",
    "C:\Users\Public\Desktop\File Explorer.lnk",
    "C:\Users\Public\Desktop\Explorateur de fichiers.lnk"
)

foreach ($Shortcut in $ExplorerShortcuts) {
    if (Test-Path $Shortcut) {
        Remove-Item $Shortcut -Force
        Write-Log "Raccourci supprimé : $Shortcut"
    }
}

# ------------------------------------------------------------
# 2. Détacher l'Explorateur de fichiers de la taskbar
# ------------------------------------------------------------
# Windows 11 ne fournit pas de méthode officielle PowerShell
# fiable pour détacher une application épinglée.
# On supprime donc les raccourcis épinglés du profil kiosk.
# Un redémarrage ou une reconnexion peut être nécessaire.

$PinnedTaskbarPath = Join-Path $KioskProfilePath "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

if (Test-Path $PinnedTaskbarPath) {
    Get-ChildItem $PinnedTaskbarPath -Filter "*Explorer*.lnk" -ErrorAction SilentlyContinue |
        Remove-Item -Force

    Get-ChildItem $PinnedTaskbarPath -Filter "*Explorateur*.lnk" -ErrorAction SilentlyContinue |
        Remove-Item -Force

    Write-Log "Raccourcis Explorateur supprimés de la taskbar kiosk."
}
else {
    Write-Log "Dossier taskbar pinned introuvable : $PinnedTaskbarPath" "WARN"
}

# ------------------------------------------------------------
# 3. Charger la ruche utilisateur kiosk
# ------------------------------------------------------------

reg unload "HKU\$HiveName" 2>$null | Out-Null
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {
    $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $DisallowRun = "$ExplorerPolicy\DisallowRun"

    New-Item -Path $ExplorerPolicy -Force | Out-Null
    New-Item -Path $DisallowRun -Force | Out-Null

    # --------------------------------------------------------
    # 4. Bloquer le lancement direct de explorer.exe
    # --------------------------------------------------------
    # Attention :
    # explorer.exe reste déjà chargé comme shell Windows.
    # Cette stratégie empêche surtout l'utilisateur de lancer
    # une nouvelle fenêtre Explorateur depuis l'interface.
    # Elle ne doit pas tuer Explorer.exe.

    Set-ItemProperty -Path $ExplorerPolicy -Name "DisallowRun" -Type DWord -Value 1

    New-ItemProperty `
        -Path $DisallowRun `
        -Name "1" `
        -Value "explorer.exe" `
        -PropertyType String `
        -Force | Out-Null

    Write-Log "Lancement direct de explorer.exe bloqué pour kiosk."

    # --------------------------------------------------------
    # 5. Masquer des entrées Explorer courantes
    # --------------------------------------------------------

    # Masque les lecteurs dans "Ce PC"
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoDrives" -Type DWord -Value 67108863

    # Empêche l'accès aux lecteurs depuis Explorer
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoViewOnDrive" -Type DWord -Value 67108863

    # Supprime l'accès aux options de dossiers
    Set-ItemProperty -Path $ExplorerPolicy -Name "NoFolderOptions" -Type DWord -Value 1

    Write-Log "Restrictions Explorateur appliquées pour kiosk."
}
finally {
    reg unload "HKU\$HiveName" 2>$null | Out-Null
    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Masquage Explorateur de fichiers terminé."