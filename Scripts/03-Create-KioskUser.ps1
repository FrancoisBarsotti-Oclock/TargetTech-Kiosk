# ============================================================
# 03-Create-KioskUser.ps1
# Création du compte utilisateur kiosk non-administrateur
# ============================================================

# Chargement des fonctions communes
. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début de la création du compte kiosk."

# Nom du compte kiosk
$KioskUser = "kiosk"

# Mot de passe temporaire fort
# À adapter avant usage réel
$KioskPasswordPlain = "TargetTech-Kiosk-2026!"
$KioskPassword = ConvertTo-SecureString $KioskPasswordPlain -AsPlainText -Force

# Vérification si le compte existe déjà
$ExistingUser = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue

if ($null -eq $ExistingUser) {
    # Création du compte kiosk
    New-LocalUser `
        -Name $KioskUser `
        -Password $KioskPassword `
        -FullName "TargetTech Kiosk User" `
        -Description "Compte kiosk TargetTech" `
        -PasswordNeverExpires `
        -UserMayNotChangePassword

    Write-Log "Compte kiosk créé."
}
else {
    Write-Log "Le compte kiosk existe déjà."
}

# S'assurer que kiosk n'est PAS administrateur
Remove-LocalGroupMember -Group "Administrateurs" -Member $KioskUser -ErrorAction SilentlyContinue
Write-Log "Vérification : kiosk retiré du groupe Administrators si présent."

# Ajouter kiosk au groupe Users
Add-LocalGroupMember -Group "Utilisateurs" -Member $KioskUser -ErrorAction SilentlyContinue
Write-Log "Compte kiosk ajouté/vérifié dans le groupe Users."

# Activer le compte kiosk
Enable-LocalUser -Name $KioskUser
Write-Log "Compte kiosk activé."

# Création d'un dossier profil/app si nécessaire
$KioskDataPath = "C:\TargetTech\KioskData"

if (-not (Test-Path $KioskDataPath)) {
    New-Item -ItemType Directory -Force -Path $KioskDataPath | Out-Null
    Write-Log "Dossier KioskData créé : $KioskDataPath"
}
else {
    Write-Log "Dossier KioskData déjà présent : $KioskDataPath"
}

Write-Log "Création du compte kiosk terminée."