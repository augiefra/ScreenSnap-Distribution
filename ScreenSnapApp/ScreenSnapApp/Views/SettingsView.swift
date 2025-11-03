import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var isRecordingHotKey = false

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("Général", systemImage: "gear")
                }

            HotKeySettingsView()
                .tabItem {
                    Label("Raccourci", systemImage: "keyboard")
                }

            StorageSettingsView()
                .tabItem {
                    Label("Stockage", systemImage: "folder")
                }
        }
        .frame(width: 500, height: 400)
        .environmentObject(settings)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        Form {
            Section(header: Text("Options de capture").font(.headline)) {
                Toggle("Copier dans le presse-papiers", isOn: $settings.copyToClipboard)
                    .help("Permet de coller directement avec Cmd+V dans n'importe quelle application")

                Toggle("Enregistrer sur le disque", isOn: $settings.saveToFile)

                Toggle("Jouer un son lors de la capture", isOn: $settings.playSoundOnCapture)
            }

            Section(header: Text("Format d'image").font(.headline)) {
                Picker("Format:", selection: $settings.imageFormat) {
                    Text("PNG").tag("png")
                    Text("JPEG").tag("jpg")
                }
                .pickerStyle(.radioGroup)
            }
        }
        .padding()
    }
}

struct HotKeySettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        VStack(spacing: 20) {
            Text("Raccourci clavier pour la capture")
                .font(.headline)

            VStack(spacing: 10) {
                Text("Raccourci actuel:")
                    .foregroundColor(.secondary)

                HStack {
                    Text(currentHotKeyString)
                        .font(.system(size: 18, weight: .medium))
                        .padding()
                        .frame(minWidth: 200)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                Button(isRecording ? "Appuyez sur le nouveau raccourci..." : "Modifier le raccourci") {
                    toggleRecording()
                }
                .buttonStyle(.bordered)
                .tint(isRecording ? .red : .blue)

                if isRecording {
                    Text("Appuyez sur Échap pour annuler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 5) {
                Text("Conseils:")
                    .font(.caption)
                    .fontWeight(.semibold)

                Text("• Utilisez des modificateurs (⌘, ⌥, ⌃, ⇧) pour éviter les conflits")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("• Le raccourci par défaut est ⌘⇧5")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
        .padding()
        .onDisappear {
            stopRecording()
        }
    }

    private var currentHotKeyString: String {
        let modifiersString = HotKeyManager.modifiersToString(settings.hotKeyModifiers)
        let keyString = HotKeyManager.keyCodeToString(settings.hotKeyKeyCode)
        return modifiersString + keyString
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.keyCode == 53 { // ESC
                stopRecording()
                return nil
            }

            if event.type == .keyDown {
                let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])

                if !modifiers.isEmpty {
                    settings.hotKeyModifiers = Int(modifiers.rawValue)
                    settings.hotKeyKeyCode = Int(event.keyCode)

                    // Re-register the hotkey
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.hotKeyManager?.registerHotKey()
                    }

                    stopRecording()
                }
                return nil
            }

            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

struct StorageSettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showingFolderPicker = false

    var body: some View {
        Form {
            Section(header: Text("Dossier de sauvegarde").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Les captures d'écran seront enregistrées dans:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text(settings.saveFolderPath)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)

                        Button("Changer...") {
                            if let newPath = settings.selectFolder() {
                                settings.saveFolderPath = newPath
                                settings.ensureFolderExists()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Toggle("Vider le dossier à chaque redémarrage du Mac", isOn: $settings.clearOnRestart)
                    .help("Les captures seront supprimées automatiquement au redémarrage")

                Divider()

                HStack {
                    Button("Ouvrir le dossier") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: settings.saveFolderPath))
                    }
                    .buttonStyle(.bordered)

                    Button("Vider maintenant", role: .destructive) {
                        settings.clearSaveFolder()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
