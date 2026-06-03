# ============================================================
# 18-Disable-WindowsWelcomeExperience.ps1
# Désactive les expériences Microsoft post-installation
# pour l'utilisateur courant + le profil kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation Windows Welcome Experience."

# ------------------------------------------------------------
# Fonction commune : applique les clés dans une ruche donnée
# ------------------------------------------------------------

function Disable-WelcomeExperience {
    param(
        [string]$RootPath
    )

    $UserProfileEngagement = "$RootPath\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
    $ContentDeliveryManager = "$RootPath\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

    New-Item -Path $UserProfileEngagement -Force | Out-Null
    New-Item -Path $ContentDeliveryManager -Force | Out-Null

    Set-ItemProperty `
        -Path $UserProfileEngagement `
        -Name "ScoobeSystemSettingEnabled" `
        -Type DWord `
        -Value 0

    Set-ItemProperty `
        -Path $ContentDeliveryManager `
        -Name "SubscribedContent-310093Enabled" `
        -Type DWord `
        -Value 0
}

# ------------------------------------------------------------
# 1. Appliquer à l'utilisateur courant
# ------------------------------------------------------------

Disable-WelcomeExperience -RootPath "HKCU:"
Write-Log "Welcome Experience désactivée pour l'utilisateur courant."

# ------------------------------------------------------------
# 2. Détecter le vrai profil kiosk
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable. Configuration kiosk ignorée." "WARN"
}
else {
    $HiveName = "KioskTempHive"
    $NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"

    if (-not (Test-Path $NtUserDat)) {
        Write-Log "NTUSER.DAT kiosk introuvable : $NtUserDat" "WARN"
    }
    else {
        reg unload "HKU\$HiveName" 2>$null | Out-Null
        reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

        try {
            Disable-WelcomeExperience -RootPath "Registry::HKEY_USERS\$HiveName"
            Write-Log "Welcome Experience désactivée pour le profil kiosk : $($KioskProfile.LocalPath)"
        }
        finally {
            reg unload "HKU\$HiveName" 2>$null | Out-Null
            Write-Log "Ruche kiosk déchargée."
        }
    }
}

Write-Log "Désactivation Windows Welcome Experience terminée."
Write-Host "Windows Welcome Experience désactivée pour l'utilisateur courant et le profil kiosk."
Pause