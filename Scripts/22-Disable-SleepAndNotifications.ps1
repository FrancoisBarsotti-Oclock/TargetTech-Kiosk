# ============================================================
# 22-Disable-SleepAndNotifications.ps1
# Désactive veille, extinction écran et notifications parasites
# pour stabiliser le kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation veille et notifications."

# ------------------------------------------------------------
# 1. Désactiver veille / extinction écran
# ------------------------------------------------------------

# Désactive veille sur secteur
powercfg /change standby-timeout-ac 0

# Désactive veille sur batterie
powercfg /change standby-timeout-dc 0

# Désactive extinction écran sur secteur
powercfg /change monitor-timeout-ac 0

# Désactive extinction écran sur batterie
powercfg /change monitor-timeout-dc 0

# Désactive hibernation
powercfg /hibernate off

Write-Log "Veille, extinction écran et hibernation désactivées."

# ------------------------------------------------------------
# 2. Désactiver la localisation Windows
# ------------------------------------------------------------

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" /v Value /t REG_SZ /d Deny /f | Out-Null

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f | Out-Null

Write-Log "Localisation Windows désactivée."

# ------------------------------------------------------------
# 3. Désactiver notifications toast Windows
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable. Notifications kiosk non modifiées." "WARN"
}
else {
    $HiveName = "KioskTempHive"
    $NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"

    reg unload "HKU\$HiveName" 2>$null | Out-Null
    reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

    try {
        reg add "HKU\$HiveName\Software\Microsoft\Windows\CurrentVersion\PushNotifications" `
            /v ToastEnabled `
            /t REG_DWORD `
            /d 0 `
            /f | Out-Null

        Write-Log "Notifications toast désactivées pour kiosk."
    }
    finally {
        reg unload "HKU\$HiveName" 2>$null | Out-Null
        Write-Log "Ruche kiosk déchargée."
    }
}

Write-Log "Désactivation veille et notifications terminée."