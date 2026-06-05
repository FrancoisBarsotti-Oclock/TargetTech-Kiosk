# ============================================================
# 25-Disable-CopilotAndUnpinTaskbar.ps1
# Bloque/masque Microsoft Copilot pour kiosk
# Sans tuer Explorer.exe
# Version rapide pour intégration dans WinKiosk.ps1
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation/masquage Copilot."

# ------------------------------------------------------------
# 1. Désactiver Copilot au niveau machine
# ------------------------------------------------------------
# Cette stratégie désactive Windows Copilot pour tous les utilisateurs.
# Note : sur certaines versions récentes, Copilot peut aussi exister
# comme application Appx séparée. Sa suppression Appx doit être faite
# hors WinKiosk pour éviter des blocages longs.

$CopilotPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"

New-Item -Path $CopilotPolicyPath -Force | Out-Null

Set-ItemProperty `
    -Path $CopilotPolicyPath `
    -Name "TurnOffWindowsCopilot" `
    -Type DWord `
    -Value 1

Write-Log "Windows Copilot désactivé au niveau machine."

# ------------------------------------------------------------
# 2. Détection automatique du vrai profil kiosk
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable." "WARN"
    Write-Log "Désactivation Copilot machine appliquée uniquement."
    return
}

$KioskProfilePath = $KioskProfile.LocalPath
$HiveName = "KioskTempHive"
$NtUserDat = Join-Path $KioskProfilePath "NTUSER.DAT"

if (-not (Test-Path $NtUserDat)) {
    Write-Log "NTUSER.DAT kiosk introuvable : $NtUserDat" "WARN"
    Write-Log "Désactivation Copilot machine appliquée uniquement."
    return
}

Write-Log "Profil kiosk détecté : $KioskProfilePath"

# ------------------------------------------------------------
# 3. Supprimer les raccourcis Copilot visibles
# ------------------------------------------------------------

$CopilotShortcuts = @(
    "$KioskProfilePath\Desktop\Copilot.lnk",
    "C:\Users\Public\Desktop\Copilot.lnk"
)

foreach ($Shortcut in $CopilotShortcuts) {
    if (Test-Path $Shortcut) {
        Remove-Item $Shortcut -Force
        Write-Log "Raccourci Copilot supprimé : $Shortcut"
    }
}

# ------------------------------------------------------------
# 4. Supprimer Copilot des raccourcis épinglés taskbar
# ------------------------------------------------------------

$PinnedTaskbarPath = Join-Path $KioskProfilePath "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

if (Test-Path $PinnedTaskbarPath) {
    Get-ChildItem $PinnedTaskbarPath -Filter "*Copilot*.lnk" -ErrorAction SilentlyContinue |
        Remove-Item -Force

    Write-Log "Raccourcis Copilot supprimés de la taskbar kiosk."
}
else {
    Write-Log "Dossier taskbar pinned introuvable : $PinnedTaskbarPath" "WARN"
}

# ------------------------------------------------------------
# 5. Charger ou réutiliser la ruche utilisateur kiosk
# ------------------------------------------------------------

$KioskSid = $KioskProfile.SID

if (Test-Path "Registry::HKEY_USERS\$KioskSid") {
    $HiveRegPath = "HKU\$KioskSid"
    $HiveWasLoadedByScript = $false
    Write-Log "Ruche kiosk déjà chargée via SID : $KioskSid"
}
else {
    reg unload "HKU\$HiveName" 2>$null | Out-Null
    reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

    $HiveRegPath = "HKU\$HiveName"
    $HiveWasLoadedByScript = $true
    Write-Log "Ruche kiosk chargée temporairement : $HiveName"
}

try {
    # --------------------------------------------------------
    # 6. Masquer le bouton Copilot dans la taskbar kiosk
    # --------------------------------------------------------
    # ShowCopilotButton = 0 masque le bouton Copilot.
    # TaskbarDa = 0 peut masquer certains composants modernes
    # de recherche/widgets/copilot selon version Windows 11.

    reg add "$HiveRegPath\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f | Out-Null
    reg add "$HiveRegPath\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f | Out-Null

    Write-Log "Bouton Copilot masqué pour kiosk."

    # --------------------------------------------------------
    # 7. Désactiver Copilot côté utilisateur kiosk
    # --------------------------------------------------------

    reg add "$HiveRegPath\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null

    Write-Log "Copilot désactivé côté profil kiosk."
}
finally {
    if ($HiveWasLoadedByScript) {
        reg unload "HKU\$HiveName" 2>$null | Out-Null
        Write-Log "Ruche kiosk déchargée."
    }
    else {
        Write-Log "Ruche kiosk déjà chargée, pas de déchargement."
    }
}

Write-Log "Désactivation/masquage Copilot terminée."