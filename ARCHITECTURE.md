# 🏗️ ARCHITECTURE.md — TargetTech WinKiosk

Ce document décrit le rôle des scripts du projet **TargetTech WinKiosk**, leurs dépendances principales, les modifications système appliquées et leur équivalent de restauration dans `WinRestore.ps1`.

---

# 🎯 Objectif général

Le projet transforme un poste **Windows 11 standard** en environnement **kiosk sécurisé** destiné à lancer l’interface TargetTech via `SwitchLauncher.exe`.

La logique principale repose sur deux scripts maîtres :

| Script           | Rôle                              |
| ---------------- | --------------------------------- |
| `WinKiosk.ps1`   | Déploie le mode kiosk             |
| `WinRestore.ps1` | Restaure un Windows administrable |

---

# 🔁 Cycle de fonctionnement

```text
Admin
 └─ WinKiosk.ps1
      └─ Redémarrage
           └─ Session kiosk verrouillée
                └─ SwitchLauncher.exe
                     └─ Chrome durci

Admin
 └─ WinRestore.ps1
      └─ Redémarrage
           └─ Windows administrable
```

---

# 📋 Tableau détaillé des scripts

| Script                                     | Rôle                                                   | Dépendances                                       | Modifications principales                                                                                                             | Restauration dans `WinRestore.ps1`                                       |
| ------------------------------------------ | ------------------------------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| `01-Prepare-TargetTech.ps1`                | Crée l’arborescence `C:\TargetTech`                    | Aucune                                            | Création des dossiers `Apps`, `Backup`, `Config`, `Logs`, `Scripts`, etc.                                                             | Non supprimé volontairement                                              |
| `02-Install-SwitchLauncher.ps1`            | Installe/vérifie `SwitchLauncher.exe`                  | `C:\TargetTech\Apps`                              | Copie ou validation de l’exécutable                                                                                                   | Processus arrêté par `Get-Process SwitchLauncher`                        |
| `03-Create-KioskUser.ps1`                  | Crée le compte local `kiosk`                           | Droits admin                                      | Création utilisateur Windows                                                                                                          | Non supprimé par restauration                                            |
| `04-Configure-Autologon.ps1`               | Active l’autologon kiosk                               | Compte `kiosk` existant                           | `HKLM\...\Winlogon` : `AutoAdminLogon`, `DefaultUserName`, `DefaultPassword`, `DefaultDomainName` ; `HideFastUserSwitching`           | Suppression des valeurs autologon + restauration `HideFastUserSwitching` |
| `05-Configure-LauncherStartup.ps1`         | Ancienne méthode par dossier Startup                   | Obsolète                                          | Raccourci Startup utilisateur                                                                                                         | Non utilisé dans l’architecture finale                                   |
| `06-Grant-KioskAdmin.ps1`                  | Ajoute `kiosk` aux administrateurs locaux              | Compte `kiosk`                                    | Groupe local Administrateurs                                                                                                          | Non restauré automatiquement                                             |
| `07-Configure-ElevatedLauncherTask.ps1`    | Ancienne tâche élevée SwitchLauncher                   | SwitchLauncher présent                            | Tâche `TargetTech-SwitchLauncher-Elevated`                                                                                            | Supprimée par `WinRestore.ps1`                                           |
| `08-Configure-WatchdogTask.ps1`            | Crée la tâche watchdog                                 | `Run-Watchdog.vbs`, `Watchdog-SwitchLauncher.ps1` | Tâche planifiée `TargetTech-Watchdog`                                                                                                 | Supprimée par `WinRestore.ps1`                                           |
| `09-Configure-KioskShell.ps1`              | Ancienne stratégie de remplacement shell               | Obsolète                                          | Tentatives de remplacement shell                                                                                                      | Non utilisé dans l’architecture finale                                   |
| `10-Configure-ExplorerAliveKiosk.ps1`      | Garde Explorer vivant mais verrouillé                  | Compte `kiosk`, profil initialisé                 | Policies utilisateur kiosk : `NoRun`, `NoWinKeys`, `NoViewContextMenu`, `NoTrayContextMenu`, `NoControlPanel`, `DisableTaskMgr`, etc. | Suppression des policies dans la ruche kiosk                             |
| `11-Apply-TaskbarAutohide.ps1`             | Masque automatiquement la taskbar                      | Profil kiosk                                      | `HKCU\...\Explorer\StuckRects3` via ruche kiosk                                                                                       | Non restauré explicitement, mais environnement admin restauré            |
| `12-Configure-ChromePoliciesPhase1.ps1`    | Ancienne phase Chrome légère                           | Obsolète                                          | Policies Chrome partielles                                                                                                            | Remplacé par script 17                                                   |
| `13-Configure-KioskWallpaper.ps1`          | Configure le fond d’écran kiosk                        | `Fond_écran_TT.png`                               | `HKCU\Control Panel\Desktop` du profil kiosk                                                                                          | Non restauré explicitement                                               |
| `14-Log-AdminLogon.ps1`                    | Journalise les connexions admin                        | Ancienne stratégie                                | `admin-logon.log`                                                                                                                     | Non utilisé en tâche active finale                                       |
| `15-Configure-AdminLogonTask.ps1`          | Ancienne tâche de log admin                            | Obsolète                                          | Tâche `TargetTech-LogAdminLogon`                                                                                                      | Supprimée par `WinRestore.ps1` si présente                               |
| `16-Configure-ChromeWhitelistRegistry.ps1` | Ancienne whitelist Chrome seule                        | Obsolète                                          | `HKLM\SOFTWARE\Policies\Google\Chrome`                                                                                                | Remplacé par script 17                                                   |
| `17-Configure-ChromeHardeningFull.ps1`     | Durcissement complet Chrome                            | Chrome installé                                   | Whitelist, blocklist, désactivation téléchargements, impression, DevTools, profils, invité                                            | Suppression des policies Chrome                                          |
| `18-Disable-WindowsWelcomeExperience.ps1`  | Désactive les écrans Microsoft post-installation       | Profil kiosk                                      | `UserProfileEngagement`, `ContentDeliveryManager`                                                                                     | Non restauré, choix volontaire                                           |
| `19-Disable-WindowsHotkeys.ps1`            | Désactive les touches Windows                          | Droits admin                                      | `HKLM\SYSTEM\...\Keyboard Layout\Scancode Map`                                                                                        | Suppression de `Scancode Map`                                            |
| `20-Disable-WindowsSettings.ps1`           | Bloque Paramètres / Panneau de configuration           | Profil kiosk                                      | `NoControlPanel`                                                                                                                      | Suppression de `NoControlPanel`                                          |
| `21-Disable-ForbiddenApps.ps1`             | Bloque les outils système sensibles                    | Profil kiosk                                      | `DisallowRun` : `cmd.exe`, `pwsh.exe`, `regedit.exe`, `explorer.exe`, `msedge.exe`, etc.                                              | Suppression de `DisallowRun` et de sa sous-clé                           |
| `22-Disable-SleepAndNotifications.ps1`     | Désactive veille, écran, notifications et localisation | Droits admin                                      | `powercfg`, `ToastEnabled`, policies localisation                                                                                     | Restauration partielle via `powercfg`                                    |
| `23-Disable-EdgeAndUnpinTaskbar.ps1`       | Masque et neutralise Edge                              | Edge installé                                     | Suppression raccourcis Edge + `HKLM\SOFTWARE\Policies\Microsoft\Edge\URLBlocklist`                                                    | Suppression de `URLBlocklist` Edge                                       |
| `24-Disable-FileExplorerAccess.ps1`        | Restreint l’accès à l’Explorateur                      | Profil kiosk                                      | `NoDrives`, `NoViewOnDrive`, `NoFolderOptions`                                                                                        | Suppression de ces policies                                              |
| `25-Disable-CopilotAndUnpinTaskbar.ps1`    | Masque/désactive Copilot rapidement                    | Profil kiosk                                      | `TurnOffWindowsCopilot`, `ShowCopilotButton`, `TaskbarDa`                                                                             | Pas de restauration Copilot volontaire                                   |
| `25bis-Remove-CopilotAppx.ps1`             | Supprime Copilot Appx définitivement                   | Image de base                                     | `Remove-AppxPackage`, `Remove-AppxProvisionedPackage`                                                                                 | Non restauré volontairement                                              |

---

# 🔑 Clés de registre importantes

## Autologon

```text
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
```

Utilisé pour :

* `AutoAdminLogon`
* `DefaultUserName`
* `DefaultPassword`
* `DefaultDomainName`

Restauré par `WinRestore.ps1`.

---

## Restrictions kiosk utilisateur

```text
HKU\<SID_KIOSK>\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer
HKU\<SID_KIOSK>\Software\Microsoft\Windows\CurrentVersion\Policies\System
```

Utilisé pour :

* bloquer Win+R
* bloquer les menus contextuels
* bloquer le panneau de configuration
* bloquer le gestionnaire des tâches
* bloquer les applications interdites

Restauré par `WinRestore.ps1`.

---

## Chrome Enterprise Policies

```text
HKLM\SOFTWARE\Policies\Google\Chrome
```

Utilisé pour :

* whitelist URL
* blocklist globale
* blocage téléchargements
* blocage impression
* blocage DevTools
* désactivation profils et invité

Restauré par `WinRestore.ps1`.

---

## Edge Policies

```text
HKLM\SOFTWARE\Policies\Microsoft\Edge
```

Utilisé pour bloquer la navigation Edge.

Restauré par `WinRestore.ps1`.

---

## Touches Windows

```text
HKLM\SYSTEM\CurrentControlSet\Control\Keyboard Layout
```

Valeur :

```text
Scancode Map
```

Utilisée pour désactiver les touches Windows gauche/droite.

Restaurée par `WinRestore.ps1`.

---

# 🧠 Scripts critiques

## 🔒 `WinKiosk.ps1`

Script maître de déploiement.

Il doit être exécuté depuis une session administrateur.

Il applique les scripts validés dans l’ordre suivant :

```text
01 → 02 → 03 → 06 → 04 → 07 → 10 → 08 → 11 → 13
→ 17 → 18 → 19 → 20 → 21 → 22 → 23 → 24 → 25
```

Important :

* `08` doit être exécuté après `10`, car `10` nettoie les anciennes tâches TargetTech.
* `17` remplace les anciens scripts Chrome `12` et `16`.
* `25bis` n’est pas exécuté par WinKiosk.

---

## 🔧 `WinRestore.ps1`

Script maître de restauration.

Il doit être exécuté depuis une session administrateur.

Il restaure :

* autologon désactivé
* shell Explorer restauré
* tâches TargetTech supprimées
* policies Chrome supprimées
* policies Edge supprimées
* restrictions kiosk supprimées
* touches Windows restaurées
* paramètres d’alimentation restaurés

Il ne réinstalle pas Copilot.

---

## 🧹 `25bis-Remove-CopilotAppx.ps1`

Script exceptionnel à lancer une seule fois sur l’image de base.

Il sert à supprimer Copilot Appx définitivement.

Il n’est pas appelé automatiquement par `WinKiosk.ps1`.

---

# 🧪 Validation recommandée

Après `WinKiosk.ps1` :

* autologon kiosk
* SwitchLauncher automatique
* Chrome whitelist OK
* Edge bloqué
* Copilot absent
* Explorer inaccessible
* outils système bloqués
* watchdog fonctionnel

Après `WinRestore.ps1` :

* Windows administrable
* autologon supprimé
* Chrome libre
* Explorer libre
* Edge libre
* touches Windows fonctionnelles
* tâches TargetTech supprimées

---

# ⚠️ Notes importantes

* Ne pas relancer les anciens scripts obsolètes `09`, `12`, `14`, `15`, `16` sauf besoin de test isolé.
* Ne pas supprimer `C:\TargetTech` avec `WinRestore.ps1`.
* Ne pas exécuter `WinKiosk.ps1` depuis la session kiosk.
* Ne pas exécuter `WinRestore.ps1` depuis la session kiosk.
* Les deux scripts maîtres doivent être lancés depuis une session administrateur.

---
