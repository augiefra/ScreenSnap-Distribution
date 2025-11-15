//
//  SettingsView.swift
//  PastScreen
//
//  Settings window with Glass design
//

import SwiftUI
#if canImport(TipKit)
import TipKit
#endif

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("Général", systemImage: "gear")
                }

            CaptureSettingsTab()
                .tabItem {
                    Label("Capture", systemImage: "camera.fill")
                }

            StorageSettingsTab()
                .tabItem {
                    Label("Stockage", systemImage: "folder.fill")
                }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
#if canImport(TipKit)
            if #available(macOS 14.0, *) {
                TipView(QuickCaptureTip())
                    .tipBackground(.ultraThickMaterial)
                    .padding(.vertical, 4)
            }
#endif
            Section {
                Toggle("Afficher l'icône dans le Dock", isOn: $settings.showInDock)
                    .help("Affiche l'icône de l'application dans le Dock. Désactivez pour passer en mode barre de menus uniquement.")

                Toggle("Jouer un son lors de la capture", isOn: $settings.playSoundOnCapture)
                    .help("Feedback audio lors de chaque capture")

                Toggle("Vérifier les mises à jour automatiquement", isOn: $settings.autoCheckUpdates)
                    .help("Vérifie automatiquement les nouvelles versions au démarrage")
            } header: {
                Text("Options générales")
            }

            Section {
                Button("Afficher le tutoriel de démarrage") {
                    OnboardingManager.shared.show()
                }
                .help("Réaffiche l'écran d'accueil avec les instructions")
            } header: {
                Text("Aide")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Capture Settings Tab

struct CaptureSettingsTab: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section {
                Picker("Format d'image", selection: $settings.imageFormat) {
                    Text("PNG (sans perte)").tag("png")
                    Text("JPEG (compressé)").tag("jpeg")
                }
                .help("PNG recommandé pour du texte et code, JPEG pour des photos")
            } header: {
                Text("Format de fichier")
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Activer le raccourci clavier global", isOn: $settings.globalHotkeyEnabled)
                        .help("Active ou désactive le raccourci ⌥⌘S pour capturer une zone")

                    if settings.globalHotkeyEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Capturer une zone :")
                                Spacer()
                                Text("⌥⌘S")
                                    .font(.system(.body, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }

                            HStack {
                                Text("Clic sur l'icône :")
                                Spacer()
                                Text("Ouvrir le menu")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.leading, 20)
                        .opacity(0.8)
                    } else {
                        Text("Le raccourci clavier global est désactivé. Vous pouvez toujours utiliser l'icône de la barre de menu.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                    }
                }
            } header: {
                Text("Raccourcis clavier")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Storage Settings Tab

struct StorageSettingsTab: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingFolderPicker = false

    var body: some View {
        Form {
            Section {
                Toggle("Enregistrer sur le disque", isOn: $settings.saveToFile)
                    .help("Sauvegarde les captures dans un dossier")

                if settings.saveToFile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dossier de sauvegarde :")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text(settings.saveFolderPath)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)

                            Spacer()

                            Button("Changer...") {
                                if let newPath = settings.selectFolder() {
                                    settings.saveFolderPath = newPath
                                }
                            }
                        }

                        HStack {
                            Button("Ouvrir le dossier") {
                                NSWorkspace.shared.open(URL(fileURLWithPath: settings.saveFolderPath))
                            }

                            Button("Vider le dossier") {
                                settings.clearSaveFolder()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                Text("Stockage")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
