# ScreenSnap 📸

Application Mac native pour prendre des captures d'écran rapides et les coller directement dans vos IDEs préférés (VSCode, Cursor, Zed, etc.).

## ✨ Fonctionnalités

- **Raccourci clavier personnalisable** : Définissez votre propre raccourci (par défaut : `⌘⇧5`)
- **Sélection de zone interactive** : Sélectionnez la zone à capturer comme avec `⌘⇧4`
- **Copie automatique dans le presse-papiers** : Collez directement avec `⌘V` dans n'importe quel IDE
- **Sauvegarde optionnelle** : Enregistrez vos captures dans un dossier de votre choix
- **Dossier temporaire** : Option de vider automatiquement le dossier au redémarrage
- **Son de capture** : Feedback audio lors de la prise de capture
- **Interface élégante** : Application menu bar discrète et intuitive
- **Formats multiples** : PNG ou JPEG au choix

## 🚀 Installation

### Prérequis

- macOS 13.0 (Ventura) ou supérieur
- Xcode 15+ avec Swift 5.9+

### Compilation

1. **Cloner le repository** :
   ```bash
   git clone <votre-repo>
   cd Optimiiz
   ```

2. **Ouvrir le projet dans Xcode** :
   ```bash
   open ScreenSnapApp/Package.swift
   ```

   Ou créez un projet Xcode en important les fichiers du dossier `ScreenSnapApp/`.

3. **Configurer le projet** :
   - Sélectionnez votre équipe de développement dans les paramètres de signature
   - Vérifiez que le Bundle Identifier est unique (ex: `com.votrenom.screensnap`)

4. **Compiler et exécuter** :
   - Appuyez sur `⌘R` pour compiler et lancer l'application
   - L'icône de caméra apparaîtra dans la barre de menu

### Installation de l'application

Pour installer l'application de manière permanente :

1. **Créer une archive** :
   - Product → Archive dans Xcode
   - Distribuez l'application localement

2. **Copier vers Applications** :
   ```bash
   cp -r ~/Library/Developer/Xcode/DerivedData/.../ScreenSnapApp.app /Applications/
   ```

3. **Ajouter au démarrage automatique** (optionnel) :
   - Préférences Système → Utilisateurs et groupes → Éléments de connexion
   - Ajoutez ScreenSnap

## 🎯 Utilisation

### Prendre une capture

1. **Avec le raccourci clavier** :
   - Appuyez sur votre raccourci personnalisé (par défaut `⌘⇧5`)
   - Sélectionnez la zone à capturer en cliquant et glissant
   - La capture est automatiquement copiée dans le presse-papiers

2. **Depuis la barre de menu** :
   - Cliquez sur l'icône 📷 dans la barre de menu
   - Sélectionnez "Prendre une capture"

### Coller dans votre IDE

Une fois la capture effectuée, ouvrez votre IDE préféré :

- **VSCode** : `⌘V` dans un fichier Markdown ou dans le chat
- **Cursor** : `⌘V` dans l'éditeur ou le chat
- **Zed** : `⌘V` dans l'éditeur
- **Tout autre éditeur** : `⌘V` fonctionne partout !

### Configurer l'application

Cliquez sur l'icône dans la barre de menu, puis "Préférences" :

#### Onglet Général
- ✅ **Copier dans le presse-papiers** : Active/désactive la copie automatique
- ✅ **Enregistrer sur le disque** : Active/désactive la sauvegarde
- ✅ **Jouer un son** : Active/désactive le son de capture
- **Format d'image** : PNG ou JPEG

#### Onglet Raccourci
- Cliquez sur "Modifier le raccourci"
- Appuyez sur votre combinaison de touches souhaitée
- Exemple : `⌘⌥S`, `⌃⇧C`, etc.

#### Onglet Stockage
- **Dossier de sauvegarde** : Choisissez où enregistrer vos captures
- ✅ **Vider au redémarrage** : Supprime automatiquement les captures au redémarrage
- **Ouvrir le dossier** : Accès rapide à vos captures
- **Vider maintenant** : Supprime toutes les captures actuelles

## 🔧 Architecture technique

### Structure du projet

```
ScreenSnapApp/
├── ScreenSnapApp/
│   ├── ScreenSnapAppApp.swift          # Point d'entrée de l'application
│   ├── Models/
│   │   └── AppSettings.swift           # Gestion des préférences
│   ├── Services/
│   │   ├── ScreenshotService.swift     # Service de capture d'écran
│   │   └── HotKeyManager.swift         # Gestion des raccourcis clavier
│   └── Views/
│       └── SettingsView.swift          # Interface utilisateur
├── Info.plist                           # Configuration de l'application
├── Package.swift                        # Configuration Swift Package
└── ScreenSnapApp.entitlements          # Permissions système
```

### Fonctionnalités clés

#### Capture d'écran
- Utilise `CGDisplayCreateImage` pour capturer des régions spécifiques
- Fenêtre de sélection semi-transparente avec prévisualisation en temps réel
- Affichage des dimensions pendant la sélection

#### Presse-papiers
- Utilise `NSPasteboard` pour une compatibilité maximale
- Copie l'image au format natif pour tous les IDEs
- Support des formats PNG et JPEG

#### Raccourcis clavier
- Utilise Carbon API pour l'enregistrement global des raccourcis
- Support de tous les modificateurs (`⌘`, `⌥`, `⌃`, `⇧`)
- Réenregistrement automatique lors du changement de raccourci

#### Stockage
- Dossier temporaire par défaut (`/tmp/ScreenSnap/`)
- Nommage automatique avec timestamp
- Nettoyage au démarrage si activé

## 🔐 Permissions requises

L'application nécessite les permissions suivantes :

- **Enregistrement d'écran** : Pour capturer les screenshots
- **Accessibilité** (optionnel) : Pour les raccourcis clavier globaux

Lors du premier lancement, macOS demandera ces permissions. Acceptez-les dans :
- Préférences Système → Sécurité et confidentialité → Confidentialité

## 🐛 Dépannage

### L'icône n'apparaît pas dans la barre de menu
- Vérifiez que l'application est bien lancée
- Redémarrez l'application

### Le raccourci clavier ne fonctionne pas
- Vérifiez que les permissions d'accessibilité sont accordées
- Assurez-vous qu'aucune autre application n'utilise le même raccourci
- Essayez un raccourci différent

### La capture ne se colle pas dans mon IDE
- Vérifiez que l'option "Copier dans le presse-papiers" est activée
- Certains IDEs peuvent nécessiter un format spécifique
- Essayez de coller dans un autre éditeur pour vérifier

### Le dossier temporaire n'est pas vidé au redémarrage
- Vérifiez que l'option "Vider au redémarrage" est activée
- L'application doit être lancée au démarrage pour effectuer le nettoyage

## 🎨 Personnalisation

### Changer le dossier de sauvegarde
Par défaut, les captures sont sauvegardées dans `/tmp/ScreenSnap/`. Pour changer :
1. Ouvrez les Préférences
2. Onglet "Stockage"
3. Cliquez sur "Changer..."
4. Sélectionnez votre dossier préféré

### Utiliser un dossier qui se vide automatiquement
Pour un dossier temporaire qui se vide au redémarrage :
- Utilisez un sous-dossier de `/tmp/` ou `/var/tmp/`
- Activez "Vider au redémarrage" dans les préférences

## 📝 TODO / Améliorations futures

- [ ] Support de la capture vidéo
- [ ] Annotations sur les captures
- [ ] Upload automatique vers le cloud
- [ ] Historique des captures
- [ ] Support des captures multi-écrans
- [ ] Export en GIF animé
- [ ] Raccourcis clavier pour différentes actions

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## 👨‍💻 Développement

### Structure du code

L'application suit une architecture MVVM :
- **Models** : `AppSettings` pour la gestion des préférences
- **Views** : SwiftUI pour l'interface
- **Services** : Services métier pour la capture et les raccourcis

### Tests

Pour tester localement :
```bash
# Compiler
swift build

# Ouvrir dans Xcode pour déboguer
open ScreenSnapApp/Package.swift
```

## 💡 Conseils d'utilisation

- **Pour les développeurs** : Parfait pour partager des captures de code ou d'erreurs
- **Pour les designers** : Idéal pour capturer rapidement des inspirations
- **Pour les formateurs** : Excellent pour créer des tutoriels
- **Pour tous** : Simple et rapide pour toute capture d'écran

---

Fait avec ❤️ pour la communauté des développeurs Mac
