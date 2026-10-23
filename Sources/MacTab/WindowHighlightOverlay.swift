import Cocoa

/// Draws a colored, click-through outline around the real on-screen window
/// that is currently selected in the switcher HUD.
///
/// Implementation notes:
/// - Uses a borderless, transparent, non-activating window that ignores mouse events,
///   so it never steals focus or intercepts clicks.
/// - Sits one level below the switcher panel (`.floating`), so it is drawn above normal
///   app windows but never on top of the HUD itself.
/// - CGWindowList bounds use a top-left origin relative to the primary display; they are
///   converted to Cocoa's bottom-left coordinate system before positioning.
public final class WindowHighlightOverlay {
    public static let shared = WindowHighlightOverlay()
    
    private var overlayWindow: NSWindow?
    private var currentWindowID: CGWindowID?
    
    private let borderWidth: CGFloat = 4
    private let outset: CGFloat = 3
    
    private init() {}
    
    private func ensureWindow() -> NSWindow {
        if let existing = overlayWindow { return existing }
        
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue - 1)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        
        let borderView = NSView(frame: .zero)
        borderView.wantsLayer = true
        if let layer = borderView.layer {
            layer.borderWidth = borderWidth
            layer.cornerRadius = 12
            layer.borderColor = NSColor.controlAccentColor.cgColor
            layer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.06).cgColor
            layer.shadowColor = NSColor.controlAccentColor.cgColor
            layer.shadowOpacity = 0.8
            layer.shadowRadius = 8
            layer.shadowOffset = .zero
        }
        borderView.autoresizingMask = [.width, .height]
        window.contentView = borderView
        
        overlayWindow = window
        return window
    }
    
    /// Shows the outline around the given window, or hides it if the window cannot be outlined
    /// (minimized, hidden, on another Space, or feature disabled in the settings).
    public func show(for model: WindowModel?) {
        guard PreferencesManager.shared.highlightSelectedWindow,
              let model = model,
              !model.isMinimized,
              !model.isHidden,
              model.isOnActiveSpace,
              model.bounds.width > 0, model.bounds.height > 0,
              let primaryScreen = NSScreen.screens.first else {
            hide()
            return
        }
        
        // Avoid redundant repositioning (e.g. when only thumbnails were updated)
        if currentWindowID == model.id, overlayWindow?.isVisible == true {
            return
        }
        currentWindowID = model.id
        
        let cgBounds = model.bounds
        let cocoaRect = NSRect(
            x: cgBounds.origin.x,
            y: primaryScreen.frame.height - cgBounds.origin.y - cgBounds.height,
            width: cgBounds.width,
            height: cgBounds.height
        ).insetBy(dx: -outset, dy: -outset)
        
        let window = ensureWindow()
        // Refresh accent color in case the user changed it in System Settings
        window.contentView?.layer?.borderColor = NSColor.controlAccentColor.cgColor
        window.contentView?.layer?.shadowColor = NSColor.controlAccentColor.cgColor
        window.setFrame(cocoaRect, display: true)
        window.orderFrontRegardless()
    }
    
    public func hide() {
        currentWindowID = nil
        overlayWindow?.orderOut(nil)
    }
}
