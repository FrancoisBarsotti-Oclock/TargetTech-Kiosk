# ============================================================
# 16-Configure-ChromeWhitelistRegistry.ps1
# Chrome Hardening - Phase 2
# Whitelist URL via registre Windows
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début Chrome Whitelist Registry Phase 2."

$ChromePolicyRoot = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# Créer la racine policies Chrome
New-Item -Path $ChromePolicyRoot -Force | Out-Null

# Nettoyer anciennes listes si elles existent
Remove-Item -Path "$ChromePolicyRoot\URLBlocklist" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\URLAllowlist" -Recurse -Force -ErrorAction SilentlyContinue

# Policies simples
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
Set-ItemProperty -Path $ChromePolicyRoot -Name "DeveloperToolsAvailability" -Type DWord -Value 1

# Startup / homepage
Remove-ItemProperty -Path $ChromePolicyRoot -Name "HomepageLocation" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $ChromePolicyRoot -Name "RestoreOnStartup" -ErrorAction SilentlyContinue
Remove-Item -Path "$ChromePolicyRoot\RestoreOnStartupURLs" -Recurse -Force -ErrorAction SilentlyContinue

# URL blocklist : bloque tout
New-Item -Path "$ChromePolicyRoot\URLBlocklist" -Force | Out-Null
New-ItemProperty -Path "$ChromePolicyRoot\URLBlocklist" -Name "1" -Value "*" -PropertyType String -Force | Out-Null

# URL allowlist : autorise TargetTech + PayPal
New-Item -Path "$ChromePolicyRoot\URLAllowlist" -Force | Out-Null
$AllowUrls = @(
    "target-tech.fr",
    "peerjs.target-tech.fr",
    "peersjs.target-tech.fr",
    "matomo.science-edu.fr",
    "upload.wikimedia.org",
    "paypal.com",
    "youtube.com",
    "youtube-nocookie.com",
    "ytimg.com",
    "googlevideo.com",
    "chrome://policy",
    "chrome://gpu",
    "chrome://webrtc-internals"
)

$i = 1
foreach ($Url in $AllowUrls) {
    New-ItemProperty -Path "$ChromePolicyRoot\URLAllowlist" -Name "$i" -Value $Url -PropertyType String -Force | Out-Null
    $i++
}

Write-Log "Policies Chrome écrites dans le registre."
Write-Log "Chrome Whitelist Registry Phase 2 terminée."