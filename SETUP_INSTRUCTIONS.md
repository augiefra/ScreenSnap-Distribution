# Instructions de configuration du projet Xcode

## Création du projet Xcode

Comme Swift Package Manager ne supporte pas complètement les applications macOS avec interface graphique, vous devrez créer un projet Xcode manuellement. Voici les étapes :

### Option 1 : Créer un nouveau projet Xcode (Recommandé)

1. **Ouvrir Xcode**
   ```bash
   open -a Xcode
   ```

2. **Créer un nouveau projet**
   - File → New → Project
   - Sélectionnez "macOS" → "App"
   - Cliquez sur "Next"

3. **Configurer le projet**
   - **Product Name** : `ScreenSnap`
   - **Team** : Sélectionnez votre équipe de développement
   - **Organization Identifier** : `com.votrenomsociete` (ou votre identifiant)
   - **Bundle Identifier** : Sera automatiquement `com.votrenomsociete.ScreenSnap`
   - **Interface** : `SwiftUI`
   - **Language** : `Swift`
   - **Décochez** "Use Core Data"
   - **Décochez** "Include Tests"

4. **Enregistrer le projet**
   - Choisissez le dossier `Optimiiz` comme emplacement
   - **IMPORTANT** : Décochez "Create Git repository" (il existe déjà)

5. **Supprimer les fichiers par défaut**
   - Dans le navigateur de projet (à gauche), supprimez :
     - `ScreenSnapApp.swift` (sera remplacé)
     - `ContentView.swift` (non nécessaire)
     - Le dossier `Assets.xcassets` (optionnel, peut être conservé)

6. **Ajouter les fichiers sources**
   - Faites glisser le dossier `ScreenSnapApp/ScreenSnapApp` dans le projet
   - Assurez-vous de cocher "Copy items if needed"
   - Sélectionnez "Create groups"
   - Target : Cochez "ScreenSnap"

7. **Configurer Info.plist**
   - Dans le navigateur de projet, sélectionnez le projet "ScreenSnap"
   - Onglet "Info"
   - Ajoutez les entrées suivantes dans "Custom macOS Application Target Properties" :
     - `LSUIElement` : `YES` (Boolean) → Pour cacher l'icône du dock
     - `NSAppleEventsUsageDescription` : `Cette app nécessite l'accès aux événements Apple pour les raccourcis clavier.` (String)
     - `NSScreenCaptureUsageDescription` : `Cette app nécessite l'accès à la capture d'écran pour prendre des screenshots.` (String)

8. **Configurer les Entitlements**
   - File → New → File
   - Choisissez "Property List"
   - Nommez-le `ScreenSnap.entitlements`
   - Ajoutez le contenu du fichier `ScreenSnapApp.entitlements` fourni

   Ou copiez le fichier existant :
   - Dans le navigateur, clic droit sur "ScreenSnap"
   - Add Files to "ScreenSnap"
   - Sélectionnez `ScreenSnapApp/ScreenSnapApp.entitlements`

9. **Lier les Entitlements au projet**
   - Sélectionnez le projet "ScreenSnap"
   - Onglet "Signing & Capabilities"
   - Dans "Entitlements File", sélectionnez `ScreenSnap.entitlements`

10. **Configurer le build**
    - Sélectionnez le projet "ScreenSnap"
    - Onglet "Build Settings"
    - Recherchez "Deployment Target"
    - Définissez "macOS Deployment Target" à `13.0` minimum

### Option 2 : Utiliser XcodeGen (Avancé)

Si vous avez `xcodegen` installé :

```bash
# Installer XcodeGen
brew install xcodegen

# Générer le projet Xcode
cd ScreenSnapApp
xcodegen
```

Cela utilisera le fichier `project.yml` fourni.

## Permissions système

Lors du premier lancement, vous devrez accorder des permissions :

### Enregistrement d'écran
1. Préférences Système → Sécurité et confidentialité
2. Confidentialité → Enregistrement d'écran
3. Cochez "ScreenSnap"

### Accessibilité (pour les raccourcis clavier)
1. Préférences Système → Sécurité et confidentialité
2. Confidentialité → Accessibilité
3. Cliquez sur le cadenas pour déverrouiller
4. Ajoutez "ScreenSnap" à la liste

## Build et exécution

### Mode Debug
1. Sélectionnez le schéma "ScreenSnap" dans Xcode
2. Choisissez "My Mac" comme destination
3. Appuyez sur `⌘R` pour compiler et exécuter

### Mode Release
1. Product → Archive
2. Distribute App → Copy App
3. Choisissez un emplacement
4. Copiez l'application vers `/Applications/`

## Signature du code

Pour une distribution en dehors de l'App Store :

1. **Dans Xcode**
   - Signing & Capabilities
   - Sélectionnez votre équipe
   - Signing Certificate : "Apple Development" ou "Developer ID Application"

2. **Notarization** (optionnel, pour distribution publique)
   ```bash
   # Exporter l'application
   xcodebuild archive -scheme ScreenSnap -archivePath ./build/ScreenSnap.xcarchive

   # Créer un package
   xcodebuild -exportArchive -archivePath ./build/ScreenSnap.xcarchive -exportPath ./build -exportOptionsPlist exportOptions.plist

   # Soumettre pour notarization
   xcrun altool --notarize-app --primary-bundle-id "com.votrenomsociete.ScreenSnap" --file ./build/ScreenSnap.app
   ```

## Débogage

### Logs de l'application
```bash
# Voir les logs de l'application
log stream --predicate 'processImagePath contains "ScreenSnap"' --level debug
```

### Debug dans Xcode
- Ajoutez des breakpoints dans le code
- Utilisez `print()` pour logger des informations
- Consultez la console de débogage

## Problèmes courants

### "Developer cannot be verified"
```bash
xattr -cr /Applications/ScreenSnap.app
```

### Permissions non demandées
- Supprimez l'application
- Supprimez les caches : `rm -rf ~/Library/Caches/com.votrenomsociete.ScreenSnap`
- Réinstallez

### Raccourcis clavier ne fonctionnent pas
- Vérifiez les permissions d'accessibilité
- Redémarrez l'application
- Essayez un raccourci différent

## Structure du projet final

```
ScreenSnap/
├── ScreenSnap.xcodeproj/
│   └── project.pbxproj
├── ScreenSnap/
│   ├── ScreenSnapAppApp.swift
│   ├── Models/
│   │   └── AppSettings.swift
│   ├── Services/
│   │   ├── ScreenshotService.swift
│   │   └── HotKeyManager.swift
│   ├── Views/
│   │   └── SettingsView.swift
│   └── Resources/
│       └── Assets.xcassets
├── ScreenSnap.entitlements
└── Info.plist
```

## Prochaines étapes

1. Suivez les instructions ci-dessus pour créer le projet
2. Compilez et testez l'application
3. Configurez vos préférences
4. Profitez de vos captures d'écran rapides !

Pour toute question ou problème, consultez le README.md principal.
