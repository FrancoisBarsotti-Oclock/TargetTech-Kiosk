# ============================================================
# 13-Configure-KioskWallpaper.ps1
# Configure le fond d'écran personnalisé du compte kiosk
# ============================================================

. "C:\TargetTech\Scripts\Common.ps1"

Write-Log "Début configuration fond d'écran kiosk."

# Chemin de l'image personnalisée
$WallpaperPath = "C:\TargetTech\Config\Fond_écran_TT.png"

# Détection automatique du vrai profil du compte kiosk
$KioskProfile = Get-CimInstance Win32_UserProfile |
    Where-Object { $_.LocalPath -like "C:\Users\kiosk*" -and $_.Special -eq $false } |
    Select-Object -First 1

if ($null -eq $KioskProfile) {
    Write-Log "Profil kiosk introuvable via Win32_UserProfile." "ERROR"
    throw "Profil kiosk introuvable."
}

$KioskUserProfile = $KioskProfile.LocalPath

# Chemin du fichier registre utilisateur kiosk
$KioskHivePath = Join-Path $KioskUserProfile "NTUSER.DAT"

Write-Log "Profil kiosk détecté : $KioskUserProfile"

# Nom temporaire utilisé pour monter le registre utilisateur kiosk
$TempHiveName = "KioskTempHive"

# Vérifie que l'image existe
if (-not (Test-Path $WallpaperPath)) {
    Write-Log "Fond d'écran introuvable : $WallpaperPath" "ERROR"
    throw "Fond d'écran introuvable."
}

# Vérifie que le profil kiosk existe
if (-not (Test-Path $KioskHivePath)) {
    Write-Log "Profil kiosk introuvable : $KioskHivePath" "ERROR"
    throw "Profil kiosk introuvable."
}

# Charge temporairement le registre utilisateur kiosk
reg load "HKU\$TempHiveName" "$KioskHivePath" | Out-Null
Write-Log "Hive utilisateur kiosk chargé."

# Configure le fond d'écran du compte kiosk
reg add "HKU\$TempHiveName\Control Panel\Desktop" /v Wallpaper /t REG_SZ /d "$WallpaperPath" /f | Out-Null

# WallpaperStyle = 10 : mode Remplir
reg add "HKU\$TempHiveName\Control Panel\Desktop" /v WallpaperStyle /t REG_SZ /d "10" /f | Out-Null

# TileWallpaper = 0 : pas de mosaïque
reg add "HKU\$TempHiveName\Control Panel\Desktop" /v TileWallpaper /t REG_SZ /d "0" /f | Out-Null

Write-Log "Fond d'écran configuré pour le compte kiosk."

# Décharge proprement le registre utilisateur kiosk
reg query HKU\KioskTempHive > $null 2>&1
if ($LASTEXITCODE -eq 0) {
    reg unload HKU\KioskTempHive | Out-Null
}
Write-Log "Hive utilisateur kiosk déchargé."

Write-Log "Configuration fond d'écran kiosk terminée."