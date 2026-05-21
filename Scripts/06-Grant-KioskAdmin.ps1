# ============================================================
# 06-Grant-KioskAdmin.ps1
# Ajout du compte kiosk au groupe Administrateurs local
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début attribution droits administrateur au compte kiosk."

$KioskUser = "kiosk"
$AdminGroup = "Administrateurs"

# Vérifier que le compte kiosk existe
$User = Get-LocalUser -Name $KioskUser -ErrorAction SilentlyContinue

if ($null -eq $User) {
    Write-Log "Le compte kiosk n'existe pas. Impossible de continuer." "ERROR"
    throw "Compte kiosk introuvable."
}

# Ajouter kiosk au groupe Administrateurs local
try {
    Add-LocalGroupMember -Group $AdminGroup -Member $KioskUser -ErrorAction Stop
    Write-Log "Compte kiosk ajouté au groupe $AdminGroup."
}
catch {
    # Si le compte est déjà membre, on ne bloque pas le script
    Write-Log "Ajout au groupe $AdminGroup non effectué ou déjà présent : $($_.Exception.Message)" "WARN"
}

# Vérification finale
$Members = Get-LocalGroupMember -Group $AdminGroup | Select-Object -ExpandProperty Name

if ($Members -match "\\$KioskUser$|^$KioskUser$") {
    Write-Log "Vérification OK : kiosk est administrateur local."
}
else {
    Write-Log "Vérification échouée : kiosk n'apparaît pas dans Administrateurs." "ERROR"
    throw "kiosk non administrateur après tentative d'ajout."
}

Write-Log "Attribution droits administrateur terminée."