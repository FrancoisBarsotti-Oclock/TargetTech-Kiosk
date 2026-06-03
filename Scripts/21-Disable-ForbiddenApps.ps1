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

reg unload "HKU\$HiveName" 2>$null | Out-Null
reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

try {
    $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
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
        "explorer.exe",
        "compmgmt.msc",
        "services.msc",
        "gpedit.msc",
        "secpol.msc"
    )

    # Nettoyage ancienne liste
    Get-ItemProperty -Path $DisallowRunPath -ErrorAction SilentlyContinue |
        Select-Object -Property * |
        Out-Null

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
    reg unload "HKU\$HiveName" 2>$null | Out-Null
    Write-Log "Ruche kiosk déchargée."
}

Write-Log "Blocage applications interdites terminé."