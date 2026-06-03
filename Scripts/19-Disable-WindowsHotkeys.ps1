# ============================================================
# 19-Disable-WindowsHotkeys.ps1
# Désactive les raccourcis Windows via blocage des touches Win
# Bloque : Win+E, Win+D, Win+Tab, Win+R, etc.
# Ne bloque PAS : Ctrl+Alt+Del
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début désactivation touches Windows."

$KeyboardLayoutPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
$BackupPath = "C:\TargetTech\Backup\scancode-map-backup.txt"

# Créer la clé si nécessaire
New-Item -Path $KeyboardLayoutPath -Force | Out-Null

# Sauvegarder l'éventuelle valeur existante
try {
    $ExistingMap = Get-ItemPropertyValue `
        -Path $KeyboardLayoutPath `
        -Name "Scancode Map" `
        -ErrorAction Stop

    [Convert]::ToBase64String($ExistingMap) | Set-Content -Path $BackupPath
    Write-Log "Ancienne Scancode Map sauvegardée : $BackupPath"
}
catch {
    Write-Log "Aucune Scancode Map existante à sauvegarder."
}

# Scancode Map :
# - désactive touche Windows gauche  : E0 5B
# - désactive touche Windows droite  : E0 5C
# - ne touche pas à Ctrl, Alt, Suppr
$ScancodeMap = [byte[]](
    0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x00,
    0x03,0x00,0x00,0x00,
    0x00,0x00,0x5B,0xE0,
    0x00,0x00,0x5C,0xE0,
    0x00,0x00,0x00,0x00
)

# Appliquer la nouvelle Scancode Map
New-ItemProperty `
    -Path $KeyboardLayoutPath `
    -Name "Scancode Map" `
    -PropertyType Binary `
    -Value $ScancodeMap `
    -Force | Out-Null

Write-Log "Touches Windows gauche/droite désactivées."

Write-Host "Touches Windows désactivées. Redémarrage nécessaire."