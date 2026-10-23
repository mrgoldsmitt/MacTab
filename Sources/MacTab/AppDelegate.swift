import Cocoa

public class AppDelegate: NSObject, NSApplicationDelegate, KeyboardHookDelegate {
    private var statusBarController: StatusBarController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent app from showing in Dock (agent / background helper app)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize status bar item
        statusBarController = StatusBarController()
        
        // Initialize keyboard hook
        KeyboardHook.shared.delegate = self
        KeyboardHook.shared.start()
        
        // Verify permissions
        let axTrusted = PermissionsManager.shared.hasAccessibilityPermission
        if !axTrusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                PermissionsManager.shared.requestAccessibility()
                self?.statusBarController?.openPreferencesAction()
            }
        }
    }
    
    // MARK: - KeyboardHookDelegate
    
    public func onTriggerPressed(isShiftHeld: Bool) {
        WindowEngine.shared.getWindows { windows in
            SwitcherWindowController.shared.show(with: windows)
            if isShiftHeld {
                SwitcherWindowController.shared.selectPrevious()
            }
        }
    }
    
    public func onTabPressed(isShiftHeld: Bool) {
        if isShiftHeld {
            SwitcherWindowController.shared.selectPrevious()
        } else {
            SwitcherWindowController.shared.selectNext()
        }
    }
    
    public func onArrowPressed(direction: NavigationDirection) {
        switch direction {
        case .left:
            SwitcherWindowController.shared.selectPrevious()
        case .right:
            SwitcherWindowController.shared.selectNext()
        case .up:
            SwitcherWindowController.shared.moveUp()
        case .down:
            SwitcherWindowController.shared.moveDown()
        }
    }
    
    public func onNumberPressed(number: Int) {
        SwitcherWindowController.shared.selectByNumber(number)
    }
    
    public func onClosePressed() {
        SwitcherWindowController.shared.closeCurrent()
    }
    
    public func onMinimizePressed() {
        SwitcherWindowController.shared.minimizeCurrent()
    }
    
    public func onHidePressed() {
        SwitcherWindowController.shared.hideCurrent()
    }
    
    public func onPreviewPressed() {
        SwitcherWindowController.shared.togglePreview()
    }
    
    public func onEscapePressed() {
        SwitcherWindowController.shared.dismiss()
    }
    
    public func onModifierReleased() {
        SwitcherWindowController.shared.focusSelected()
    }
}
