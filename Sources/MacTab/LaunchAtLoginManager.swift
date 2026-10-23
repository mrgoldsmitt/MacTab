import Cocoa
import ServiceManagement
import Combine

public class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()
    
    private let agentPath = ("~/Library/LaunchAgents/com.mactab.app.plist" as NSString).expandingTildeInPath
    
    @Published public var isEnabled: Bool = false
    
    private init() {
        checkStatus()
    }
    
    public func checkStatus() {
        var active = false
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled {
                active = true
            }
        }
        if !active {
            active = FileManager.default.fileExists(atPath: agentPath)
        }
        DispatchQueue.main.async {
            self.isEnabled = active
        }
    }
    
    public func setEnabled(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                
                // If register succeeded and SMAppService is enabled, ensure any legacy LaunchAgent is removed
                if SMAppService.mainApp.status == .enabled {
                    removeLaunchAgent()
                    checkStatus()
                    return
                }
            } catch {
                NSLog("[MacTab] SMAppService failed (\(error)), falling back to LaunchAgent")
            }
        }
        
        // Fallback via LaunchAgent
        if enable {
            installLaunchAgent()
        } else {
            removeLaunchAgent()
        }
        checkStatus()
    }
    
    public func toggle() {
        setEnabled(!isEnabled)
    }
    
    public func installLaunchAgent() {
        let targetAppPath = "/Applications/MacTab.app/Contents/MacOS/MacTab"
        let plistContent = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mactab.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>\(targetAppPath)</string>
    </array>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
</dict>
</plist>
"""
        let dir = ("~/Library/LaunchAgents" as NSString).expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? plistContent.write(toFile: agentPath, atomically: true, encoding: .utf8)
    }
    
    public func removeLaunchAgent() {
        try? FileManager.default.removeItem(atPath: agentPath)
    }
}
