# ============================================================
# 21-Disable-ForbiddenApps.ps1
# Bloque l'exécution d'outils système sensibles
# pour le compte kiosk via DisallowRun
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début blocage applications interdites."

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable." "ERROR"
    throw "Profil kiosk introuvable."
}

$HiveName = "KioskTempHive"
$NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"
$KioskSid = $KioskProfile.SID

# Si le profil kiosk est déjà chargé, utiliser directement son SID
if (Test-Path "Registry::HKEY_USERS\$KioskSid") {
    $HiveRoot = "Registry::HKEY_USERS\$KioskSid"
    $HiveWasLoadedByScript = $false
    Write-Log "Ruche kiosk déjà chargée via SID : $KioskSid"
}
else {
    # Sinon, charger NTUSER.DAT temporairement
    reg unload "HKU\$HiveName" 2>$null | Out-Null
    reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

    $HiveRoot = "Registry::HKEY_USERS\$HiveName"
    $HiveWasLoadedByScript = $true
    Write-Log "Ruche kiosk chargée temporairement : $HiveName"
}

try {
    $ExplorerPolicyReg = "HKU\$KioskSid\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"

    if ($HiveWasLoadedByScript) {
        $ExplorerPolicyReg = "HKU\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    }

    $DisallowRunReg = "$ExplorerPolicyReg\DisallowRun"

    # Créer les clés avec reg.exe
    reg add "$ExplorerPolicyReg" /f | Out-Null
    reg add "$DisallowRunReg" /f | Out-Null

    # Activer DisallowRun
    reg add "$ExplorerPolicyReg" /v DisallowRun /t REG_DWORD /d 1 /f | Out-Null

    $ForbiddenApps = @(
        "cmd.exe",
        "powershell.exe",
        "pwsh.exe",
        "regedit.exe",
        "reg.exe",
        "mmc.exe",
        "msconfig.exe",
        "control.exe",
        "taskmgr.exe",
        "compmgmt.msc",
        "services.msc",
        "gpedit.msc",
        "secpol.msc",
        "msedge.exe",
        "copilot.exe",
        "microsoft.copilot.exe",
        "msedgewebview2.exe"
    )

    # Nettoyer ancienne liste
    reg delete "$DisallowRunReg" /f 2>$null | Out-Null
    reg add "$DisallowRunReg" /f | Out-Null

    $i = 1
    foreach ($App in $ForbiddenApps) {
        reg add "$DisallowRunReg" /v "$i" /t REG_SZ /d "$App" /f | Out-Null
        Write-Log "Application bloquée pour kiosk : $App"
        $i++
    }

    Write-Log "Blocage applications interdites appliqué."
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

Write-Log "Blocage applications interdites terminé."