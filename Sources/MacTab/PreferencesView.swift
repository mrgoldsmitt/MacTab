import SwiftUI

public struct PreferencesView: View {
    @ObservedObject var prefs = PreferencesManager.shared
    @ObservedObject var perms = PermissionsManager.shared
    @ObservedObject var installer = InstallationManager.shared
    @ObservedObject var launchAtLogin = LaunchAtLoginManager.shared
    
    @State private var showUninstallAlert: Bool = false
    @State private var installationMessage: String? = nil
    @State private var showChangelog: Bool = true
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("MacTab")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("v0.2.0")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        Text("Fast, stable, and native window switcher for macOS")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 4)
                
                Divider()
                
                // Installation Management Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Installation & Systemstart")
                        .font(.headline)
                    
                    if installer.isInstalledInApplications {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("MacTab ist im Programme-Ordner installiert")
                                    .fontWeight(.medium)
                                Text("/Applications/MacTab.app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Deinstallieren...", role: .destructive) {
                                showUninstallAlert = true
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundColor(.orange)
                                Text("Läuft außerhalb des Programme-Ordners")
                                    .fontWeight(.medium)
                                Spacer()
                                Button("In Programme installieren") {
                                    if installer.installToApplications() {
                                        installationMessage = "MacTab wurde erfolgreich nach /Applications kopiert."
                                    } else {
                                        installationMessage = "Installation fehlgeschlagen. Bitte manuell oder via ./install.sh versuchen."
                                    }
                                }
                            }
                            if let msg = installationMessage {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Divider()
                    
                    Toggle(isOn: Binding(
                        get: { launchAtLogin.isEnabled },
                        set: { launchAtLogin.setEnabled($0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Beim Systemstart automatisch öffnen")
                                .fontWeight(.medium)
                            Text("Startet MacTab im Hintergrund bei jeder Benutzeranmeldung.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(10)
                
                // Permissions Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("System Permissions")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: perms.hasAccessibilityPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(perms.hasAccessibilityPermission ? .green : .red)
                        Text("Accessibility")
                            .fontWeight(.medium)
                        Spacer()
                        if !perms.hasAccessibilityPermission {
                            Button("Grant Access") {
                                perms.requestAccessibility()
                            }
                        } else {
                            Text("Granted")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: perms.hasScreenRecordingPermission ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(perms.hasScreenRecordingPermission ? .green : .yellow)
                        Text("Screen Recording (for thumbnails)")
                            .fontWeight(.medium)
                        Spacer()
                        if !perms.hasScreenRecordingPermission {
                            Button("Grant Access") {
                                perms.requestScreenRecording()
                            }
                        } else {
                            Text("Granted")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Probleme mit Berechtigungen?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Berechtigungen im System zurücksetzen (TCC Reset)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Rechte zurücksetzen") {
                            perms.resetPermissions()
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(10)
                
                // Shortcut Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Keyboard Shortcut")
                        .font(.headline)
                    
                    Picker("Trigger Modifier:", selection: $prefs.modifierChoice) {
                        ForEach(ModifierKeyChoice.allCases) { choice in
                            Text(choice.rawValue).tag(choice)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Text("Drücke \(prefs.modifierChoice.rawValue) + Tab, um den Fenster-Umschalter aufzurufen.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Window Filtering Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Window Inclusion")
                        .font(.headline)
                    
                    Toggle("Minimierte Fenster anzeigen", isOn: $prefs.showMinimized)
                    Toggle("Fenster ausgeblendeter Apps anzeigen", isOn: $prefs.showHidden)
                    Toggle("Ausgewähltes Fenster auf dem Bildschirm umranden", isOn: $prefs.highlightSelectedWindow)
                }
                
                // Changelog Section
                VStack(alignment: .leading, spacing: 10) {
                    DisclosureGroup(isExpanded: $showChangelog) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Version 0.2.0")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("21. Okt 2026")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ChangelogEntry(icon: "rectangle.dashed", text: "Echtes Fenster wird auf dem Bildschirm farbig umrandet, solange es im Switcher ausgewählt ist (abschaltbar)")
                            }
                            .padding(.top, 2)
                            
                            Divider()
                            
                            HStack {
                                Text("Version 0.1.0")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("Initialer Release • 20. Okt 2026")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ChangelogEntry(icon: "sparkles", text: "Initialer Release: Schlanker & stabiler nativer Fenster-Umschalter für macOS")
                                ChangelogEntry(icon: "bolt.shield", text: "150ms AX-Timeouts & Auto-Healing Event Tap (verhindert Hänger)")
                                ChangelogEntry(icon: "square.grid.2x2", text: "4-Spalten-Raster mit Zeilenumbruch & 2D-Tastaturnavigation (↑/↓/←/→)")
                                ChangelogEntry(icon: "arrow.triangle.2.circlepath", text: "MRU-Fokus: Zuletzt aktives Fenster steht immer direkt als nächstes zur Auswahl")
                                ChangelogEntry(icon: "cursorarrow.rays", text: "Präzises Einzelfenster-Highlighting ohne überlappende Markierungen")
                                ChangelogEntry(icon: "questionmark.circle", text: "Kompaktes Tastatur-Hilfe-Icon unten rechts im Switcher-HUD")
                                ChangelogEntry(icon: "power", text: "Automatischer Systemstart (Launch at Login via SMAppService & LaunchAgent)")
                                ChangelogEntry(icon: "arrow.down.doc", text: "In-App Installation nach /Applications, Uninstaller & MacTab.dmg zur Weitergabe")
                                ChangelogEntry(icon: "lock.shield", text: "TCC-Berechtigungsmanager mit Reset-Funktion bei Systemkonflikten")
                            }
                            .padding(.top, 2)
                        }
                        .padding(.top, 6)
                    } label: {
                        HStack {
                            Image(systemName: "list.bullet.rectangle.portrait")
                                .foregroundColor(.accentColor)
                            Text("Changelog")
                                .font(.headline)
                            Spacer()
                            Text("v0.2.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(10)
                
                Divider()
                
                HStack {
                    Spacer()
                    Text("MacTab v0.2.0 • Pure Swift & Metal/CoreGraphics")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 560)
        .alert("MacTab deinstallieren?", isPresented: $showUninstallAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Deinstallieren und beenden", role: .destructive) {
                _ = installer.uninstall()
                NSApplication.shared.terminate(nil)
            }
        } message: {
            Text("MacTab wird aus dem Programme-Ordner (/Applications/MacTab.app) gelöscht und alle Einstellungen zurückgesetzt. Die App beendet sich anschließend.")
        }
    }
}

struct ChangelogEntry: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.accentColor)
                .frame(width: 14, height: 14)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
