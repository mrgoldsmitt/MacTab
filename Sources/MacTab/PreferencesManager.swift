import Cocoa
import Combine

public enum ModifierKeyChoice: String, CaseIterable, Identifiable {
    case option = "Option (⌥)"
    case command = "Command (⌘)"
    case control = "Control (⌃)"
    
    public var id: String { rawValue }
    
    public var eventMask: NSEvent.ModifierFlags {
        switch self {
        case .option: return .option
        case .command: return .command
        case .control: return .control
        }
    }
    
    public var cgEventFlags: CGEventFlags {
        switch self {
        case .option: return .maskAlternate
        case .command: return .maskCommand
        case .control: return .maskControl
        }
    }
}

public class PreferencesManager: ObservableObject {
    public static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    @Published public var modifierChoice: ModifierKeyChoice {
        didSet {
            defaults.set(modifierChoice.rawValue, forKey: "modifierChoice")
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @Published public var showMinimized: Bool {
        didSet {
            defaults.set(showMinimized, forKey: "showMinimized")
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @Published public var showHidden: Bool {
        didSet {
            defaults.set(showHidden, forKey: "showHidden")
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @Published public var showOnlyCurrentSpace: Bool {
        didSet {
            defaults.set(showOnlyCurrentSpace, forKey: "showOnlyCurrentSpace")
            NotificationCenter.default.post(name: .preferencesChanged, object: nil)
        }
    }
    
    @Published public var tileWidth: CGFloat {
        didSet {
            defaults.set(tileWidth, forKey: "tileWidth")
        }
    }
    
    @Published public var tileHeight: CGFloat {
        didSet {
            defaults.set(tileHeight, forKey: "tileHeight")
        }
    }
    
    @Published public var showAppIcons: Bool {
        didSet {
            defaults.set(showAppIcons, forKey: "showAppIcons")
        }
    }
    
    @Published public var showTitles: Bool {
        didSet {
            defaults.set(showTitles, forKey: "showTitles")
        }
    }
    
    /// Draws a colored outline around the real on-screen window that is currently selected in the switcher.
    @Published public var highlightSelectedWindow: Bool {
        didSet {
            defaults.set(highlightSelectedWindow, forKey: "highlightSelectedWindow")
        }
    }
    
    private init() {
        let savedMod = defaults.string(forKey: "modifierChoice") ?? ModifierKeyChoice.option.rawValue
        self.modifierChoice = ModifierKeyChoice(rawValue: savedMod) ?? .option
        
        self.showMinimized = defaults.object(forKey: "showMinimized") == nil ? true : defaults.bool(forKey: "showMinimized")
        self.showHidden = defaults.object(forKey: "showHidden") == nil ? true : defaults.bool(forKey: "showHidden")
        self.showOnlyCurrentSpace = defaults.bool(forKey: "showOnlyCurrentSpace")
        
        self.tileWidth = defaults.object(forKey: "tileWidth") == nil ? 220 : CGFloat(defaults.double(forKey: "tileWidth"))
        self.tileHeight = defaults.object(forKey: "tileHeight") == nil ? 140 : CGFloat(defaults.double(forKey: "tileHeight"))
        
        self.showAppIcons = defaults.object(forKey: "showAppIcons") == nil ? true : defaults.bool(forKey: "showAppIcons")
        self.showTitles = defaults.object(forKey: "showTitles") == nil ? true : defaults.bool(forKey: "showTitles")
        self.highlightSelectedWindow = defaults.object(forKey: "highlightSelectedWindow") == nil ? true : defaults.bool(forKey: "highlightSelectedWindow")
    }
}

public extension Notification.Name {
    static let preferencesChanged = Notification.Name("com.mactab.preferencesChanged")
}
