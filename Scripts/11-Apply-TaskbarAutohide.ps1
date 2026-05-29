# ============================================================
# 11-Apply-TaskbarAutohide.ps1
# Active l'auto-hide de la taskbar pour kiosk
# Méthode native StuckRects3 bytes[]
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration auto-hide taskbar."

$HiveName = "KioskTempHive"

# Détection automatique du vrai profil kiosk
$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable via Win32_UserProfile." "ERROR"
    throw "Profil kiosk introuvable."
}

$KioskUserProfile = $KioskProfile.LocalPath
$NtUserDat = Join-Path $KioskUserProfile "NTUSER.DAT"

Write-Log "Profil kiosk détecté : $KioskUserProfile"

if (-not (Test-Path $NtUserDat)) {
    Write-Log "NTUSER.DAT introuvable : $NtUserDat" "ERROR"
    throw "NTUSER.DAT introuvable."
}

# Décharger une ancienne ruche temporaire si elle existe encore
reg unload HKU\$HiveName 2>$null | Out-Null

# Charger la ruche kiosk
reg load HKU\$HiveName "$NtUserDat" | Out-Null
Write-Log "Ruche kiosk chargée."

try {
    $Path = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

    if (-not (Test-Path $Path)) {
        Write-Log "Clé StuckRects3 introuvable : $Path" "ERROR"
        throw "Clé StuckRects3 introuvable."
    }

    # Lire Settings
    $Settings = (Get-ItemProperty -Path $Path -Name Settings).Settings

    if ($null -eq $Settings -or $Settings.Length -lt 9) {
        Write-Log "Valeur Settings invalide ou trop courte." "ERROR"
        throw "Valeur Settings invalide."
    }

    # Activer auto-hide taskbar
    # Index 8 = flags taskbar ; 0x03 active l'auto-hide
    $Settings[8] = 0x03

    # Écrire nouvelle valeur
    Set-ItemProperty `
        -Path $Path `
        -Name Settings `
        -Value $Settings

    Write-Log "Auto-hide taskbar appliqué."
}
finally {
    reg unload HKU\$HiveName 2>$null | Out-Null
    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Configuration auto-hide taskbar terminée."