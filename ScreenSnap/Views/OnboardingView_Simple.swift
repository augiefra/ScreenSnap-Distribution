//
//  OnboardingView_Simple.swift
//  ScreenSnap
//
//  Simple NSAlert-based onboarding (stable, no SwiftUI crashes)
//

import Foundation
import AppKit

// MARK: - Simple OnboardingManager

class SimpleOnboardingManager {
    static let shared = SimpleOnboardingManager()

    private let hasSeenOnboardingKey = "hasSeenOnboarding"

    var hasSeenOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenOnboardingKey) }
    }

    func showIfNeeded() {
        guard !hasSeenOnboarding else {
            print("ℹ️ [ONBOARDING] Already seen, skipping")
            return
        }
        show()
    }

    func show() {
        DispatchQueue.main.async {
            print("✨ [ONBOARDING] Showing welcome screen")

            let alert = NSAlert()
            alert.messageText = "🎉 Bienvenue dans ScreenSnap!"
            alert.informativeText = """
            ScreenSnap simplifie vos captures d'écran pour les développeurs.

            🚀 Pourquoi ScreenSnap ?

            ⚡️ Ultra-rapide
                ⌥⌘S → Capturer → Cmd+V → C'est collé !
                (Plus besoin de chercher le fichier)

            🧹 Nettoyage automatique
                Toutes vos captures vidées au redémarrage du Mac
                (Fini les dossiers qui débordent)

            🔔 Notifications intelligentes
                Cliquez pour ouvrir directement dans le Finder
                (Comme les apps pro, pas comme la fonction native)

            📋 Workflow optimisé
                Capture → Clipboard → Coller dans votre IDE
                (Parfait pour Cursor, Zed, VSCode)

            ⚙️  Personnalisable
                Icône menu bar → Préférences

            vs. Capture macOS native : Fichiers sur le Bureau qui s'accumulent
            vs. Autres apps : Interface complexe, pas de nettoyage auto
            """

            alert.alertStyle = .informational
            alert.showsSuppressionButton = true
            alert.suppressionButton?.title = "Ne plus afficher"

            alert.addButton(withTitle: "Compris!")

            // Show the alert
            let response = alert.runModal()

            // Check if user clicked "Don't show again"
            if alert.suppressionButton?.state == .on {
                self.hasSeenOnboarding = true
                print("✅ [ONBOARDING] User chose 'Don't show again'")
            }

            print("✅ [ONBOARDING] Dismissed")
        }
    }
}
