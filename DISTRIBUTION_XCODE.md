# 📦 ScreenSnap - Distribution DMG avec Xcode

Guide simple pour créer un DMG professionnel avec fenêtre de glisser-déposer.

---

## 🎯 Résultat Final

Un DMG avec une belle fenêtre montrant :
- ScreenSnap.app à gauche
- Dossier Applications (alias) à droite
- Fond personnalisé (optionnel)
- Instructions visuelles

---

## 📋 Étape 1 : Archive depuis Xcode

### 1.1 Préparer le Build

```bash
# 1. Ouvrir le projet
open ScreenSnap/ScreenSnap.xcodeproj

# 2. Dans Xcode:
#    - Sélectionner "Any Mac" comme destination
#    - Scheme : ScreenSnap
#    - Configuration : Release
```

### 1.2 Créer l'Archive

```
Product → Archive

Xcode va :
1. Compiler en mode Release
2. Créer l'archive
3. Ouvrir la fenêtre Organizer
```

### 1.3 Exporter l'App

Dans l'**Organizer** :

1. **Sélectionner** l'archive la plus récente
2. **Distribute App** → **Custom**
3. **Copy App**
4. **Next** → **Choisir destination** → **Export**

L'app sera exportée dans un dossier (ex: `ScreenSnap 2025-11-12.app`)

---

## 📦 Étape 2 : Créer le DMG avec create-dmg

### 2.1 Installer create-dmg (outil Homebrew)

```bash
# Installer Homebrew si pas déjà fait
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installer create-dmg
brew install create-dmg
```

### 2.2 Préparer les Ressources

```bash
# Créer dossier pour le DMG
mkdir -p dmg-build/source

# Copier l'app exportée
cp -R /path/to/ScreenSnap.app dmg-build/source/

# Créer alias vers Applications
ln -s /Applications dmg-build/source/Applications
```

### 2.3 Créer Image de Fond (Optionnel)

Créer une image PNG (600x400 pixels) avec :
- Instructions "Glisser ScreenSnap vers Applications"
- Flèche visuelle
- Design cohérent avec l'app

```bash
# Si vous avez une image de fond
cp background.png dmg-build/background.png
```

### 2.4 Générer le DMG

```bash
create-dmg \
  --volname "ScreenSnap" \
  --volicon "ScreenSnap/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
  --background "dmg-build/background.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "ScreenSnap.app" 175 190 \
  --hide-extension "ScreenSnap.app" \
  --app-drop-link 425 190 \
  --no-internet-enable \
  "ScreenSnap-1.0.0.dmg" \
  "dmg-build/source/"
```

**Explications des options** :
- `--volname` : Nom du volume monté
- `--volicon` : Icône du DMG
- `--background` : Image de fond
- `--window-pos` : Position de la fenêtre
- `--window-size` : Taille de la fenêtre (largeur x hauteur)
- `--icon-size` : Taille des icônes
- `--icon "ScreenSnap.app" 175 190` : Position de l'app (x y)
- `--app-drop-link 425 190` : Position du dossier Applications

### 2.5 Vérifier le DMG

```bash
# Monter le DMG
open ScreenSnap-1.0.0.dmg

# Vérifier :
# ✅ Fenêtre s'ouvre avec belle disposition
# ✅ ScreenSnap.app à gauche
# ✅ Applications à droite
# ✅ Glisser-déposer fonctionne
# ✅ Image de fond visible (si configurée)
```

---

## 🎨 Méthode Alternative : Sans create-dmg (Manuel)

Si vous préférez créer le DMG manuellement :

### Étape 1 : Créer DMG Temporaire

```bash
# Créer DMG de 200MB (ajuster si nécessaire)
hdiutil create -size 200m -fs HFS+ -volname "ScreenSnap" temp.dmg

# Monter le DMG
hdiutil attach temp.dmg

# Copier l'app
cp -R /path/to/ScreenSnap.app /Volumes/ScreenSnap/

# Créer alias Applications
ln -s /Applications /Volumes/ScreenSnap/Applications
```

### Étape 2 : Personnaliser l'Apparence

```bash
# Ouvrir le volume dans Finder
open /Volumes/ScreenSnap

# Dans Finder :
# 1. View → Show View Options (⌘J)
# 2. Configurer :
#    - Icon size : 100px
#    - Grid spacing : Maximum
#    - Background : Image (copier background.png)
# 3. Positionner les icônes :
#    - ScreenSnap.app à gauche
#    - Applications à droite
# 4. Fermer la fenêtre
```

### Étape 3 : Convertir en DMG Final

```bash
# Démonter
hdiutil detach /Volumes/ScreenSnap

# Convertir en DMG compressé final
hdiutil convert temp.dmg -format UDZO -o ScreenSnap-1.0.0.dmg

# Nettoyer
rm temp.dmg
```

---

## 🖼️ Créer l'Image de Fond (Template)

### Dimensions Recommandées
- **Taille** : 600x400 pixels
- **Format** : PNG avec transparence
- **DPI** : 144 (Retina)

### Éléments à Inclure
```
┌─────────────────────────────────────┐
│                                     │
│  📱              →        📁        │
│ ScreenSnap          Applications   │
│                                     │
│  Glissez ScreenSnap vers           │
│  Applications pour installer        │
│                                     │
└─────────────────────────────────────┘
```

### Créer avec Preview ou Design Tool

```bash
# Créer template simple avec ImageMagick (optionnel)
convert -size 600x400 xc:white \
  -font Arial -pointsize 24 \
  -draw "text 150,250 'Glissez vers Applications →'" \
  dmg-background.png
```

---

## 🔐 Signature et Notarisation (Optionnel - Distribution Publique)

### Prérequis
- Compte Apple Developer ($99/an)
- Developer ID Certificate

### Signer l'App

```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Votre Nom (TEAM_ID)" \
  --options runtime \
  --entitlements ScreenSnap.entitlements \
  ScreenSnap.app
```

### Notariser le DMG

```bash
# 1. Uploader pour notarisation
xcrun notarytool submit ScreenSnap-1.0.0.dmg \
  --apple-id "votre@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# 2. Agrafer le ticket
xcrun stapler staple ScreenSnap-1.0.0.dmg

# 3. Vérifier
spctl -a -vv -t install ScreenSnap-1.0.0.dmg
```

---

## ✅ Checklist Finale

### Avant Distribution
- [ ] App compilée en Release
- [ ] Version correcte dans Info.plist (1.0.0)
- [ ] Icônes présentes et correctes
- [ ] DMG créé avec glisser-déposer
- [ ] Fenêtre DMG bien configurée
- [ ] Test d'installation sur machine propre

### Test Utilisateur
- [ ] Monter le DMG
- [ ] Glisser ScreenSnap vers Applications
- [ ] Lancer depuis Applications
- [ ] Autoriser permissions
- [ ] Tester fonctionnalités principales

---

## 📝 Notes

### Taille du DMG
Le DMG final devrait faire **3-5 MB** compressé.

### Compatibilité
Testé sur macOS 12.3+ (Monterey et supérieur).

### Distribution
- **Privée** : Partager le DMG directement (email, Drive, etc.)
- **Publique** : Signature + Notarisation requises

---

## 🎯 Commandes Rapides (Résumé)

```bash
# 1. Exporter depuis Xcode (Product → Archive → Export)

# 2. Créer DMG avec create-dmg
create-dmg \
  --volname "ScreenSnap" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "ScreenSnap.app" 175 190 \
  --app-drop-link 425 190 \
  "ScreenSnap-1.0.0.dmg" \
  "source-folder/"

# 3. Tester
open ScreenSnap-1.0.0.dmg
```

---

**Date** : 2025-11-12  
**Version** : 1.0  
**Statut** : ✅ Prêt à utiliser
