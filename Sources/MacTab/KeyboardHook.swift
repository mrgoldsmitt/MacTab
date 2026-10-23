import Cocoa
import Carbon.HIToolbox

public protocol KeyboardHookDelegate: AnyObject {
    func onTriggerPressed(isShiftHeld: Bool)
    func onTabPressed(isShiftHeld: Bool)
    func onArrowPressed(direction: NavigationDirection)
    func onNumberPressed(number: Int)
    func onClosePressed()
    func onMinimizePressed()
    func onHidePressed()
    func onPreviewPressed()
    func onEscapePressed()
    func onModifierReleased()
}

public enum NavigationDirection {
    case left, right, up, down
}

public class KeyboardHook {
    public static let shared = KeyboardHook()
    
    public weak var delegate: KeyboardHookDelegate?
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var watchdogTimer: Timer?
    
    public var isSwitcherVisible: Bool = false
    
    // Key codes
    private let kVK_Tab: Int64 = 0x30
    private let kVK_Escape: Int64 = 0x35
    private let kVK_Space: Int64 = 0x31
    private let kVK_Delete: Int64 = 0x33
    private let kVK_ANSI_W: Int64 = 0x0D
    private let kVK_ANSI_X: Int64 = 0x07
    private let kVK_ANSI_M: Int64 = 0x2E
    private let kVK_ANSI_H: Int64 = 0x04
    
    private let kVK_LeftArrow: Int64 = 0x7B
    private let kVK_RightArrow: Int64 = 0x7C
    private let kVK_DownArrow: Int64 = 0x7D
    private let kVK_UpArrow: Int64 = 0x7E
    
    private let numberKeyCodes: [Int64: Int] = [
        0x12: 1, // '1'
        0x13: 2, // '2'
        0x14: 3, // '3'
        0x15: 4, // '4'
        0x17: 5, // '5'
        0x16: 6, // '6'
        0x1A: 7, // '7'
        0x1C: 8, // '8'
        0x19: 9  // '9'
    ]
    
    private init() {}
    
    public func start() {
        stop()
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                        (1 << CGEventType.keyUp.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)
        
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let hook = Unmanaged<KeyboardHook>.fromOpaque(refcon).takeUnretainedValue()
                return hook.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: observer
        ) else {
            print("[MacTab] Failed to create event tap. Ensure Accessibility permissions are granted.")
            return
        }
        
        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        // Watchdog timer: re-enables tap if macOS disables it by timeout
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self, let tap = self.eventTap else { return }
            if !CGEvent.tapIsEnabled(tap: tap) {
                print("[MacTab] Event tap was disabled; re-enabling now.")
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
    }
    
    public func stop() {
        watchdogTimer?.invalidate()
        watchdogTimer = nil
        
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                runLoopSource = nil
            }
            eventTap = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Auto-recover if macOS temporarily disables tap
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        let flags = event.flags
        let targetModifierFlag = PreferencesManager.shared.modifierChoice.cgEventFlags
        let isModifierDown = flags.contains(targetModifierFlag)
        let isShiftDown = flags.contains(.maskShift)
        
        // 1. Handle Modifier Release
        if type == .flagsChanged {
            if isSwitcherVisible && !isModifierDown {
                // User let go of modifier -> switch to selected window!
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.onModifierReleased()
                }
            }
            return Unmanaged.passUnretained(event)
        }
        
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // 2. Switcher is NOT visible: Check for trigger (Modifier + Tab)
        if !isSwitcherVisible {
            if isModifierDown && keyCode == kVK_Tab {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.onTriggerPressed(isShiftHeld: isShiftDown)
                }
                return nil // Intercept & swallow event so active app doesn't receive Tab
            }
            return Unmanaged.passUnretained(event)
        }
        
        // 3. Switcher IS visible: Navigation & Actions
        switch keyCode {
        case kVK_Tab:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onTabPressed(isShiftHeld: isShiftDown)
            }
            return nil
            
        case kVK_LeftArrow:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onArrowPressed(direction: .left)
            }
            return nil
            
        case kVK_RightArrow:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onArrowPressed(direction: .right)
            }
            return nil
            
        case kVK_UpArrow:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onArrowPressed(direction: .up)
            }
            return nil
            
        case kVK_DownArrow:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onArrowPressed(direction: .down)
            }
            return nil
            
        case kVK_Escape:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onEscapePressed()
            }
            return nil
            
        case kVK_Space:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onPreviewPressed()
            }
            return nil
            
        case kVK_ANSI_W, kVK_ANSI_X, kVK_Delete:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onClosePressed()
            }
            return nil
            
        case kVK_ANSI_M:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onMinimizePressed()
            }
            return nil
            
        case kVK_ANSI_H:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.onHidePressed()
            }
            return nil
            
        default:
            if let number = numberKeyCodes[keyCode] {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.onNumberPressed(number: number)
                }
                return nil
            }
            // If another key is pressed while switcher is open, swallow to prevent typing into background apps
            return nil
        }
    }
}
