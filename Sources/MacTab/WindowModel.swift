import Cocoa
import ApplicationServices

/// Represents an active window displayed in the MacTab switcher.
public struct WindowModel: Identifiable, Equatable {
    public let id: CGWindowID
    public let pid: pid_t
    public let appName: String
    public let title: String
    public let bundleIdentifier: String?
    public let appIcon: NSImage?
    public let bounds: CGRect
    public let isMinimized: Bool
    public let isHidden: Bool
    public let isOnActiveSpace: Bool
    public let axElement: AXUIElement?
    
    // Thumbnail cached image
    public var thumbnail: NSImage?
    public var thumbnailLoaded: Bool = false
    
    public init(
        id: CGWindowID,
        pid: pid_t,
        appName: String,
        title: String,
        bundleIdentifier: String?,
        appIcon: NSImage?,
        bounds: CGRect,
        isMinimized: Bool = false,
        isHidden: Bool = false,
        isOnActiveSpace: Bool = true,
        axElement: AXUIElement? = nil,
        thumbnail: NSImage? = nil,
        thumbnailLoaded: Bool = false
    ) {
        self.id = id
        self.pid = pid
        self.appName = appName
        self.title = title
        self.bundleIdentifier = bundleIdentifier
        self.appIcon = appIcon
        self.bounds = bounds
        self.isMinimized = isMinimized
        self.isHidden = isHidden
        self.isOnActiveSpace = isOnActiveSpace
        self.axElement = axElement
        self.thumbnail = thumbnail
        self.thumbnailLoaded = thumbnailLoaded
    }
    
    public static func == (lhs: WindowModel, rhs: WindowModel) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isMinimized == rhs.isMinimized &&
               lhs.isHidden == rhs.isHidden &&
               lhs.thumbnailLoaded == rhs.thumbnailLoaded
    }
}
