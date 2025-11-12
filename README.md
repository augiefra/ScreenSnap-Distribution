# 📸 ScreenSnap

Application macOS pour captures d'écran rapides avec workflow optimisé pour développeurs.

## ✨ Fonctionnalités

- 📸 **Capture de zone** : Sélection interactive avec aperçu des dimensions
- 🖥️ **Capture plein écran** : Un clic pour tout l'écran
- ⚡ **Ultra-rapide** : ⌥⌘S → Capturer → Cmd+V → Collé !
- 📋 **Copie automatique** : Direct dans le clipboard pour coller dans votre IDE
- 🧹 **Nettoyage auto** : Fichiers vidés au redémarrage du Mac
- 🔔 **Notifications intelligentes** : Clic pour ouvrir dans Finder
- ⚙️ **Personnalisable** : Format, son, raccourcis, stockage

## 🚀 Installation

### Depuis DMG (Recommandé)
1. Télécharger `ScreenSnap-1.0.0.dmg`
2. Monter le DMG
3. Glisser `ScreenSnap.app` vers `Applications`
4. Lancer depuis Applications
5. Autoriser les permissions (Enregistrement d'écran + Accessibilité)

### Depuis Sources
```bash
git clone https://github.com/votre-repo/screensnap
cd screensnap
open ScreenSnap/ScreenSnap.xcodeproj
```

Puis : `Product → Archive → Export`

## 🎯 Utilisation

### Raccourcis Clavier
- **⌥⌘S** : Capturer une zone
- **Clic icône menu bar** : Menu complet

### Menu Bar
- 📸 Capturer une zone
- 🖥️ Capturer l'écran complet
- 📁 Voir la dernière capture
- ⚙️ Préférences
- Quitter

### Workflow
1. Appuyer sur ⌥⌘S
2. Sélectionner la zone
3. Cmd+V dans votre IDE → C'est collé !

## ⚙️ Configuration

- **Format** : PNG (sans perte) ou JPEG (compressé)
- **Stockage** : Dossier temporaire (nettoyé au reboot) ou permanent
- **Options** : Son, dimensions, clipboard automatique

## 🛠️ Développement

### Prérequis
- macOS 12.3+ (Monterey)
- Xcode 14+
- Swift 5.9+

### Structure
```
ScreenSnap/
├── ScreenSnap/
│   ├── ScreenSnapApp.swift     # Point d'entrée
│   ├── Models/                 # AppSettings
│   ├── Views/                  # SwiftUI views
│   ├── Services/               # Screenshot, Permissions
│   └── Utils/                  # Logger
└── README.md
```

### Build
```bash
cd ScreenSnap
xcodebuild -scheme ScreenSnap -configuration Release build
```

### Distribution
Voir `DISTRIBUTION_XCODE.md` pour créer le DMG avec glisser-déposer.

## 📦 Créer le DMG

```bash
# Installer create-dmg
brew install create-dmg

# Créer le DMG
create-dmg \
  --volname "ScreenSnap" \
  --window-size 600 400 \
  --icon-size 100 \
  --app-drop-link 425 190 \
  "ScreenSnap-1.0.0.dmg" \
  "path/to/ScreenSnap.app"
```

Guide complet : `DISTRIBUTION_XCODE.md`

## 🌍 Localisation (V1.1)

Traductions prêtes pour V1.1 :
- 🇬🇧 English
- 🇫🇷 Français
- 🇪🇸 Español
- 🇮🇹 Italiano
- 🇩🇪 Deutsch

Voir `docs/v1.1/` pour intégration.

## 📝 Permissions Requises

- **Enregistrement d'écran** : Pour capturer l'écran
- **Accessibilité** : Pour le raccourci clavier global ⌥⌘S

Configurées automatiquement au premier lancement.

## 🤝 Contribution

Les contributions sont bienvenues !

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amelioration`)
3. Commit (`git commit -m 'Ajout fonctionnalité'`)
4. Push (`git push origin feature/amelioration`)
5. Ouvrir une Pull Request

## 📄 Licence

MIT License - Voir `LICENSE`

## 🔗 Liens

- Documentation : `CLAUDE.md`
- Distribution : `DISTRIBUTION_XCODE.md`
- Localisation V1.1 : `docs/v1.1/`

## ✨ Pourquoi ScreenSnap ?

### vs. Capture macOS Native
❌ Fichiers s'accumulent sur le Bureau  
✅ Nettoyage automatique au redémarrage

### vs. Autres Apps
❌ Interface complexe, pas de nettoyage auto  
✅ Simple, rapide, workflow optimisé développeurs

---

**Version** : 1.0.0  
**Compatibilité** : macOS 12.3+  
**Auteur** : Eric COLOGNI
