# Guide de Soumission App Store - PastScreen

Ce document détaille la procédure pour compiler et soumettre **PastScreen** sur l'App Store.
Version actuelle : **1.8**

---

## 1. Vérifications Préalables dans Xcode

Avant de lancer l'archive, assurez-vous que la configuration de la **Target App Store** est correcte.

1.  **Sélectionner la Target :**
    *   Dans la barre latérale gauche, cliquez sur l'icône bleue du projet `PastScreen`.
    *   Dans la liste des "Targets", sélectionnez **`PastScreen App Store`** (ou le nom exact de votre seconde target).

2.  **Onglet "General" :**
    *   **Version** : `1.8`
    *   **Build** : `12`
    *   **Minimum Deployments** : `macOS 14.0`

3.  **Onglet "Signing & Capabilities" (CRITIQUE) :**
    *   **Bundle Identifier** : Doit être `com.ecologni.PastScreen` (différent de la version Dev).
    *   **Team** : Votre compte Apple Developer personnel.
    *   **Signing Certificate** : "Apple Distribution" (ou "Development" si vous testez en local, mais "Distribution" pour l'archive).
    *   **App Sandbox** : ✅ **Doit être ACTIVÉ** (C'est la condition sine qua non).
        *   *Network - Outgoing Connections (Client)* : Cochée (pour Sparkle/Mises à jour si utilisé, ou analytics).
        *   *User Selected File* : Read/Write (pour sauvegarder les captures).
    *   **Hardened Runtime** : ✅ **Doit être ACTIVÉ**.

4.  **Entitlements :**
    *   Vérifiez que le fichier pointé est bien `PastScreenAppStore.entitlements`.
    *   Ouvrez ce fichier et assurez-vous que la clé `com.apple.security.temporary-exception.apple-events` est **ABSENTE**.

---

## 2. Création de l'Archive

1.  **Choisir le Scheme :**
    *   En haut à gauche de Xcode (à côté du bouton Play/Stop), cliquez sur le nom du scheme.
    *   Sélectionnez le scheme **`PastScreen App Store`**.
    *   Destination : **"Any Mac (Apple Silicon, Intel)"**.

2.  **Nettoyer (Optionnel mais recommandé) :**
    *   Menu `Product` > `Clean Build Folder`.

3.  **Archiver :**
    *   Menu `Product` > `Archive`.
    *   Attendez que la compilation se termine.

---

## 3. Validation et Upload

Une fois la fenêtre "Organizer" ouverte avec votre nouvelle archive :

1.  Sélectionnez l'archive **1.8 (12)**.
2.  Cliquez sur **"Distribute App"**.
3.  Sélectionnez **"App Store Connect"** > **"Upload"**.
4.  Laissez les options par défaut (Upload symbols, Manage Version automatically).
5.  Si on vous demande de choisir un certificat/profil, laissez Xcode gérer ("Automatically manage signing").
6.  Cliquez sur **"Upload"**.

---

## 4. Configuration dans App Store Connect

Une fois l'upload terminé (attendez le mail de confirmation "Processing Complete") :

1.  Allez sur [App Store Connect](https://appstoreconnect.apple.com).
2.  Sélectionnez votre app.
3.  Créez une nouvelle version (ou modifiez celle en attente) : **1.8**.
4.  **Nouveautés (What's New) :**
    *   Ajoutez le texte en français/anglais mentionnant l'Historique des captures et les correctifs.
    *   *Exemple :* "Découvrez le nouvel historique des captures ! Accédez à vos 10 dernières images directement depuis le menu. Cette version inclut également des correctifs importants et une meilleure gestion des raccourcis clavier."

5.  **Notes pour l'évaluateur (App Review Information) :**
    *   C'est ici qu'il faut être proactif si vous craignez un rejet sur la fonctionnalité de capture.
    *   *Suggestion :* "This app captures screenshots using standard macOS APIs. It requires Screen Recording permission to function. The 'Smart App Detection' feature (which previously required Apple Events) has been disabled for this App Store build to fully comply with Sandboxing rules. The app strictly uses public APIs."

6.  **Soumettre pour validation.**

---

## En cas de Rejet

Si l'application est rejetée :
1.  Lisez attentivement le message (comme nous l'avons fait pour la 1.7).
2.  Ne réagissez pas à chaud.
3.  Vérifiez si c'est un problème de métadonnées (description, screenshots) ou binaire.
4.  Si c'est technique, nous ajusterons le code ensemble.
