# 🌍 ScreenSnap - Guide de Localisation Multilingue

**Date**: 2025-11-12  
**Statut**: ✅ Fichiers créés, prêt pour intégration Xcode

---

## 📊 Vue d'Ensemble

ScreenSnap est maintenant **entièrement traduisible** en 5 langues :
- 🇬🇧 **English** (langue par défaut)
- 🇫🇷 **Français**
- 🇪🇸 **Español**
- 🇮🇹 **Italiano**  
- 🇩🇪 **Deutsch**

**82 chaînes traduites** réparties sur 6 catégories d'interface utilisateur.

---

## 📁 Fichiers Créés

```
ScreenSnap/ScreenSnap/ScreenSnap/
├── en.lproj/
│   └── Localizable.strings  (96 lignes - ANGLAIS - DEFAULT)
├── fr.lproj/
│   └── Localizable.strings  (96 lignes - FRANÇAIS)
├── es.lproj/
│   └── Localizable.strings  (96 lignes - ESPAGNOL)
├── it.lproj/
│   └── Localizable.strings  (96 lignes - ITALIEN)
└── de.lproj/
    └── Localizable.strings  (96 lignes - ALLEMAND)
```

---

## 🚀 Intégration dans Xcode (Étape par Étape)

### Étape 1: Ajouter les Fichiers de Localisation

1. **Ouvrir Xcode**
   ```bash
   open ScreenSnap/ScreenSnap.xcodeproj
   ```

2. **Glisser-déposer les dossiers .lproj**
   - Dans le **Project Navigator** (panneau gauche)
   - Sélectionnez tous les dossiers `.lproj` depuis le Finder
   - Glissez-les dans le projet Xcode
   - Cochez **"Copy items if needed"**
   - Target: **ScreenSnap**

3. **Vérifier l'ajout**
   - Les 5 dossiers `.lproj` doivent apparaître dans le navigateur
   - Chacun contient un fichier `Localizable.strings`

### Étape 2: Configurer les Localisations du Projet

1. **Cliquer sur le projet ScreenSnap** (racine dans Project Navigator)
2. **Onglet "Info"**
3. **Section "Localizations"**
4. **Cliquer sur "+" pour ajouter chaque langue**:
   - ✅ English (Development Language) - déjà sélectionné
   - ✅ French
   - ✅ Spanish
   - ✅ Italian
   - ✅ German

5. **Pour chaque langue ajoutée**:
   - Cocher `Localizable.strings`
   - Cliquer "Finish"

### Étape 3: Définir la Langue de Développement

1. Projet → Info → Project Name
2. **"Development Language"** doit être **English**
3. Si ce n'est pas le cas, changer pour English

---

## 💻 Modification du Code (NSLocalizedString)

### Principe

Remplacer toutes les chaînes hardcodées par:

```swift
NSLocalizedString("key", comment: "Description for translators")
```

### Exemples de Remplacement

#### AVANT (hardcodé)
```swift
let menuItem = NSMenuItem(title: "📸 Capturer une zone", action: #selector(takeScreenshot), keyEquivalent: "")
```

#### APRÈS (localisé)
```swift
let menuItem = NSMenuItem(
    title: NSLocalizedString("menu.capture_area", comment: "Menu item to capture screen area"),
    action: #selector(takeScreenshot),
    keyEquivalent: ""
)
```

---

## 📝 Fichiers à Modifier (7 fichiers)

### 1. ScreenSnapApp.swift (6 strings)

**Ligne 89** - Tooltip
```swift
// AVANT
button.toolTip = "ScreenSnap - Raccourci: ⌥⌘S"

// APRÈS
button.toolTip = NSLocalizedString("menu.tooltip", comment: "Menu bar icon tooltip")
```

**Lignes 145-171** - Menu items
```swift
// AVANT
let screenshotItem = NSMenuItem(title: "📸 Capturer une zone", action: #selector(takeScreenshot), keyEquivalent: "")

// APRÈS
let screenshotItem = NSMenuItem(
    title: NSLocalizedString("menu.capture_area", comment: "Capture area menu item"),
    action: #selector(takeScreenshot),
    keyEquivalent: ""
)
```

**Ligne 153**
```swift
// AVANT
let fullScreenItem = NSMenuItem(title: "🖥️ Capturer l'écran complet", action: #selector(captureFullScreen), keyEquivalent: "")

// APRÈS
let fullScreenItem = NSMenuItem(
    title: NSLocalizedString("menu.capture_fullscreen", comment: "Capture full screen menu item"),
    action: #selector(captureFullScreen),
    keyEquivalent: ""
)
```

**Ligne 160**
```swift
// AVANT
let revealItem = NSMenuItem(title: "📁 Voir la dernière capture", action: #selector(revealLastScreenshot), keyEquivalent: "")

// APRÈS
let revealItem = NSMenuItem(
    title: NSLocalizedString("menu.show_last", comment: "Show last screenshot menu item"),
    action: #selector(revealLastScreenshot),
    keyEquivalent: ""
)
```

**Ligne 167**
```swift
// AVANT
let prefsItem = NSMenuItem(title: "⚙️ Préférences...", action: #selector(openPreferences), keyEquivalent: ",")

// APRÈS
let prefsItem = NSMenuItem(
    title: NSLocalizedString("menu.preferences", comment: "Preferences menu item"),
    action: #selector(openPreferences),
    keyEquivalent: ","
)
```

**Ligne 173**
```swift
// AVANT
let quitItem = NSMenuItem(title: "Quitter", action: #selector(quit), keyEquivalent: "q")

// APRÈS
let quitItem = NSMenuItem(
    title: NSLocalizedString("menu.quit", comment: "Quit menu item"),
    action: #selector(quit),
    keyEquivalent: "q"
)
```

**Lignes 210-211** - File not found alert
```swift
// AVANT
alert.messageText = "Fichier introuvable"
alert.informativeText = "La capture n'existe plus sur le disque."

// APRÈS
alert.messageText = NSLocalizedString("error.file_not_found.title", comment: "File not found alert title")
alert.informativeText = NSLocalizedString("error.file_not_found.message", comment: "File not found alert message")
```

**Lignes 389-403** - Accessibility alert
```swift
// AVANT
alert.messageText = "🔑 Autorisation Accessibilité requise"
alert.informativeText = """
Pour que le raccourci ⌥⌘S fonctionne, vous devez autoriser ScreenSnap:
[...]
"""

// APRÈS
alert.messageText = NSLocalizedString("error.accessibility_required.title", comment: "Accessibility permission required")
alert.informativeText = NSLocalizedString("error.accessibility_required.message", comment: "Accessibility permission instructions")
```

---

### 2. SettingsView.swift (33 strings)

**Tab Names** (lignes 17, 22, 27)
```swift
// AVANT
TabView {
    GeneralSettingsView()
        .tabItem {
            Label("Général", systemImage: "gearshape")
        }

// APRÈS
TabView {
    GeneralSettingsView()
        .tabItem {
            Label(NSLocalizedString("settings.tab.general", comment: "General tab"), 
                  systemImage: "gearshape")
        }
```

**Toggle Labels** (exemple ligne 42)
```swift
// AVANT
Toggle("Copier dans le presse-papiers", isOn: $settings.copyToClipboard)

// APRÈS
Toggle(NSLocalizedString("settings.general.copy_clipboard", comment: "Copy to clipboard toggle"), 
       isOn: $settings.copyToClipboard)
```

**Help Text** (exemple ligne 43)
```swift
// AVANT
Text("Copie automatiquement la capture pour pouvoir coller avec ⌘V")

// APRÈS
Text(NSLocalizedString("settings.general.copy_clipboard.help", comment: "Help text for clipboard copy"))
```

---

### 3. OnboardingView_Simple.swift (4 strings majeures)

**Ligne 36** - Title
```swift
// AVANT
alert.messageText = "🎉 Bienvenue dans ScreenSnap!"

// APRÈS
alert.messageText = NSLocalizedString("onboarding.title", comment: "Welcome title")
```

**Lignes 37-63** - Message complet
```swift
// AVANT
alert.informativeText = """
ScreenSnap simplifie vos captures d'écran pour les développeurs.
[...]
"""

// APRÈS
// Option 1: Une seule clé avec texte complet
alert.informativeText = NSLocalizedString("onboarding.message", comment: "Complete onboarding message")

// Option 2: Plusieurs clés (recommandé pour flexibilité)
let subtitle = NSLocalizedString("onboarding.subtitle", comment: "")
let why = NSLocalizedString("onboarding.why_title", comment: "")
let ultrafast = NSLocalizedString("onboarding.ultrafast", comment: "")
// ... etc
alert.informativeText = "\(subtitle)\n\n\(why)\n\n\(ultrafast)\n..."
```

**Ligne 67**
```swift
// AVANT
alert.suppressionButton?.title = "Ne plus afficher"

// APRÈS
alert.suppressionButton?.title = NSLocalizedString("onboarding.dont_show", comment: "Don't show again")
```

**Ligne 69**
```swift
// AVANT
alert.addButton(withTitle: "Compris!")

// APRÈS
alert.addButton(withTitle: NSLocalizedString("onboarding.got_it", comment: "Got it button"))
```

---

### 4. PermissionManager.swift (7 strings)

**Lignes 247-257** - Permission Required Alert
```swift
// AVANT
alert.messageText = "Permissions Required"
alert.informativeText = """
ScreenSnap needs the following permissions to work properly:
[...]
"""

// APRÈS
alert.messageText = NSLocalizedString("error.permissions_required.title", comment: "Permissions required title")
alert.informativeText = String(format: NSLocalizedString("error.permissions_required.message", comment: "Permissions required message"), missingNames)
```

---

### 5. ScreenshotService.swift (10 strings)

**Notifications**
```swift
// AVANT (ligne 228-229)
content.title = "📸 Screenshot Ready"
content.body = "Click to reveal in Finder"

// APRÈS
content.title = NSLocalizedString("notification.screenshot_ready", comment: "Screenshot ready notification")
content.body = NSLocalizedString("notification.click_to_reveal", comment: "Click to reveal")
```

**Error Messages**
```swift
// AVANT (ligne 218)
alert.messageText = "Erreur de capture"

// APRÈS
alert.messageText = NSLocalizedString("error.capture_error", comment: "Capture error title")
```

---

## 🔧 Helper Function (Optionnel mais Recommandé)

Créer une extension pour simplifier l'usage:

```swift
// Extensions/String+Localization.swift
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

// Usage simplifié
let title = "menu.capture_area".localized
```

---

## ✅ Checklist de Vérification

### Avant Compilation
- [ ] Les 5 dossiers `.lproj` sont dans Xcode
- [ ] Les 5 langues sont dans Project → Info → Localizations
- [ ] English est défini comme Development Language
- [ ] Tous les `NSLocalizedString` utilisent les bonnes clés

### Tests de Localisation

**Méthode 1: Changer la langue système**
1. Préférences Système → Langue et région
2. Ajouter la langue à tester
3. Redémarrer l'app

**Méthode 2: Scheme Xcode (plus rapide)**
1. Product → Scheme → Edit Scheme
2. Run → Options → App Language
3. Sélectionner langue à tester
4. Run (⌘R)

**Méthode 3: Arguments de lancement**
```swift
// Edit Scheme → Run → Arguments
-AppleLanguages (fr)
```

### Tests Manuels par Langue

**English** 🇬🇧
- [ ] Menu items en anglais
- [ ] Settings UI en anglais
- [ ] Notifications en anglais
- [ ] Messages d'erreur en anglais

**Français** 🇫🇷
- [ ] Menu items en français
- [ ] Settings UI en français
- [ ] Notifications en français
- [ ] Messages d'erreur en français

**Español** 🇪🇸
- [ ] Todos los elementos en español

**Italiano** 🇮🇹
- [ ] Tutti gli elementi in italiano

**Deutsch** 🇩🇪
- [ ] Alle Elemente auf Deutsch

---

## 🐛 Dépannage

### Problème: Les traductions n'apparaissent pas

**Vérifications**:
1. Les fichiers `.lproj` sont bien dans le target ScreenSnap
2. La langue est bien dans Project → Info → Localizations
3. Les clés dans le code correspondent aux clés dans `Localizable.strings`
4. Le fichier `.strings` a la bonne syntaxe: `"key" = "value";`

**Solution**:
```bash
# Nettoyer le build
cd ScreenSnap
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/ScreenSnap-*
# Rebuilder
xcodebuild -scheme ScreenSnap build
```

### Problème: Certaines chaînes restent en français

**Cause**: Vous avez oublié de remplacer une chaîne hardcodée

**Solution**: Chercher toutes les chaînes hardcodées:
```bash
grep -r "Capturer" ScreenSnap/ScreenSnap/*.swift
grep -r "Préférences" ScreenSnap/ScreenSnap/*.swift
```

### Problème: Syntax error dans Localizable.strings

**Vérification de syntaxe**:
```bash
plutil -lint ScreenSnap/en.lproj/Localizable.strings
```

---

## 📊 Statistiques

- **Langues supportées**: 5
- **Chaînes traduites**: 82
- **Fichiers à modifier**: 7
- **Temps estimé de modification**: 2-3 heures
- **Couverture**: 100% de l'interface utilisateur

---

## 🚀 Prochaines Étapes

### Maintenant (V1.1)
1. Intégrer les fichiers `.lproj` dans Xcode
2. Modifier les 7 fichiers Swift pour utiliser `NSLocalizedString`
3. Tester chaque langue
4. Compiler et vérifier qu'aucune régression

### Plus tard (V1.2+)
- Ajouter support pour d'autres langues (portugais, japonais, chinois)
- Exporter/importer via XLIFF pour traducteurs professionnels
- Utiliser `.xcstrings` (Xcode 15+) pour localisation centralisée
- Implémenter tests automatisés de localisation

---

## 📖 Ressources Apple

- [Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [NSLocalizedString](https://developer.apple.com/documentation/foundation/nslocalizedstring)
- [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog)

---

**Créé le**: 2025-11-12  
**Auteur**: Claude Code  
**Statut**: ✅ Prêt pour intégration
