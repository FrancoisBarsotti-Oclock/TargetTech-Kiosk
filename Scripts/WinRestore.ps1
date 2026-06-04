# ============================================================
# WinRestore.ps1
# Restaure Windows en mode administrable
# ============================================================

Write-Host "Restauration Windows administrable..."

$WinlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$PoliciesPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$ChromePolicyRoot = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# ------------------------------------------------------------
# 1. Restaurer Explorer.exe comme shell Windows
# ------------------------------------------------------------

Set-ItemProperty -Path $WinlogonPath -Name "Shell" -Value "explorer.exe"

# ------------------------------------------------------------
# 2. Désactiver l'autologon kiosk
# ------------------------------------------------------------

Set-ItemProperty -Path $WinlogonPath -Name "AutoAdminLogon" -Value "0" -Type String

Remove-ItemProperty -Path $WinlogonPath -Name "DefaultUserName" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $WinlogonPath -Name "DefaultPassword" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $WinlogonPath -Name "DefaultDomainName" -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 3. Réafficher l'option "Changer d'utilisateur"
# ------------------------------------------------------------

Remove-ItemProperty -Path $PoliciesPath -Name "HideFastUserSwitching" -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 4. Supprimer les tâches planifiées TargetTech
# ------------------------------------------------------------

$Tasks = @(
    "TargetTech-KioskSession",
    "TargetTech-KillExplorer",
    "TargetTech-Watchdog",
    "TargetTech-SwitchLauncher-Elevated",
    "TargetTech-LogAdminLogon",
    "TargetTech-KioskLauncher",
    "TargetTech-CleanLauncher"
)

foreach ($Task in $Tasks) {
    schtasks /Delete /TN $Task /F 2>$null | Out-Null
}

# ------------------------------------------------------------
# 5. Supprimer / nettoyer les policies Chrome TargetTech
# ------------------------------------------------------------

Remove-Item -Path "$ChromePolicyRoot\URLBlocklist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\URLAllowlist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\AudioCaptureAllowedUrls" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\VideoCaptureAllowedUrls" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\RestoreOnStartupURLs" -Recurse -Force -ErrorAction SilentlyContinue

$ChromePolicyNames = @(
    "BrowserSignin",
    "SyncDisabled",
    "PasswordManagerEnabled",
    "AutofillAddressEnabled",
    "AutofillCreditCardEnabled",
    "IncognitoModeAvailability",
    "BookmarkBarEnabled",
    "ShowHomeButton",
    "TranslateEnabled",
    "SearchSuggestEnabled",
    "DeveloperToolsAvailability",
    "HomepageLocation",
    "RestoreOnStartup",
    "DownloadRestrictions",
    "PrintingEnabled",
    "BrowserGuestModeEnabled",
    "BrowserAddPersonEnabled",
    "ProfilePickerOnStartupAvailability"
)

foreach ($PolicyName in $ChromePolicyNames) {
    Remove-ItemProperty -Path $ChromePolicyRoot -Name $PolicyName -ErrorAction SilentlyContinue
}

# ------------------------------------------------------------
# 6. Restaurer les restrictions utilisateur kiosk si profil détecté
# ------------------------------------------------------------

$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Sort-Object LastUseTime -Descending |
    Select-Object -First 1

if ($null -ne $KioskProfile) {

    $HiveName = "KioskTempHive"
    $NtUserDat = Join-Path $KioskProfile.LocalPath "NTUSER.DAT"

    if (Test-Path $NtUserDat) {

        reg unload "HKU\$HiveName" 2>$null | Out-Null
        reg load "HKU\$HiveName" "$NtUserDat" | Out-Null
        
        try {
            $ExplorerPolicy = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
            $SystemPolicy   = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Policies\System"
            $ExplorerAdvanced = "Registry::HKEY_USERS\$HiveName\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

            $ExplorerPolicyNames = @(
                "NoRun",
                "NoWinKeys",
                "NoViewContextMenu",
                "NoTrayContextMenu",
                "NoDesktop",
                "NoControlPanel",
                "DisallowRun",
                "NoDrives",
                "NoViewOnDrive",
                "NoFolderOptions"            
            )

            foreach ($Name in $ExplorerPolicyNames) {
                Remove-ItemProperty -Path $ExplorerPolicy -Name $Name -ErrorAction SilentlyContinue
            }
            
            $SystemPolicyNames = @(
                "DisableTaskMgr",
                "DisableLockWorkstation",
                "DisableChangePassword",
                "Shell"
            )

            foreach ($Name in $SystemPolicyNames) {
                Remove-ItemProperty -Path $SystemPolicy -Name $Name -ErrorAction SilentlyContinue
            }
            # Supprimer la liste applicative interdite, dont msedge.exe
            $DisallowRun = "$ExplorerPolicy\DisallowRun"
            Remove-Item -Path $DisallowRun -Recurse -Force -ErrorAction SilentlyContinue
            
            # Réafficher les icônes du bureau
            Remove-ItemProperty -Path $ExplorerAdvanced -Name "HideIcons" -ErrorAction SilentlyContinue
            
        }
        finally {
            reg unload "HKU\$HiveName" 2>$null | Out-Null
        }
    }
}

# ------------------------------------------------------------
# 7. Arrêter les processus kiosk
# ------------------------------------------------------------

Get-Process SwitchLauncher -ErrorAction SilentlyContinue | Stop-Process -Force

# ------------------------------------------------------------
# 8. Restaurer les touches Windows
# ------------------------------------------------------------

Remove-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout" `
  -Name "Scancode Map" `
  -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 9. Restaurer les paramètres d'alimentation Windows
# ------------------------------------------------------------

powercfg /change standby-timeout-ac 15
powercfg /change standby-timeout-dc 15

powercfg /change monitor-timeout-ac 10
powercfg /change monitor-timeout-dc 5

powercfg /hibernate on

# ------------------------------------------------------------
# 10. Restaurer Edge
# ------------------------------------------------------------

$EdgePolicyRoot = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Remove-Item -Path "$EdgePolicyRoot\URLBlocklist" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 11. Relancer Explorer immédiatement
# ------------------------------------------------------------

Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
Start-Process explorer.exe

Write-Host "Restauration terminée."
Write-Host "Redémarre la machine pour valider le retour complet à Windows."
Pause