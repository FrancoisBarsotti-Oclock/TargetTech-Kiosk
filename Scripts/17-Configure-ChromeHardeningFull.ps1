# ============================================================
# 17-Configure-ChromeHardeningFull.ps1
# Chrome Hardening complet : whitelist + sécurité navigateur
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début Chrome Hardening complet."

$ChromePolicyRoot = "HKLM:\SOFTWARE\Policies\Google\Chrome"

New-Item -Path $ChromePolicyRoot -Force | Out-Null

# Nettoyage des anciennes listes
Remove-Item -Path "$ChromePolicyRoot\URLBlocklist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\URLAllowlist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\AudioCaptureAllowedUrls" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\VideoCaptureAllowedUrls" -Recurse -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# Restrictions générales Chrome
# ------------------------------------------------------------

Set-ItemProperty -Path $ChromePolicyRoot -Name "BrowserSignin" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "SyncDisabled" -Type DWord -Value 1
Set-ItemProperty -Path $ChromePolicyRoot -Name "PasswordManagerEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "AutofillAddressEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "AutofillCreditCardEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "IncognitoModeAvailability" -Type DWord -Value 1
Set-ItemProperty -Path $ChromePolicyRoot -Name "BookmarkBarEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "ShowHomeButton" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "TranslateEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "SearchSuggestEnabled" -Type DWord -Value 0

# ------------------------------------------------------------
# Hardening Phase 3
# ------------------------------------------------------------

Set-ItemProperty -Path $ChromePolicyRoot -Name "DownloadRestrictions" -Type DWord -Value 3
Set-ItemProperty -Path $ChromePolicyRoot -Name "PrintingEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "DeveloperToolsAvailability" -Type DWord -Value 2
Set-ItemProperty -Path $ChromePolicyRoot -Name "BrowserGuestModeEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "BrowserAddPersonEnabled" -Type DWord -Value 0
Set-ItemProperty -Path $ChromePolicyRoot -Name "ProfilePickerOnStartupAvailability" -Type DWord -Value 2

# ------------------------------------------------------------
# Whitelist : bloquer tout sauf sites autorisés
# ------------------------------------------------------------

New-Item -Path "$ChromePolicyRoot\URLBlocklist" -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\URLBlocklist" -Name "1" -Value "*" -PropertyType String -Force | Out-Null

New-Item -Path "$ChromePolicyRoot\URLAllowlist" -Force | Out-Null

$AllowUrls = @(
    "target-tech.fr",
    "peerjs.target-tech.fr",
    "matomo.science-edu.fr",
    "upload.wikimedia.org",
    "paypal.com",
    "chrome://policy",
    "chrome://gpu",
    "chrome://webrtc-internals"
)

$i = 1
foreach ($Url in $AllowUrls) {
    New-ItemProperty -Path "$ChromePolicyRoot\URLAllowlist" -Name "$i" -Value $Url -PropertyType String -Force | Out-Null
    $i++
}

# ------------------------------------------------------------
# Permissions micro / caméra pour TargetTech
# ------------------------------------------------------------

New-Item -Path "$ChromePolicyRoot\AudioCaptureAllowedUrls" -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\AudioCaptureAllowedUrls" -Name "1" -Value "target-tech.fr" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\AudioCaptureAllowedUrls" -Name "2" -Value "peerjs.target-tech.fr" -PropertyType String -Force | Out-Null

New-Item -Path "$ChromePolicyRoot\VideoCaptureAllowedUrls" -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\VideoCaptureAllowedUrls" -Name "1" -Value "target-tech.fr" -PropertyType String -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\VideoCaptureAllowedUrls" -Name "2" -Value "peerjs.target-tech.fr" -PropertyType String -Force | Out-Null

Write-Log "Chrome Hardening complet appliqué."