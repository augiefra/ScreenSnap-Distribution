# Resources

## Assets requis

Pour une meilleure expérience, ajoutez les assets suivants dans Xcode :

### 1. Icône de l'application (App Icon)

Créez un jeu d'icônes pour macOS dans `Assets.xcassets/AppIcon.appiconset` :

Tailles requises :
- 16x16px (1x et 2x)
- 32x32px (1x et 2x)
- 128x128px (1x et 2x)
- 256x256px (1x et 2x)
- 512x512px (1x et 2x)

**Suggestion de design** :
- Icône de caméra stylisée
- Couleurs : Bleu/Violet ou dégradé moderne
- Style minimaliste

### 2. Icône de la barre de menu (Menu Bar Icon)

L'application utilise actuellement une icône SF Symbol (`camera.fill`), mais vous pouvez créer une icône personnalisée :

- Format : PDF ou PNG
- Taille : 22x22px @1x, 44x44px @2x
- Style : Monochrome (template image)
- Nom suggéré : `menubar-icon`

Pour utiliser votre icône personnalisée, modifiez dans `ScreenSnapAppApp.swift` :

```swift
// Remplacez
button.image = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: "ScreenSnap")

// Par
button.image = NSImage(named: "menubar-icon")
button.image?.isTemplate = true
```

### 3. Son de capture (optionnel)

Si vous souhaitez un son personnalisé :

- Format : MP3 ou WAV
- Durée : ~0.5 secondes
- Nom : `camera-shutter.mp3`
- Placez-le dans ce dossier Resources

Par défaut, l'application utilise le son système "Pop".

## Comment ajouter des assets dans Xcode

1. **Ouvrez** `Assets.xcassets` dans Xcode
2. **Clic droit** → "New Image Set" ou "New Sound"
3. **Glissez-déposez** vos fichiers
4. **Assurez-vous** que le target "ScreenSnap" est coché

## Outils recommandés pour créer des icônes

- **SF Symbols** : Icônes système Apple (gratuit)
- **Figma** : Design d'icônes personnalisées
- **IconJar** : Gestion d'icônes
- **ImageOptim** : Optimisation des images

## Structure recommandée

```
Resources/
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   │   ├── icon_16x16.png
│   │   ├── icon_16x16@2x.png
│   │   ├── icon_32x32.png
│   │   ├── icon_32x32@2x.png
│   │   ├── icon_128x128.png
│   │   ├── icon_128x128@2x.png
│   │   ├── icon_256x256.png
│   │   ├── icon_256x256@2x.png
│   │   ├── icon_512x512.png
│   │   └── icon_512x512@2x.png
│   └── menubar-icon.imageset/
│       ├── menubar-icon.pdf
│       └── Contents.json
└── camera-shutter.mp3 (optionnel)
```

## Notes

- Les icônes de la barre de menu doivent être des "template images" (monochromes)
- macOS adaptera automatiquement la couleur selon le thème (clair/sombre)
- Les icônes doivent être exportées en @1x et @2x pour les écrans Retina
