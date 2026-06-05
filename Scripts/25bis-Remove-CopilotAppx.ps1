# ============================================================
# 25bis-Remove-CopilotAppx.ps1
# Supprime définitivement Microsoft Copilot Appx
# et empêche son reprovisionnement automatique
# À exécuter UNE SEULE FOIS sur l'image de base
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début suppression définitive Copilot Appx."

# ------------------------------------------------------------
# 1. Supprimer les paquets Copilot installés
# ------------------------------------------------------------

$CopilotPackages = Get-AppxPackage -AllUsers |
    Where-Object {
        $_.Name -like "*Copilot*" -or
        $_.PackageFullName -like "*Copilot*"
    }

if ($CopilotPackages.Count -eq 0) {
    Write-Log "Aucun paquet Copilot installé."
}
else {

    foreach ($Package in $CopilotPackages) {

        try {
            Write-Log "Suppression paquet : $($Package.PackageFullName)"

            Remove-AppxPackage `
                -Package $Package.PackageFullName `
                -AllUsers `
                -ErrorAction Stop

            Write-Log "Paquet supprimé."
        }
        catch {
            Write-Log "Échec suppression : $($_.Exception.Message)" "WARN"
        }
    }
}

# ------------------------------------------------------------
# 2. Supprimer les paquets provisionnés
# ------------------------------------------------------------
# Empêche Copilot de revenir pour les futurs comptes.

try {

    $ProvisionedPackages = Get-AppxProvisionedPackage -Online |
        Where-Object {
            $_.DisplayName -like "*Copilot*"
        }

    foreach ($Package in $ProvisionedPackages) {

        Write-Log "Déprovisionnement : $($Package.DisplayName)"

        Remove-AppxProvisionedPackage `
            -Online `
            -PackageName $Package.PackageName `
            -ErrorAction SilentlyContinue | Out-Null

        Write-Log "Paquet déprovisionné."
    }
}
catch {
    Write-Log "Déprovisionnement ignoré : $($_.Exception.Message)" "WARN"
}

# ------------------------------------------------------------
# 3. Désactiver Copilot par stratégie machine
# ------------------------------------------------------------

$CopilotPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"

New-Item -Path $CopilotPolicyPath -Force | Out-Null

Set-ItemProperty `
    -Path $CopilotPolicyPath `
    -Name "TurnOffWindowsCopilot" `
    -Type DWord `
    -Value 1

Write-Log "Policy WindowsCopilot appliquée."

# ------------------------------------------------------------
# 4. Vérification finale
# ------------------------------------------------------------

$RemainingPackages = Get-AppxPackage -AllUsers |
    Where-Object {
        $_.Name -like "*Copilot*" -or
        $_.PackageFullName -like "*Copilot*"
    }

if ($RemainingPackages.Count -eq 0) {
    Write-Log "Aucun paquet Copilot restant."
}
else {
    Write-Log "Des paquets Copilot subsistent." "WARN"
}

Write-Log "Suppression définitive Copilot terminée."

Write-Host ""
Write-Host "Copilot supprimé de l'image."
Write-Host "Redémarrage recommandé."
Pause