# Guide de démarrage rapide ⚡

## En 5 minutes chrono !

### 1. Prérequis
- ✅ macOS 13.0+ (Ventura ou plus récent)
- ✅ Xcode 15+ installé
- ✅ Compte développeur Apple (gratuit suffit)

### 2. Ouvrir dans Xcode

```bash
cd Optimiiz
open -a Xcode
```

Ensuite dans Xcode :
- **File** → **New** → **Project**
- Sélectionnez **macOS** → **App**
- **Product Name** : `ScreenSnap`
- **Interface** : `SwiftUI`
- **Language** : `Swift`

### 3. Importer les fichiers

1. Supprimez les fichiers par défaut créés par Xcode
2. Glissez-déposez le dossier `ScreenSnapApp/ScreenSnapApp` dans le projet
3. Cochez "Copy items if needed"

### 4. Configurer les permissions

Dans le projet Xcode, onglet **Info**, ajoutez :
- `LSUIElement` = `YES` (Boolean)
- `NSAppleEventsUsageDescription` = `Pour les raccourcis clavier` (String)
- `NSScreenCaptureUsageDescription` = `Pour capturer l'écran` (String)

### 5. Lancer ! 🚀

Appuyez sur **⌘R** et c'est parti !

Lors du premier lancement, acceptez les permissions demandées par macOS.

---

## Utilisation immédiate

1. **Icône dans la barre de menu** : Cherchez l'icône 📷 en haut à droite
2. **Première capture** : `⌘⇧5` (raccourci par défaut)
3. **Sélectionnez la zone** à capturer en glissant la souris
4. **Collez dans votre IDE** : `⌘V` dans VSCode, Cursor, Zed, etc.

---

## Problèmes ?

### L'application ne capture pas
→ Vérifiez les permissions dans **Préférences Système** → **Sécurité** → **Enregistrement d'écran**

### Le raccourci ne fonctionne pas
→ Vérifiez les permissions dans **Préférences Système** → **Sécurité** → **Accessibilité**

### Plus de détails
→ Consultez [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md)

---

**Temps total : ~5 minutes** ⏱️

Bon développement ! 🎉
