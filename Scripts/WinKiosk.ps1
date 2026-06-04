# ============================================================
# WinKiosk.ps1
# Script maître de déploiement TargetTech WinKiosk
# ============================================================

# ------------------------------------------------------------
# 0. Vérifier que le script est lancé en administrateur
# ------------------------------------------------------------

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Erreur : lance WinKiosk.ps1 en administrateur." -ForegroundColor Red
    Pause
    exit 1
}

# ------------------------------------------------------------
# 1. Charger les fonctions communes
# ------------------------------------------------------------

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "================ DÉBUT DÉPLOIEMENT WINKIOSK ================"

# ------------------------------------------------------------
# 2. Vérifier les prérequis essentiels
# ------------------------------------------------------------

$RequiredFiles = @(
    "C:\TargetTech\Apps\SwitchLauncher.exe",
    "C:\TargetTech\Config\Fond_écran_TT.png",
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files\PowerShell\7\pwsh.exe"
)

foreach ($File in $RequiredFiles) {
    if (-not (Test-Path $File)) {
        Write-Log "Prérequis manquant : $File" "ERROR"
        throw "Prérequis manquant : $File"
    }

    Write-Log "Prérequis OK : $File"
}

# ------------------------------------------------------------
# 3. Liste ordonnée des scripts validés
# ------------------------------------------------------------
# Scripts volontairement exclus :
# - 05-Configure-LauncherStartup.ps1 : remplacé par tâche élevée
# - 09-Configure-KioskShell.ps1 : ancienne stratégie shell abandonnée
# - 12-Configure-ChromePoliciesPhase1.ps1 : remplacé par script 17
# - 14 / 15 admin logon : abandonnés pour éviter menu Windows parasite
# - 16-Configure-ChromeWhitelistRegistry.ps1 : intégré dans script 17
# ------------------------------------------------------------

$Scripts = @(
    "01-Prepare-TargetTech.ps1",
    "02-Install-SwitchLauncher.ps1",
    "03-Create-KioskUser.ps1",
    "06-Grant-KioskAdmin.ps1",
    "04-Configure-Autologon.ps1",
    "07-Configure-ElevatedLauncherTask.ps1",    
    "10-Configure-ExplorerAliveKiosk.ps1",
    "08-Configure-WatchdogTask.ps1",
    "11-Apply-TaskbarAutohide.ps1",
    "13-Configure-KioskWallpaper.ps1",
    "17-Configure-ChromeHardeningFull.ps1",
    "18-Disable-WindowsWelcomeExperience.ps1",
    "19-Disable-WindowsHotkeys.ps1",
    "20-Disable-WindowsSettings.ps1",
    "21-Disable-ForbiddenApps.ps1",
    "22-Disable-SleepAndNotifications.ps1",
    "23-Disable-EdgeAndUnpinTaskbar.ps1",
    "24-Disable-FileExplorerAccess.ps1",
    "25-Disable-CopilotAndUnpinTaskbar.ps1"
)

# ------------------------------------------------------------
# 4. Exécuter les scripts un par un
# ------------------------------------------------------------

foreach ($Script in $Scripts) {
    $ScriptPath = "C:\TargetTech\Scripts\$Script"

    if (-not (Test-Path $ScriptPath)) {
        Write-Log "Script introuvable : $ScriptPath" "ERROR"
        throw "Script manquant : $Script"
    }

    Write-Log "Exécution du script : $Script"

    try {
        & $ScriptPath
        Write-Log "Script terminé avec succès : $Script"
    }
    catch {
        Write-Log "Erreur pendant $Script : $($_.Exception.Message)" "ERROR"
        throw
    }
}

# ------------------------------------------------------------
# 5. Fin du déploiement
# ------------------------------------------------------------

Write-Log "================ DÉPLOIEMENT WINKIOSK TERMINÉ ================"
Write-Host ""
Write-Host "Déploiement WinKiosk terminé avec succès."
Write-Host "Redémarre la machine pour appliquer toutes les restrictions."
Write-Host ""

Pause