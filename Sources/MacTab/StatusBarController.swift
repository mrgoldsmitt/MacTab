import Cocoa
import SwiftUI

public class StatusBarController {
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    
    public init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: "MacTab")
            button.image?.isTemplate = true
        }
        
        buildMenu()
        
        NotificationCenter.default.addObserver(
            forName: .preferencesChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.buildMenu()
        }
    }
    
    private func buildMenu() {
        let menu = NSMenu()
        
        let headerItem = NSMenuItem(title: "MacTab", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        let shortcutItem = NSMenuItem(
            title: "Shortcut: \(PreferencesManager.shared.modifierChoice.rawValue) + Tab",
            action: nil,
            keyEquivalent: ""
        )
        shortcutItem.isEnabled = false
        menu.addItem(shortcutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let triggerItem = NSMenuItem(title: "Fenster-Umschalter öffnen", action: #selector(showSwitcherAction), keyEquivalent: "")
        triggerItem.target = self
        menu.addItem(triggerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Permissions
        let axTrusted = PermissionsManager.shared.hasAccessibilityPermission
        let axItem = NSMenuItem(
            title: axTrusted ? "✓ Bedienungshilfen: Erteilt" : "⚠ Bedienungshilfen: Berechtigung fehlt",
            action: #selector(openAccessibilitySettingsAction),
            keyEquivalent: ""
        )
        axItem.target = self
        menu.addItem(axItem)
        
        let screenTrusted = PermissionsManager.shared.hasScreenRecordingPermission
        let scrItem = NSMenuItem(
            title: screenTrusted ? "✓ Bildschirmaufnahme: Erteilt" : "⚠ Bildschirmaufnahme: Berechtigung fehlt",
            action: #selector(openScreenRecordingSettingsAction),
            keyEquivalent: ""
        )
        scrItem.target = self
        menu.addItem(scrItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Installation Status
        if !InstallationManager.shared.isInstalledInApplications {
            let installItem = NSMenuItem(
                title: "In Programme-Ordner installieren...",
                action: #selector(installToApplicationsAction),
                keyEquivalent: ""
            )
            installItem.target = self
            menu.addItem(installItem)
            menu.addItem(NSMenuItem.separator())
        }
        
        let loginItem = NSMenuItem(
            title: "Beim Systemstart öffnen",
            action: #selector(toggleLaunchAtLoginAction),
            keyEquivalent: ""
        )
        loginItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        loginItem.target = self
        menu.addItem(loginItem)
        
        let prefsItem = NSMenuItem(title: "Einstellungen...", action: #selector(openPreferencesAction), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let uninstallItem = NSMenuItem(title: "MacTab deinstallieren...", action: #selector(uninstallAction), keyEquivalent: "")
        uninstallItem.target = self
        menu.addItem(uninstallItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "MacTab beenden", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func showSwitcherAction() {
        WindowEngine.shared.getWindows { windows in
            SwitcherWindowController.shared.show(with: windows)
        }
    }
    
    @objc private func openAccessibilitySettingsAction() {
        PermissionsManager.shared.requestAccessibility()
    }
    
    @objc private func openScreenRecordingSettingsAction() {
        PermissionsManager.shared.requestScreenRecording()
    }
    
    @objc private func installToApplicationsAction() {
        if InstallationManager.shared.installToApplications() {
            let alert = NSAlert()
            alert.messageText = "MacTab installiert"
            alert.informativeText = "MacTab wurde erfolgreich in den Ordner /Applications kopiert und neu gestartet."
            alert.runModal()
        } else {
            let alert = NSAlert()
            alert.messageText = "Installation fehlgeschlagen"
            alert.informativeText = "MacTab konnte nicht nach /Applications kopiert werden. Nutze bitte das Terminal-Skript ./install.sh."
            alert.runModal()
        }
    }
    
    @objc private func uninstallAction() {
        let alert = NSAlert()
        alert.messageText = "MacTab deinstallieren?"
        alert.informativeText = "Möchtest du MacTab wirklich aus /Applications entfernen und alle Einstellungen zurücksetzen?"
        alert.addButton(withTitle: "Deinstallieren")
        alert.addButton(withTitle: "Abbrechen")
        alert.alertStyle = .warning
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            _ = InstallationManager.shared.uninstall()
            NSApplication.shared.terminate(nil)
        }
    }
    
    @objc public func openPreferencesAction() {
        if preferencesWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 580),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "MacTab Einstellungen"
            window.center()
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: PreferencesView())
            self.preferencesWindow = window
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func toggleLaunchAtLoginAction() {
        LaunchAtLoginManager.shared.toggle()
        buildMenu()
    }
    
    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
