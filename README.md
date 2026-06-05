```text
Windows 11
│
├── WinKiosk.ps1
│      ↓
│   Configuration Kiosk
│
├── SwitchLauncher.exe
│      ↓
│   Interface utilisateur
│
├── Google Chrome
│      ↓
│   TargetTech + PayPal + YouTube
│
└── WinRestore.ps1
       ↓
   Retour Windows standard
```

---
# 🖥️ TargetTech WinKiosk

## 📖 Présentation

**TargetTech WinKiosk** est une solution de verrouillage et de durcissement de Windows 11 permettant de transformer un poste classique en borne sécurisée, de type **borne interactive (kiosk)**, dédiée à l'activité de TargetTech.

L'objectif est de fournir un environnement simple pour l'utilisateur final tout en limitant drastiquement les possibilités de sortie du périmètre applicatif autorisé.

Le projet repose sur :

* 🪟 Windows 11
* 🌐 Google Chrome
* 🚀 SwitchLauncher
* ⚙️ Scripts PowerShell d'automatisation
* 🔄 Un mécanisme complet de restauration administrateur

Tout cela pour atteindre ces deux principes:

* 🔒 Sécurisation automatique via `WinKiosk.ps1`
* 🔧 Retour à un poste administrable via `WinRestore.ps1`

L'ensemble des modifications est entièrement scripté et journalisé.

## 🏗️ Architecture générale

Le schéma ci-dessous résume le fonctionnement global de TargetTech WinKiosk, depuis le déploiement administrateur jusqu’à la restauration maintenance.

🏗️ ARCHITECTURE TARGETTECH WINKIOSK
```
┌──────────────────────────────────────────────┐
│              👤 Administrateur               │
│        Session Windows avec droits admin     │
└───────────────────────┬──────────────────────┘
                        │
                        │ Lance
                        ▼
┌──────────────────────────────────────────────┐
│              🔒 WinKiosk.ps1                 │
│ Script maître de déploiement du kiosque      │
└───────────────────────┬──────────────────────┘
                        │
                        │ Configure
                        ▼
┌──────────────────────────────────────────────┐
│              🧱 Windows 11 durci             │
│ - autologon kiosk                             │
│ - bureau sans icônes                          │
│ - taskbar masquée                             │
│ - touches Windows désactivées                 │
│ - paramètres système bloqués                  │
│ - outils sensibles interdits                  │
└───────────────────────┬──────────────────────┘
                        │
                        │ Au redémarrage
                        ▼
┌──────────────────────────────────────────────┐
│              👤 Compte kiosk                 │
│ Session utilisateur verrouillée               │
└───────────────────────┬──────────────────────┘
                        │
                        │ Lance automatiquement
                        ▼
┌──────────────────────────────────────────────┐
│          🚀 TargetTech-KioskLauncher         │
│ Tâche planifiée de lancement                  │
└───────────────────────┬──────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────┐
│              🎯 SwitchLauncher.exe           │
│ Interface applicative principale du kiosque   │
│ - accès TargetTech                            │
│ - gestion écran / réseau / mise à jour        │
│ - ouverture contrôlée de Chrome               │
└───────────────────────┬──────────────────────┘
                        │
                        │ Ouvre
                        ▼
┌──────────────────────────────────────────────┐
│              🌐 Google Chrome durci          │
│ - whitelist TargetTech / PayPal / YouTube     │
│ - téléchargements bloqués                     │
│ - impression bloquée                          │
│ - DevTools bloqués                            │
│ - profils et invité désactivés                │
└──────────────────────────────────────────────┘


🛡️ SURVEILLANCE

┌──────────────────────────────────────────────┐
│              🛡️ TargetTech-Watchdog          │
│ Tâche planifiée de surveillance               │
└───────────────────────┬──────────────────────┘
                        │
                        │ Vérifie en boucle
                        ▼
┌──────────────────────────────────────────────┐
│              🎯 SwitchLauncher.exe           │
└───────────────────────┬──────────────────────┘
                        │
                        │ Si absent
                        ▼
┌──────────────────────────────────────────────┐
│       Relance TargetTech-KioskLauncher       │
└──────────────────────────────────────────────┘


🔧 RESTAURATION

┌──────────────────────────────────────────────┐
│              👤 Administrateur               │
└───────────────────────┬──────────────────────┘
                        │
                        │ Lance
                        ▼
┌──────────────────────────────────────────────┐
│              🔧 WinRestore.ps1               │
│ Script maître de retour maintenance           │
└───────────────────────┬──────────────────────┘
                        │
                        │ Restaure
                        ▼
┌──────────────────────────────────────────────┐
│              🖥️ Windows administrable        │
│ - autologon désactivé                         │
│ - Explorer restauré                           │
│ - Chrome libre                                │
│ - tâches TargetTech supprimées                │
│ - raccourcis Windows restaurés                │
│ - accès admin normal                          │
└──────────────────────────────────────────────┘
```

### Pour bien plus de détails, rendez-vous sur 👉​ [Architecture - TargetTech WinKiosk](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/blob/master/ARCHITECTURE.md) 👈​

---

# 📂 Arborescence du projet

```text
C:\TargetTech
│
├── Apps
├── Backup
├── Config
├── KioskData
├── Logs
├── Scripts
└── .gitignore
```

---

# 📦 Dossier Apps

Contient les applications utilisées par le kiosque.

```text
Apps
└── SwitchLauncher.exe
```

### Rôle

* 🚀 Lanceur principal du kiosque
* 🎛️ Interface utilisateur
* 🌐 Ouvre Google Chrome
* 🔒 Point d'entrée unique de l'utilisateur

L'utilisateur kiosk ne doit jamais accéder directement à Windows.

---

# 💾 Dossier Backup

Contient les sauvegardes nécessaires à la restauration du système.

Exemples :

* Sauvegarde du Shell Windows
* Sauvegarde de certaines clés registre
* Sauvegarde de configurations avant modification

Ce dossier sauvegarde des paramètres Windows modifiés; il est utilisé par `WinRestore` lorsque cela est nécessaire et facilite le retour à l'état administrable.

---

# ⚙️ Dossier Config

Contient les fichiers de configuration utilisés par l'application ou les scripts.

Exemples :

* paramètres SwitchLauncher
* listes de sites autorisés
* paramètres spécifiques au kiosque

```text
Config 
├── launcher-config.json 
├── kiosk-settings.json 
└── ...
```

Il s'agit donc des paramètres de fonctionnement, configuration de SwitchLauncher et paramètres de navigation.

---

# 👤 Dossier KioskData

Contient les données spécifiques à l'utilisateur kiosk.

Exemples :

* préférences utilisateur
* fichiers temporaires du kiosque
* données locales (non critiques) nécessaires au fonctionnement de SwitchLauncher

```text
KioskData 
├── Cache 
├── Temp 
└── UserData
```

---

# 📝 Dossier Logs

Centralise l'ensemble des journaux d'exécution.

Exemples :

```text
Logs
├── admin-logon.log
├── deployment.log
├── deployment.log.local
├── kiosk-shell.log
└── watchdog.log
```

## 🔐 admin-logon.log

Journalise chaque connexion à un compte administrateur.

Objectif :

* 🔎 Détecter les interventions d'administration
* 🚀 Faciliter les audits
* 📜 Permettre le suivi des accès privilégiés

Exemple du contenu :
```text
[2026-06-05 14:21:08]
Utilisateur : Franbarso
Machine : TARGET-TECH
Connexion administrateur détectée
```

## 🚀 deployment.log

Journal principal de déploiement, contenant :

* exécution des scripts
* succès
* avertissements
* erreurs

Exemple :

[INFO] Exécution du script : 17-Configure-ChromeHardeningFull.ps1
[INFO] Chrome Hardening complet appliqué.

## 🖥️ kiosk-shell.log

Journal du démarrage du kiosque.

Contient notamment :

* lancement du shell
* démarrage de SwitchLauncher
* erreurs éventuelles de session

## 🛡️ watchdog.log

Journal du système de surveillance.

Exemple :

Watchdog démarré.

SwitchLauncher absent.

Relance via tâche TargetTech-KioskLauncher.

Permet de vérifier :

* le bon fonctionnement du watchdog
* les relances automatiques de SwitchLauncher

---

# 🧠 Dossier Scripts

Contient l'ensemble des scripts PowerShell.

Les scripts sont volontairement découpés en petites tâches indépendantes afin de faciliter :

* la maintenance
* les tests
* le débogage
* l'évolution du projet

---

# 🚀 WinKiosk.ps1

## Script maître de mise en mode kiosque

C'est le point d'entrée principal du projet.

Il exécute automatiquement l'ensemble des scripts nécessaires pour transformer Windows en borne sécurisée.

### Actions réalisées

* 👤 Création du compte kiosk
* 🔑 Configuration de l'autologon
* 🚀 Configuration de SwitchLauncher
* 👀 Mise en place du Watchdog
* 🌐 Configuration de Chrome
* 🔒 Application des restrictions Windows
* 🧹 Suppression des accès inutiles
* 🤖 Désactivation de Copilot
* 💤 Désactivation veille et notifications

### Résultat

Après redémarrage :

```text
Boot Windows
      ↓
Connexion automatique kiosk
      ↓
SwitchLauncher
      ↓
Chrome
      ↓
Sites autorisés uniquement
```

---

# 🔄 WinRestore.ps1

## Script maître de restauration

C'est le mécanisme inverse de WinKiosk.

Il permet de remettre la machine dans un état administrable.

### Actions réalisées

* 🔓 Réactivation du shell Windows
* 👤 Désactivation de l'autologon kiosk
* 🗑️ Suppression des tâches planifiées TargetTech
* 🌐 Suppression des policies Chrome
* 🔑 Réactivation des raccourcis Windows
* 💤 Réactivation des paramètres d'alimentation
* 📂 Réouverture de l'environnement Windows standard
* 🧹 Suppression des restrictions utilisateur kiosk

### Résultat

Après redémarrage :

```text
Boot Windows
      ↓
Session administrateur
      ↓
Windows classique
```

---

# 🤖 25bis-Remove-CopilotAppx.ps1

## Suppression définitive de Copilot

Ce script est particulier.

Contrairement aux autres scripts, il n'est pas destiné à être exécuté à chaque déploiement.

### Exécution

Une seule fois :

```powershell
C:\TargetTech\Scripts\25bis-Remove-CopilotAppx.ps1
```

### Rôle

* 🗑️ Suppression de Microsoft Copilot
* 🚫 Suppression du reprovisionnement automatique
* 🔒 Application des politiques de désactivation

### Pourquoi séparé ?

Les opérations Appx peuvent être longues et ralentir fortement WinKiosk.

Ce script est donc utilisé uniquement sur l'image de référence.

---

# 👀 Watchdog

Le Watchdog surveille en permanence SwitchLauncher.

Si l'application est fermée ou plante :

```text
Watchdog
     ↓
Détection
     ↓
Relance automatique
     ↓
Retour utilisateur
```

L'utilisateur ne doit jamais pouvoir sortir du kiosque.

---

# 🌐 Google Chrome

Chrome est le navigateur unique du système.

### Restrictions appliquées

* ❌ Impression
* ❌ Téléchargement
* ❌ Outils développeur
* ❌ Gestion des profils
* ❌ Synchronisation Google
* ❌ Navigation hors périmètre

### Sites autorisés

* 🌍 target-tech.fr
* 💳 paypal.com
* ▶️ youtube.com

Les autres sites sont bloqués par politique Chrome.

---

# 🔒 Philosophie de sécurité

Le projet applique plusieurs couches de protection :

### Niveau Windows

* blocage des raccourcis système
* désactivation paramètres
* restrictions Explorer
* blocage des applications sensibles

### Niveau Chrome

* whitelist d'URL
* durcissement navigateur
* désactivation des fonctionnalités non nécessaires

### Niveau Application

* SwitchLauncher
* Watchdog
* contrôle du parcours utilisateur

Cette approche de défense en profondeur permet de limiter fortement les possibilités de contournement.

---

# 🛠️ Maintenance

Pour modifier le comportement du kiosque :

1. Modifier le script concerné
2. Tester sur VM
3. Valider sur Windows To Go
4. Commit Git
5. Déployer

Pour revenir à un Windows administrable :

```powershell
C:\TargetTech\Scripts\WinRestore.ps1
```

Pour réactiver le kiosque :

```powershell
C:\TargetTech\Scripts\WinKiosk.ps1
```

---

# 👨‍💻 Auteur

Projet développé dans le cadre de la sécurisation d'un environnement Windows 11 dédié à l'activité de TargetTech.

Objectif : fournir une borne web sécurisée, administrable et facilement restaurable.

---

#### 💡​ Pour avoir plus d'information détaillée sur les scripts (et autres), rendez-vous sur 👉​ [Architecture - TargetTech WinKiosk](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/blob/master/ARCHITECTURE.md) 👈​

---