import Cocoa
import ApplicationServices
import CoreGraphics

public class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()
    
    @Published public var hasAccessibilityPermission: Bool = false
    @Published public var hasScreenRecordingPermission: Bool = false
    
    private var timer: Timer?
    
    private init() {
        checkPermissions()
        
        // Periodically verify permissions every second on the main runloop
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkPermissions()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public func checkPermissions() {
        let axTrusted = AXIsProcessTrusted()
        let screenTrusted = CGPreflightScreenCaptureAccess()
        
        DispatchQueue.main.async {
            if self.hasAccessibilityPermission != axTrusted {
                self.hasAccessibilityPermission = axTrusted
            }
            if self.hasScreenRecordingPermission != screenTrusted {
                self.hasScreenRecordingPermission = screenTrusted
            }
        }
    }
    
    public func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        hasAccessibilityPermission = trusted
        if !trusted {
            openAccessibilitySettings()
        }
    }
    
    public func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
        openScreenRecordingSettings()
    }
    
    public func resetPermissions() {
        let p1 = Process()
        p1.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p1.arguments = ["reset", "Accessibility", "com.mactab.app"]
        try? p1.run()
        p1.waitUntilExit()
        
        let p2 = Process()
        p2.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        p2.arguments = ["reset", "ScreenCapture", "com.mactab.app"]
        try? p2.run()
        p2.waitUntilExit()
        
        checkPermissions()
    }
    
    public func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
