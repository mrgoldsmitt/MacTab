import Cocoa
import ApplicationServices
import CoreGraphics

// Private C API declaration for extracting CGWindowID from AXUIElement if available
@_silgen_name("_AXUIElementGetWindow")
private func _AXUIElementGetWindow(_ element: AXUIElement, _ wid: UnsafeMutablePointer<CGWindowID>) -> AXError

public class WindowEngine {
    public static let shared = WindowEngine()
    
    private let discoveryQueue = DispatchQueue(label: "com.mactab.windowdiscovery", qos: .userInteractive)
    
    // Ignored system processes that shouldn't appear in the window switcher
    private let ignoredProcessNames: Set<String> = [
        "Window Server",
        "Dock",
        "Wallpaper",
        "Control Center",
        "SystemUIServer",
        "Notification Center",
        "NotificationCenter",
        "Spotlight",
        "MacTab",
        "TextInputMenuAgent",
        "loginwindow",
        "screencaptureui"
    ]
    
    private init() {}
    
    /// Queries all visible and minimized windows asynchronously and returns them sorted by z-order.
    public func getWindows(completion: @escaping ([WindowModel]) -> Void) {
        discoveryQueue.async {
            let pref = PreferencesManager.shared
            
            // 1. Get on-screen windows (ordered front to back by macOS window server)
            let onScreenOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
            let onScreenList = (CGWindowListCopyWindowInfo(onScreenOptions, kCGNullWindowID) as? [[String: Any]]) ?? []
            
            // 2. If showing minimized, query all windows to find minimized ones
            var allList: [[String: Any]] = []
            if pref.showMinimized {
                allList = (CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]]) ?? []
            }
            
            var onScreenWindowIDs = Set<CGWindowID>()
            var candidateWindows: [WindowModel] = []
            
            // Process on-screen windows first
            for info in onScreenList {
                guard let window = self.parseWindowInfo(info, isOnActiveSpace: true, isMinimized: false) else {
                    continue
                }
                onScreenWindowIDs.insert(window.id)
                candidateWindows.append(window)
            }
            
            // If requested, append minimized windows that weren't in the onScreen list
            if pref.showMinimized {
                for info in allList {
                    guard let id = info[kCGWindowNumber as String] as? CGWindowID,
                          !onScreenWindowIDs.contains(id) else {
                        continue
                    }
                    if let window = self.parseWindowInfo(info, isOnActiveSpace: false, isMinimized: true) {
                        candidateWindows.append(window)
                    }
                }
            }
            
            // Associate Accessibility elements in background without blocking
            self.attachAccessibilityElements(&candidateWindows)
            
            // Ensure the currently active/frontmost application's window is at index 0,
            // so index 1 is guaranteed to be the previous foreground window!
            if let frontmostApp = NSWorkspace.shared.frontmostApplication {
                let frontPid = frontmostApp.processIdentifier
                if let activeIndex = candidateWindows.firstIndex(where: { $0.pid == frontPid && !$0.isMinimized }), activeIndex > 0 {
                    let activeWin = candidateWindows.remove(at: activeIndex)
                    candidateWindows.insert(activeWin, at: 0)
                }
            }
            
            DispatchQueue.main.async {
                completion(candidateWindows)
            }
        }
    }
    
    private func parseWindowInfo(_ info: [String: Any], isOnActiveSpace: Bool, isMinimized: Bool) -> WindowModel? {
        guard let id = info[kCGWindowNumber as String] as? CGWindowID,
              let pid = info[kCGWindowOwnerPID as String] as? pid_t,
              let layer = info[kCGWindowLayer as String] as? Int,
              layer == 0 else {
            return nil
        }
        
        // Check window bounds using robust CoreGraphics dictionary representation
        var bounds = CGRect.zero
        if let boundsDict = info[kCGWindowBounds as String] as? [String: Any] {
            CGRectMakeWithDictionaryRepresentation(boundsDict as CFDictionary, &bounds)
        }
        
        // Ignore tiny utility / invisible windows
        if !isMinimized && (bounds.width < 80 || bounds.height < 60) {
            return nil
        }
        
        let ownerName = (info[kCGWindowOwnerName as String] as? String) ?? "Unknown"
        if ignoredProcessNames.contains(ownerName) {
            return nil
        }
        
        let windowName = (info[kCGWindowName as String] as? String) ?? ""
        
        // Find running application
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return nil
        }
        
        // Filter out background auxiliary apps without UI
        if app.activationPolicy == .prohibited {
            return nil
        }
        
        let appName = app.localizedName ?? ownerName
        let isHidden = app.isHidden
        
        // Skip hidden windows if user disabled them in settings
        if isHidden && !PreferencesManager.shared.showHidden {
            return nil
        }
        
        return WindowModel(
            id: id,
            pid: pid,
            appName: appName,
            title: windowName.isEmpty ? appName : windowName,
            bundleIdentifier: app.bundleIdentifier,
            appIcon: app.icon,
            bounds: bounds,
            isMinimized: isMinimized,
            isHidden: isHidden,
            isOnActiveSpace: isOnActiveSpace,
            axElement: nil,
            thumbnail: nil,
            thumbnailLoaded: false
        )
    }
    
    /// Attaches AXUIElement to each window using bounded timeouts (prevents hangs).
    private func attachAccessibilityElements(_ windows: inout [WindowModel]) {
        // Group by pid to avoid creating redundant AXUIElementCreateApplication
        var appsByPid: [pid_t: AXUIElement] = [:]
        
        for i in 0..<windows.count {
            let pid = windows[i].pid
            let axApp: AXUIElement
            if let existing = appsByPid[pid] {
                axApp = existing
            } else {
                let created = AXUIElementCreateApplication(pid)
                // Set strict messaging timeout to 150ms so an unresponsive app will never freeze MacTab!
                AXUIElementSetMessagingTimeout(created, 0.15)
                appsByPid[pid] = created
                axApp = created
            }
            
            // Get windows attribute
            var windowsValue: AnyObject?
            let copyResult = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsValue)
            guard copyResult == .success, let axWindowsList = windowsValue as? [AXUIElement] else {
                continue
            }
            
            // Try to match by CGWindowID using _AXUIElementGetWindow
            var matchedElement: AXUIElement?
            for axWin in axWindowsList {
                var wid: CGWindowID = 0
                if _AXUIElementGetWindow(axWin, &wid) == .success, wid == windows[i].id {
                    matchedElement = axWin
                    break
                }
            }
            
            // Fallback match: if window title matches
            if matchedElement == nil && !windows[i].title.isEmpty {
                for axWin in axWindowsList {
                    var titleValue: AnyObject?
                    if AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleValue) == .success,
                       let str = titleValue as? String, str == windows[i].title {
                        matchedElement = axWin
                        break
                    }
                }
            }
            
            if let elem = matchedElement {
                // If title was empty before, fetch real title from accessibility
                var currentTitle = windows[i].title
                if currentTitle == windows[i].appName {
                    var titleValue: AnyObject?
                    if AXUIElementCopyAttributeValue(elem, kAXTitleAttribute as CFString, &titleValue) == .success,
                       let str = titleValue as? String, !str.isEmpty {
                        currentTitle = str
                    }
                }
                
                // Check if minimized
                var isMin = windows[i].isMinimized
                var minVal: AnyObject?
                if AXUIElementCopyAttributeValue(elem, kAXMinimizedAttribute as CFString, &minVal) == .success,
                   let boolVal = minVal as? Bool {
                    isMin = boolVal
                }
                
                windows[i] = WindowModel(
                    id: windows[i].id,
                    pid: windows[i].pid,
                    appName: windows[i].appName,
                    title: currentTitle,
                    bundleIdentifier: windows[i].bundleIdentifier,
                    appIcon: windows[i].appIcon,
                    bounds: windows[i].bounds,
                    isMinimized: isMin,
                    isHidden: windows[i].isHidden,
                    isOnActiveSpace: windows[i].isOnActiveSpace,
                    axElement: elem,
                    thumbnail: nil,
                    thumbnailLoaded: false
                )
            }
        }
    }
    
    /// Brings the specified window to the front and activates its application.
    public func focusWindow(_ window: WindowModel) {
        guard let app = NSRunningApplication(processIdentifier: window.pid) else {
            return
        }
        
        // 1. Unhide application if hidden
        if app.isHidden {
            app.unhide()
        }
        
        // 2. Unminimize window if minimized
        if let axWin = window.axElement {
            if window.isMinimized {
                AXUIElementSetAttributeValue(axWin, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            }
            // Raise the window
            AXUIElementPerformAction(axWin, kAXRaiseAction as CFString)
            AXUIElementSetAttributeValue(axWin, kAXMainAttribute as CFString, kCFBooleanTrue)
        }
        
        // 3. Activate the application
        app.activate(options: [.activateIgnoringOtherApps])
    }
    
    /// Closes the specified window via Accessibility.
    public func closeWindow(_ window: WindowModel) {
        guard let axWin = window.axElement else {
            return
        }
        
        // Try close button
        var closeButtonValue: AnyObject?
        if AXUIElementCopyAttributeValue(axWin, kAXCloseButtonAttribute as CFString, &closeButtonValue) == .success,
           let closeButton = closeButtonValue {
            let buttonElement = closeButton as! AXUIElement
            AXUIElementPerformAction(buttonElement, kAXPressAction as CFString)
        } else {
            // Fallback action
            AXUIElementPerformAction(axWin, "AXClose" as CFString)
        }
    }
    
    /// Minimizes the specified window.
    public func minimizeWindow(_ window: WindowModel) {
        guard let axWin = window.axElement else { return }
        AXUIElementSetAttributeValue(axWin, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }
    
    /// Hides the entire application.
    public func hideApplication(_ window: WindowModel) {
        if let app = NSRunningApplication(processIdentifier: window.pid) {
            app.hide()
        }
    }
}
