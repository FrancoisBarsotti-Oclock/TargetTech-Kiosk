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
    $ExplorerPolicy = "$HiveRoot\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $DisallowRunPath = "$ExplorerPolicy\DisallowRun"

    New-Item -Path $ExplorerPolicy -Force | Out-Null
    New-Item -Path $DisallowRunPath -Force | Out-Null

    # Active la politique DisallowRun
    Set-ItemProperty `
        -Path $ExplorerPolicy `
        -Name "DisallowRun" `
        -Type DWord `
        -Value 1

    # Liste des exécutables à bloquer pour kiosk
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

    # Nettoyage ancienne liste
    Remove-Item -Path $DisallowRunPath -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $DisallowRunPath -Force | Out-Null

    $i = 1
    foreach ($App in $ForbiddenApps) {
        New-ItemProperty `
            -Path $DisallowRunPath `
            -Name "$i" `
            -Value $App `
            -PropertyType String `
            -Force | Out-Null

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