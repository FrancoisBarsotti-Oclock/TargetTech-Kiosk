# ============================================================
# 11-Apply-TaskbarAutohide.ps1
# Active l'auto-hide de la taskbar pour kiosk
# Méthode native StuckRects3 bytes[]
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration auto-hide taskbar."

$HiveName = "KioskTempHive"
$NtUserDat = "C:\Users\kiosk\NTUSER.DAT"

# ------------------------------------------------------------
# Charger la ruche kiosk
# ------------------------------------------------------------

reg unload HKU\$HiveName 2>$null | Out-Null
reg load HKU\$HiveName $NtUserDat | Out-Null

try {

    $Path = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3"

    # Lire Settings
    $Settings = (Get-ItemProperty -Path $Path -Name Settings).Settings

    # --------------------------------------------------------
    # Activer auto-hide taskbar
    # --------------------------------------------------------

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