# ============================================================
# 20-Disable-WindowsSettings.ps1
# Bloque Paramètres Windows et Panneau de configuration
# pour le compte kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début blocage Paramètres Windows."

# ------------------------------------------------------------
# Recherche du profil kiosk
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object {
        $_.LocalPath -like "C:\Users\kiosk*" -and
        $_.Special -eq $false
    } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable." "ERROR"
    throw "Profil kiosk introuvable."
}

$HiveName = "KioskTempHive"
$NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"

reg unload "HKU\$HiveName" 2>$null | Out-Null
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {

    $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    New-Item -Path $ExplorerPolicy -Force | Out-Null

    # --------------------------------------------------------
    # Bloquer Panneau de configuration
    # --------------------------------------------------------

    Set-ItemProperty `
        -Path $ExplorerPolicy `
        -Name "NoControlPanel" `
        -Type DWord `
        -Value 1

    Write-Log "Panneau de configuration bloqué."

}
finally {

    reg unload "HKU\$HiveName" 2>$null | Out-Null

    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Blocage Paramètres Windows terminé."