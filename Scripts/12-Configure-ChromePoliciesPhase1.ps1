# ============================================================
# 12-Configure-ChromePoliciesPhase1.ps1
# Chrome Hardening - Phase 1
# Durcissement léger sans casser les fonctionnalités TargetTech
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début Chrome Hardening Phase 1."

# ------------------------------------------------------------
# Variables
# ------------------------------------------------------------

$PolicyPath = "C:\Program Files\Google\Chrome\Application\Policies\Managed"
$PolicyFile = "$PolicyPath\targettech-policy.json"

# ------------------------------------------------------------
# Créer dossier policies si nécessaire
# ------------------------------------------------------------

if (-not (Test-Path $PolicyPath)) {

    New-Item `
        -Path $PolicyPath `
        -ItemType Directory `
        -Force | Out-Null

    Write-Log "Dossier policies Chrome créé."
}

# ------------------------------------------------------------
# Contenu policies Chrome
# ------------------------------------------------------------

$PolicyJson = @'
{
    "BrowserSignin": 0,
    "SyncDisabled": true,
    "PasswordManagerEnabled": false,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false,
    "ImportBookmarks": false,
    "ImportHistory": false,
    "ImportSavedPasswords": false,
    "MetricsReportingEnabled": false,
    "SearchSuggestEnabled": false,
    "AlternateErrorPagesEnabled": false,
    "TranslateEnabled": false,
    "BackgroundModeEnabled": false,
    "ComponentUpdatesEnabled": true,
    "DefaultBrowserSettingEnabled": false,
    "DeveloperToolsAvailability": 1,
    "ExtensionInstallBlocklist": ["*"],
    "HideWebStoreIcon": true,
    "IncognitoModeAvailability": 1,
    "BookmarkBarEnabled": false,
    "ShowHomeButton": false,
    "PromotionalTabsEnabled": false
}
'@

# ------------------------------------------------------------
# Écriture fichier JSON
# ------------------------------------------------------------

Set-Content `
    -Path $PolicyFile `
    -Value $PolicyJson `
    -Encoding UTF8

Write-Log "Policies Chrome Phase 1 écrites."

Write-Log "Chrome Hardening Phase 1 terminé."