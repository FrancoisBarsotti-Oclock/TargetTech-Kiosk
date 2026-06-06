# 🏗️ ARCHITECTURE — TargetTech WinKiosk

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

# 🔑 Gestion du mot de passe du compte kiosk

## Pourquoi le compte kiosk possède un mot de passe ?

Le compte `kiosk` est utilisé pour :

* l'ouverture automatique de session (autologon)
* l'exécution des tâches planifiées TargetTech
* le fonctionnement du kiosque après redémarrage

Le mot de passe doit donc être connu du système afin que l'autologon puisse fonctionner correctement.

---

# 📂 Scripts concernés

| Script                       | Rôle                                                |
| ---------------------------- | --------------------------------------------------- |
| `03-Create-KioskUser.ps1`    | Création du compte kiosk                            |
| `04-Configure-Autologon.ps1` | Configuration de l'ouverture automatique de session |

---

# 🔒 Méthode recommandée

Le projet utilise :

```powershell
$KioskPassword = Read-Host "Entrer le mot de passe temporaire du compte kiosk" -AsSecureString
```

plutôt que :

```powershell
$KioskPasswordPlain = "MonMotDePasse123!"
$KioskPassword = ConvertTo-SecureString $KioskPasswordPlain -AsPlainText -Force
```

---

## Pourquoi cette méthode est plus sécurisée ?

### ❌ Solution en texte clair

```powershell
$KioskPasswordPlain = "MonMotDePasse123!"
```

Le mot de passe :

* apparaît dans le script
* apparaît dans GitHub
* apparaît dans les sauvegardes
* apparaît dans les captures d'écran
* peut être récupéré par toute personne ayant accès au dépôt

Cette méthode est déconseillée.

---

### ✅ Solution SecureString

```powershell
$KioskPassword = Read-Host "Entrer le mot de passe temporaire du compte kiosk" -AsSecureString
```

Le mot de passe :

* n'est jamais affiché à l'écran
* n'est pas stocké dans le script
* n'est pas envoyé dans GitHub
* n'apparaît pas dans les logs

Cette méthode est donc préférable pour un environnement de production.

---

# ⚙️ Fonctionnement de Read-Host -AsSecureString

Lorsque le script rencontre :

```powershell
$KioskPassword = Read-Host "Entrer le mot de passe temporaire du compte kiosk" -AsSecureString
```

PowerShell :

1. affiche le message :

```text
Entrer le mot de passe temporaire du compte kiosk :
```

2. attend la saisie du clavier

3. masque les caractères saisis

Exemple :

```text
Entrer le mot de passe temporaire du compte kiosk :
***************
```

4. stocke le résultat sous forme de `SecureString`

Cette variable peut ensuite être utilisée directement par :

```powershell
New-LocalUser
Set-LocalUser
```

sans jamais révéler le mot de passe.

---

# 🔄 Changer le mot de passe du compte kiosk

Si un administrateur souhaite modifier le mot de passe du compte kiosk après le déploiement :

## Étape 1 : ouvrir PowerShell administrateur

```powershell
Run as Administrator
```

---

## Étape 2 : saisir le nouveau mot de passe

```powershell
$NewPassword = Read-Host "Nouveau mot de passe kiosk" -AsSecureString
```

Exemple :

```text
PS C:\Users\Admin>

$NewPassword = Read-Host "Nouveau mot de passe kiosk" -AsSecureString

Nouveau mot de passe kiosk:
***************
```

---

## Étape 3 : appliquer le nouveau mot de passe

```powershell
Set-LocalUser -Name "kiosk" -Password $NewPassword
```

Cette commande met à jour le mot de passe du compte Windows `kiosk`. Cette commande est obligatoire pour changer réellement le mot de passe du compte Windows: Le simple `Read-Host -AsSecureString` ne fait que stocker le mot de passe dans une variable PowerShell ; il ne modifie rien tant qu'il n'est pas passé à `Set-LocalUser` (ou `New-LocalUser` lors de la création du compte).

---

# ⚠️ Étape supplémentaire obligatoire

Après modification du mot de passe Windows du compte kiosk, il faut également mettre à jour l'autologon.

En effet :

* le compte Windows utilise désormais le nouveau mot de passe
* mais Windows possède encore l'ancien mot de passe enregistré pour l'autologon

Si cette étape est oubliée :

```text
Compte kiosk = nouveau mot de passe
Autologon = ancien mot de passe
```

Le démarrage automatique du kiosque échouera.

---

# Mise à jour de l'autologon

Deux solutions sont possibles :

### Solution recommandée

Relancer :

```powershell
04-Configure-Autologon.ps1
```

en saisissant le nouveau mot de passe.

---

### Solution alternative

Modifier directement les valeurs :

```text
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon
```

notamment :

```text
DefaultPassword
```

Cette méthode est réservée aux administrateurs avancés.

---

# Vérification

Après modification :

1. redémarrer la machine
2. vérifier l'ouverture automatique du compte kiosk
3. vérifier le lancement automatique de SwitchLauncher
4. vérifier le fonctionnement normal du kiosque

Si l'autologon fonctionne après redémarrage, la modification du mot de passe a été correctement appliquée.


# 🧪 Validation recommandée

Après toute modification importante du projet, il est recommandé de valider le cycle complet :

```text
WinKiosk
   ↓
Redémarrage
   ↓
Validation kiosk
   ↓
WinRestore
   ↓
Redémarrage
   ↓
Validation Windows
```

---

# 🔒 Checklist de validation après WinKiosk.ps1

Exécuter :

```powershell
C:\TargetTech\Scripts\WinKiosk.ps1
```

Puis redémarrer la machine avec un `Restart-Computer`.

## ✅ Validation du démarrage

* [ ] Ouverture automatique de la session `kiosk`
* [ ] Aucun écran de bienvenue Microsoft
* [ ] Aucun message de configuration Windows
* [ ] Aucun message relatif à la localisation
* [ ] SwitchLauncher démarre automatiquement
* [ ] Le watchdog est actif

---

## ✅ Validation de Chrome

* [ ] Chrome s'ouvre depuis SwitchLauncher
* [ ] `target-tech.fr` est accessible
* [ ] `paypal.com` est accessible
* [ ] `youtube.com` est accessible (si présent dans la whitelist)
* [ ] Les vidéos TargetTech fonctionnent
* [ ] Un site non autorisé est bloqué

Exemple :

* [ ] https://www.lemonde.fr
* [ ] https://www.wikipedia.org
* [ ] https://www.google.com

---

## ✅ Validation des restrictions Chrome

* [ ] Téléchargements bloqués
* [ ] Impression bloquée
* [ ] DevTools (F12) bloqués
* [ ] Code source (Ctrl+U) bloqué
* [ ] Mode Invité désactivé
* [ ] Ajout de profil désactivé
* [ ] Synchronisation Google désactivée

---

## ✅ Validation de l'environnement kiosk

* [ ] Bureau conforme
* [ ] Fond d'écran TargetTech appliqué
* [ ] Barre des tâches masquée automatiquement
* [ ] Icônes attendues visibles
* [ ] Aucune icône parasite

---

## ✅ Validation des raccourcis clavier

* [ ] Win bloqué
* [ ] Win + E bloqué
* [ ] Win + R bloqué
* [ ] Win + D bloqué
* [ ] Win + Tab bloqué
* [ ] Ctrl + Alt + Del accessible

---

## ✅ Validation des outils interdits

* [ ] cmd.exe bloqué
* [ ] powershell.exe bloqué
* [ ] pwsh.exe bloqué
* [ ] regedit.exe bloqué
* [ ] reg.exe bloqué
* [ ] mmc.exe bloqué
* [ ] taskmgr.exe bloqué
* [ ] msconfig.exe bloqué
* [ ] control.exe bloqué
* [ ] services.msc bloqué
* [ ] compmgmt.msc bloqué
* [ ] gpedit.msc bloqué
* [ ] secpol.msc bloqué

---

## ✅ Validation Edge

* [ ] Icône Edge absente de la taskbar
* [ ] Navigation Edge bloquée
* [ ] Edge ne permet pas l'accès Internet

---

## ✅ Validation Copilot

* [ ] Icône Copilot absente
* [ ] Bouton Copilot absent de la taskbar
* [ ] Copilot ne peut pas être lancé

---

## ✅ Validation Explorateur

* [ ] Explorateur absent de la taskbar
* [ ] Explorateur inaccessible via menu Windows
* [ ] Lecteurs non visibles pour kiosk

---

## ✅ Validation Watchdog

Ouvrir PowerShell administrateur :

```powershell
Stop-Process -Name SwitchLauncher -Force
```

Vérifier :

* [ ] SwitchLauncher est relancé automatiquement
* [ ] Aucun message d'erreur
* [ ] watchdog.log est mis à jour

---

## ✅ Validation journaux

Vérifier :

```text
Logs
├── deployment.log
├── deployment.log.local
├── kiosk-shell.log
└── watchdog.log
```

* [ ] Aucun message d'erreur critique
* [ ] Journalisation fonctionnelle

---

# 🔧 Checklist de validation après WinRestore.ps1

Exécuter :

```powershell
C:\TargetTech\Scripts\WinRestore.ps1
```

Puis redémarrer la machine (`Restart-Computer`).

---

## ✅ Validation du retour Windows

* [ ] Session administrateur accessible
* [ ] Autologon kiosk désactivé
* [ ] Écran de connexion Windows normal

---

## ✅ Validation Explorer

* [ ] Explorer.exe lancé normalement
* [ ] Explorateur de fichiers accessible
* [ ] Lecteurs visibles
* [ ] Navigation normale

---

## ✅ Validation Chrome

* [ ] Chrome démarre normalement
* [ ] Tous les sites sont accessibles
* [ ] Téléchargements autorisés
* [ ] Impression autorisée
* [ ] DevTools accessibles

---

## ✅ Validation Edge

* [ ] Edge fonctionne normalement
* [ ] Navigation Internet possible

---

## ✅ Validation outils système

* [ ] cmd.exe accessible
* [ ] powershell.exe accessible
* [ ] pwsh.exe accessible
* [ ] regedit.exe accessible
* [ ] mmc.exe accessible
* [ ] taskmgr.exe accessible
* [ ] control.exe accessible

---

## ✅ Validation clavier

* [ ] Touche Windows fonctionnelle
* [ ] Win + E fonctionnel
* [ ] Win + R fonctionnel
* [ ] Win + D fonctionnel
* [ ] Win + Tab fonctionnel

---

## ✅ Validation alimentation

Vérifier :

```powershell
powercfg /query
```

* [ ] Veille restaurée
* [ ] Extinction écran restaurée
* [ ] Hibernation active (si supportée par le matériel)

---

## ✅ Validation tâches planifiées

Vérifier :

```powershell
Get-ScheduledTask | Where-Object {$_.TaskName -like "TargetTech*"}
```

Résultat attendu :

```text
Aucune tâche TargetTech présente
```

* [ ] TargetTech-Watchdog supprimée
* [ ] TargetTech-KioskLauncher supprimée
* [ ] TargetTech-SwitchLauncher-Elevated supprimée
* [ ] TargetTech-KioskSession supprimée

---

## ✅ Validation finale

Le poste doit être revenu à un comportement Windows standard :

* [ ] Administration normale possible
* [ ] Aucun verrouillage kiosk actif
* [ ] Aucun blocage applicatif actif
* [ ] Aucun lancement automatique de SwitchLauncher
* [ ] Aucun lancement automatique de Chrome

Si toutes les cases sont validées, le cycle de déploiement et de restauration est considéré comme conforme.


---

# ⚠️ Notes importantes

* Ne pas relancer les anciens scripts obsolètes `09`, `12`, `14`, `15`, `16` sauf besoin de test isolé.
* Ne pas supprimer `C:\TargetTech` avec `WinRestore.ps1`.
* Ne pas exécuter `WinKiosk.ps1` depuis la session kiosk.
* Ne pas exécuter `WinRestore.ps1` depuis la session kiosk.
* Les deux scripts maîtres doivent être lancés depuis une session administrateur.

---

#### 💡​ Pour avoir une vision plus général du projet, rendez-vous sur 👉 [README.md de TargetTech-Kiosk](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/blob/master/README.md) 👈​

----
