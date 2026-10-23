import Cocoa

public class InstallationManager: ObservableObject {
    public static let shared = InstallationManager()
    
    private let targetPath = "/Applications/MacTab.app"
    
    @Published public var isInstalledInApplications: Bool = false
    
    private init() {
        checkStatus()
    }
    
    public func checkStatus() {
        let currentPath = Bundle.main.bundlePath
        let installed = currentPath == targetPath || (FileManager.default.fileExists(atPath: targetPath) && currentPath.hasPrefix("/Applications/"))
        DispatchQueue.main.async {
            self.isInstalledInApplications = installed
        }
    }
    
    /// Installs MacTab into /Applications and relaunches from there.
    public func installToApplications() -> Bool {
        let fileManager = FileManager.default
        let currentBundlePath = Bundle.main.bundlePath
        
        do {
            // If already at target, nothing to do
            if currentBundlePath == targetPath {
                return true
            }
            
            // Remove previous installation if present
            if fileManager.fileExists(atPath: targetPath) {
                try fileManager.removeItem(atPath: targetPath)
            }
            
            // Copy bundle to /Applications
            try fileManager.copyItem(atPath: currentBundlePath, toPath: targetPath)
            
            // Launch installed app from /Applications
            let targetURL = URL(fileURLWithPath: targetPath)
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            
            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { app, error in
                DispatchQueue.main.async {
                    if error == nil {
                        // Exit the old instance so the new instance in /Applications takes over
                        NSApp.terminate(nil)
                    }
                }
            }
            return true
        } catch {
            print("[MacTab] Installation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Uninstalls MacTab from /Applications and cleans up preferences.
    public func uninstall() -> Bool {
        let fileManager = FileManager.default
        
        // 1. Disable launch at login & remove LaunchAgent
        LaunchAtLoginManager.shared.setEnabled(false)
        
        // 2. Remove preferences
        UserDefaults.standard.removePersistentDomain(forName: "com.mactab.app")
        
        // 2. Remove /Applications/MacTab.app if it exists
        if fileManager.fileExists(atPath: targetPath) {
            do {
                try fileManager.removeItem(atPath: targetPath)
            } catch {
                print("[MacTab] Failed to remove app bundle: \(error.localizedDescription)")
                return false
            }
        }
        
        return true
    }
}
