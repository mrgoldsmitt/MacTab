import Cocoa
import SwiftUI
import Combine

public class SwitcherWindowController: NSWindowController {
    public static let shared = SwitcherWindowController()
    
    private let viewModel = SwitcherViewModel()
    private var panel: NSPanel!
    private var isSwitcherShown: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let contentPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 260),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        contentPanel.level = .floating
        contentPanel.isOpaque = false
        contentPanel.backgroundColor = .clear
        contentPanel.hasShadow = true
        contentPanel.isMovableByWindowBackground = false
        contentPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        
        super.init(window: contentPanel)
        self.panel = contentPanel
        
        let switcherView = SwitcherView(viewModel: viewModel) { [weak self] selectedWindow in
            self?.dismissAndFocus(selectedWindow)
        }
        
        let hostingView = NSHostingView(rootView: switcherView)
        panel.contentView = hostingView
        
        // Keep the on-screen outline in sync with the current selection.
        // Note: @Published emits on willSet, so the new values are taken from the closure parameters.
        viewModel.$selectedIndex
            .combineLatest(viewModel.$windows)
            .receive(on: RunLoop.main)
            .sink { [weak self] index, windows in
                guard let self = self, self.isSwitcherShown else { return }
                let selected = (index >= 0 && index < windows.count) ? windows[index] : nil
                WindowHighlightOverlay.shared.show(for: selected)
            }
            .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show(with windows: [WindowModel]) {
        isSwitcherShown = true
        viewModel.setWindows(windows)
        
        // Find screen with cursor
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens[0]
        
        let screenFrame = targetScreen.visibleFrame
        
        // Calculate dimensions based on 4-column layout
        let count = windows.count
        let cols = min(4, max(1, count))
        let rows = max(1, (count + 3) / 4)
        
        // Card is 220 wide, spacing 14, horizontal padding 36 + panel margins
        let calculatedWidth = CGFloat(cols) * 220.0 + CGFloat(max(0, cols - 1)) * 14.0 + 56.0
        
        // Single row height: 187 card + 14 spacing + generous padding so titles never clip
        let singleRowHeight: CGFloat = 220.0
        let calculatedHeight = CGFloat(rows) * singleRowHeight + 50.0
        
        let finalWidth = min(max(calculatedWidth, 360), screenFrame.width - 60)
        let finalHeight = min(max(calculatedHeight, 270), min(screenFrame.height - 80, 720))
        
        let posX = screenFrame.origin.x + (screenFrame.width - finalWidth) / 2
        let posY = screenFrame.origin.y + (screenFrame.height - finalHeight) / 2
        
        panel.setFrame(NSRect(x: posX, y: posY, width: finalWidth, height: finalHeight), display: true)
        
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1.0
        }
        
        KeyboardHook.shared.isSwitcherVisible = true
    }
    
    public func dismiss() {
        KeyboardHook.shared.isSwitcherVisible = false
        isSwitcherShown = false
        WindowHighlightOverlay.shared.hide()
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.10
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
            ThumbnailEngine.shared.clearCache()
        })
    }
    
    public func dismissAndFocus(_ window: WindowModel) {
        dismiss()
        WindowEngine.shared.focusWindow(window)
    }
    
    public func selectNext() {
        viewModel.selectNext()
    }
    
    public func selectPrevious() {
        viewModel.selectPrevious()
    }
    
    public func moveUp() {
        viewModel.moveUp()
    }
    
    public func moveDown() {
        viewModel.moveDown()
    }
    
    public func selectByNumber(_ number: Int) {
        viewModel.selectByNumber(number)
    }
    
    public func closeCurrent() {
        viewModel.closeCurrent()
    }
    
    public func minimizeCurrent() {
        viewModel.minimizeCurrent()
    }
    
    public func hideCurrent() {
        viewModel.hideCurrent()
    }
    
    public func togglePreview() {
        viewModel.togglePreview()
    }
    
    public func focusSelected() {
        if let selected = viewModel.getSelectedWindow() {
            dismissAndFocus(selected)
        } else {
            dismiss()
        }
    }
}
