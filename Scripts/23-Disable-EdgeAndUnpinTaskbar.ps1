# ============================================================
# 23-Disable-EdgeAndUnpinTaskbar.ps1
# Masque Microsoft Edge et le détache de la taskbar kiosk
# Sans désinstaller Edge du système
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation/masquage Microsoft Edge."

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

$KioskUser = "kiosk"

# Chemins possibles des raccourcis Edge
$EdgePublicDesktop = "C:\Users\Public\Desktop\Microsoft Edge.lnk"
$EdgeUserDesktop = "C:\Users\$KioskUser\Desktop\Microsoft Edge.lnk"

# Chemin de Microsoft Edge
$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# ------------------------------------------------------------
# 1. Supprimer les raccourcis Edge visibles
# ------------------------------------------------------------

$Shortcuts = @(
    $EdgePublicDesktop,
    $EdgeUserDesktop
)

foreach ($Shortcut in $Shortcuts) {
    if (Test-Path $Shortcut) {
        Remove-Item $Shortcut -Force
        Write-Log "Raccourci Edge supprimé : $Shortcut"
    }
}

# ------------------------------------------------------------
# 2. Détacher Edge de la barre des tâches
# ------------------------------------------------------------
# Windows ne fournit pas de méthode PowerShell officielle fiable
# pour unpin une application de la taskbar sur toutes les versions.
# Cette méthode supprime les raccourcis épinglés du profil kiosk.
# Elle peut nécessiter une reconnexion/reboot.

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -ne $KioskProfile) {
    $PinnedPath = Join-Path $KioskProfile.LocalPath "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

    if (Test-Path $PinnedPath) {
        Get-ChildItem $PinnedPath -Filter "*Edge*.lnk" -ErrorAction SilentlyContinue |
            Remove-Item -Force

        Write-Log "Raccourcis Edge supprimés de la taskbar kiosk."
    }
    else {
        Write-Log "Dossier taskbar pinned introuvable : $PinnedPath" "WARN"
    }
}
else {
    Write-Log "Profil kiosk introuvable pour suppression Edge taskbar." "WARN"
}

# ------------------------------------------------------------
# 3. Bloquer le lancement direct de Microsoft Edge pour kiosk
# ------------------------------------------------------------
# Utilise une stratégie Explorer DisallowRun dans le profil kiosk.
# Cela empêche l'utilisateur de lancer msedge.exe depuis Explorer.

if ($null -ne $KioskProfile) {

    $HiveName = "KioskTempHive"
    $NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"

    if (Test-Path $NtUserDat) {

        reg unload "HKU\$HiveName" 2>$null | Out-Null
        reg load "HKU\$HiveName" "$NtUserDat" | Out-Null

        try {
            $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            $DisallowRun = "$ExplorerPolicy\DisallowRun"

            New-Item -Path $ExplorerPolicy -Force | Out-Null
            New-Item -Path $DisallowRun -Force | Out-Null

            Set-ItemProperty -Path $ExplorerPolicy -Name "DisallowRun" -Type DWord -Value 1

            New-ItemProperty `
                -Path $DisallowRun `
                -Name "1" `
                -Value "msedge.exe" `
                -PropertyType String `
                -Force | Out-Null

            Write-Log "Lancement de msedge.exe bloqué pour kiosk."
        }
        finally {
            reg unload "HKU\$HiveName" 2>$null | Out-Null
            Write-Log "Ruche kiosk déchargée."
        }
    }
}

Write-Log "Désactivation/masquage Microsoft Edge terminée."