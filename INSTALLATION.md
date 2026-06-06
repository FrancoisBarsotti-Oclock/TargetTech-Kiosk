# INSTALLATION

# 🚀 Déploiement de TargetTech-Kiosk

Ce document décrit la procédure complète permettant d'installer et de configurer un poste Windows 11 en mode kiosque TargetTech.

---

# 📋 Prérequis

Système testé :

* Windows 11 x64
* VMware Workstation
* Windows To Go (WTG)

Privilèges requis :

* Compte Administrateur local

---

# 📦 Logiciels requis

Avant de lancer les scripts, vérifier la présence de :

## Google Chrome

Télécharger et installer Google Chrome.

Chemin attendu :

```text
C:\Program Files\Google\Chrome\
```

---

## PowerShell 7

Télécharger et installer PowerShell 7.

Chemin attendu :

```text
C:\Program Files\PowerShell\7\pwsh.exe
```

---

## SwitchLauncher.exe

Copiez le binaire dans :

```text
C:\TargetTech\Apps\
```

Le binaire est distribué séparément du dépôt GitHub.

---

# 📁 Structure attendue

```text
C:\TargetTech
├── Apps
├── Backup
├── Config
├── KioskData
├── Logs
└── Scripts
```

---

# 🔧 Déploiement du kiosque

Ouvrir PowerShell en tant qu'administrateur :

```powershell
cd C:\TargetTech\Scripts
.\WinKiosk.ps1
```

Le script applique automatiquement :

* création du compte kiosk
* configuration de l'autologon
* configuration des tâches planifiées
* durcissement Chrome
* restrictions Windows
* désactivation Edge
* désactivation Copilot
* configuration du watchdog
* configuration du shell kiosque

---

# 🔄 Redémarrage

Après exécution :

```text
Redémarrer obligatoirement la machine
```

---

# ✅ Validation

Après redémarrage :

* connexion automatique sur kiosk
* démarrage automatique de SwitchLauncher
* accès à TargetTech
* blocage des outils système
* Edge inaccessible
* Copilot absent
* watchdog opérationnel

Se référer à la checklist du document ARCHITECTURE.md.

---

# 🧹 Suppression facultative de Copilot

Pour supprimer définitivement Microsoft Copilot de l'image Windows :

```powershell
.\25bis-Remove-CopilotAppx.ps1
```

Cette opération est généralement réalisée une seule fois sur l'image de référence.

---

# 🔙 Retour à un Windows administrable

Depuis une session Administrateur :

```powershell
cd C:\TargetTech\Scripts
.\WinRestore.ps1
```

Le script :

* désactive l'autologon kiosk
* supprime les tâches TargetTech
* restaure Explorer
* restaure Edge
* restaure les restrictions Windows
* restaure les paramètres d'alimentation

Redémarrer ensuite la machine.

---

# 📄 Journaux

Les journaux sont stockés dans :

```text
C:\TargetTech\Logs
```

Principaux fichiers :

```text
admin-logon.log
deployment.log
deployment.log.local
kiosk-shell.log
watchdog.log
```

Ils permettent de diagnostiquer les incidents de déploiement et d'exploitation.

---

# 📚 Documentation associée

* [README.md](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/blob/master/README.md) : présentation générale du projet
* [ARCHITECTURE.md](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/blob/master/ARCHITECTURE.md) : architecture détaillée et description des scripts
* [Release SwitchLauncher.exe](https://github.com/FrancoisBarsotti-Oclock/TargetTech-Kiosk/releases) : documentation du lanceur kiosque

---

