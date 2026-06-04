# ============================================================
# 25-Disable-CopilotAndUnpinTaskbar.ps1
# Bloque/masque Microsoft Copilot pour kiosk
# Sans tuer Explorer.exe
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation/masquage Copilot."

# ------------------------------------------------------------
# 1. Désactiver Copilot au niveau machine
# ------------------------------------------------------------
# Cette stratégie désactive Windows Copilot pour tous les utilisateurs.

$CopilotPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"

New-Item -Path $CopilotPolicyPath -Force | Out-Null

Set-ItemProperty `
    -Path $CopilotPolicyPath `
    -Name "TurnOffWindowsCopilot" `
    -Type DWord `
    -Value 1

Write-Log "Windows Copilot désactivé au niveau machine."

# ------------------------------------------------------------
# 2. Supprimer l'application Microsoft Copilot Appx
# ------------------------------------------------------------
# Certaines versions récentes de Windows installent Copilot
# comme application Appx séparée : Microsoft.Copilot.
# La policy WindowsCopilot ne suffit pas toujours à la bloquer.

$CopilotPackages = Get-AppxPackage -AllUsers *Copilot* -ErrorAction SilentlyContinue

foreach ($Package in $CopilotPackages) {
    try {
        Write-Log "Suppression Copilot Appx : $($Package.PackageFullName)"

        Remove-AppxPackage `
            -Package $Package.PackageFullName `
            -AllUsers `
            -ErrorAction Stop

        Write-Log "Copilot Appx supprimé : $($Package.PackageFullName)"
    }
    catch {
        Write-Log "Échec suppression Copilot Appx : $($_.Exception.Message)" "WARN"
    }
}

# ------------------------------------------------------------
# 3. Détection automatique du vrai profil kiosk
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
# 4. Supprimer les raccourcis Copilot visibles
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
# 5. Supprimer Copilot des raccourcis épinglés taskbar
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
# 6. Charger la ruche utilisateur kiosk
# ------------------------------------------------------------

reg unload "HKU\$HiveName" 2>$null | Out-Null
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {
    # --------------------------------------------------------
    # 7. Masquer le bouton Copilot dans la taskbar kiosk
    # --------------------------------------------------------
    # ShowCopilotButton = 0 masque le bouton Copilot dans la barre des tâches.

    reg add "HKU\$HiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f | Out-Null

    Write-Log "Bouton Copilot masqué pour kiosk."

    # --------------------------------------------------------
    # 8. Désactiver Copilot côté utilisateur kiosk
    # --------------------------------------------------------

    reg add "HKU\$HiveName\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null

    Write-Log "Copilot désactivé côté profil kiosk."
}
finally {
    reg unload "HKU\$HiveName" 2>$null | Out-Null
    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Désactivation/masquage Copilot terminée."