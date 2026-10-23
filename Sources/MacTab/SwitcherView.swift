import SwiftUI

public class SwitcherViewModel: ObservableObject {
    @Published public var windows: [WindowModel] = []
    @Published public var selectedIndex: Int = 0
    @Published public var previewWindow: WindowModel? = nil
    @Published public var hoveredIndex: Int? = nil
    
    public init() {}
    
    public func setWindows(_ newWindows: [WindowModel]) {
        self.windows = newWindows
        // Default selection: If there are 2 or more windows, select the 2nd one (index 1)
        // because index 0 is the currently active window, mimicking standard Alt-Tab behavior!
        if newWindows.count > 1 {
            self.selectedIndex = 1
        } else {
            self.selectedIndex = 0
        }
        self.previewWindow = nil
        self.hoveredIndex = nil
        
        // Trigger thumbnail loading for each window
        loadThumbnails()
    }
    
    private func loadThumbnails() {
        for index in 0..<windows.count {
            let winId = windows[index].id
            let bounds = windows[index].bounds
            ThumbnailEngine.shared.captureThumbnail(for: winId, bounds: bounds) { [weak self] image in
                guard let self = self else { return }
                if let img = image, index < self.windows.count && self.windows[index].id == winId {
                    self.windows[index].thumbnail = img
                    self.windows[index].thumbnailLoaded = true
                }
            }
        }
    }
    
    public func selectNext() {
        guard !windows.isEmpty else { return }
        hoveredIndex = nil
        selectedIndex = (selectedIndex + 1) % windows.count
    }
    
    public func selectPrevious() {
        guard !windows.isEmpty else { return }
        hoveredIndex = nil
        selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
    }
    
    public func moveUp() {
        guard !windows.isEmpty else { return }
        hoveredIndex = nil
        let columns = min(4, windows.count)
        if selectedIndex - columns >= 0 {
            selectedIndex -= columns
        } else {
            // Wrap to bottom row in the same column
            var target = selectedIndex
            while target + columns < windows.count {
                target += columns
            }
            selectedIndex = target
        }
    }
    
    public func moveDown() {
        guard !windows.isEmpty else { return }
        hoveredIndex = nil
        let columns = min(4, windows.count)
        if selectedIndex + columns < windows.count {
            selectedIndex += columns
        } else {
            // Wrap to top row in the same column
            selectedIndex = selectedIndex % columns
        }
    }
    
    public func selectIndex(_ index: Int) {
        guard index >= 0 && index < windows.count else { return }
        hoveredIndex = nil
        selectedIndex = index
    }
    
    public func selectByNumber(_ number: Int) {
        let targetIndex = number - 1
        if targetIndex >= 0 && targetIndex < windows.count {
            hoveredIndex = nil
            selectedIndex = targetIndex
        }
    }
    
    public func getSelectedWindow() -> WindowModel? {
        guard selectedIndex >= 0 && selectedIndex < windows.count else { return nil }
        return windows[selectedIndex]
    }
    
    public func closeCurrent() {
        guard let win = getSelectedWindow() else { return }
        WindowEngine.shared.closeWindow(win)
        windows.remove(at: selectedIndex)
        if selectedIndex >= windows.count {
            selectedIndex = max(0, windows.count - 1)
        }
    }
    
    public func minimizeCurrent() {
        guard let win = getSelectedWindow() else { return }
        WindowEngine.shared.minimizeWindow(win)
    }
    
    public func hideCurrent() {
        guard let win = getSelectedWindow() else { return }
        WindowEngine.shared.hideApplication(win)
    }
    
    public func togglePreview() {
        if previewWindow != nil {
            previewWindow = nil
        } else {
            previewWindow = getSelectedWindow()
        }
    }
}

public struct SwitcherView: View {
    @ObservedObject var viewModel: SwitcherViewModel
    var onSelectAndClose: ((WindowModel) -> Void)?
    
    // Exactly 4 columns per row for multiple windows, or fewer if count < 4
    private var gridColumns: [GridItem] {
        let count = min(4, max(1, viewModel.windows.count))
        return Array(repeating: GridItem(.fixed(220), spacing: 14), count: count)
    }
    
    public init(viewModel: SwitcherViewModel, onSelectAndClose: ((WindowModel) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSelectAndClose = onSelectAndClose
    }
    
    public var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 25, x: 0, y: 12)
            
            VStack(spacing: 0) {
                if viewModel.windows.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Keine offenen Fenster gefunden")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 320, height: 160)
                } else {
                    // Window Tiles Grid (Max 4 columns per row, then line break)
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: viewModel.windows.count > 8) {
                            LazyVGrid(columns: gridColumns, alignment: .center, spacing: 14) {
                                ForEach(0..<viewModel.windows.count, id: \.self) { index in
                                    WindowCardView(
                                        window: viewModel.windows[index],
                                        index: index + 1,
                                        isSelected: viewModel.selectedIndex == index,
                                        isHovered: viewModel.hoveredIndex == index,
                                        onClose: {
                                            viewModel.selectIndex(index)
                                            viewModel.closeCurrent()
                                        }
                                    )
                                    .id(index)
                                    .onTapGesture {
                                        viewModel.selectIndex(index)
                                        if let target = viewModel.getSelectedWindow() {
                                            onSelectAndClose?(target)
                                        }
                                    }
                                    .onHover { isHovered in
                                        if isHovered {
                                            viewModel.hoveredIndex = index
                                        } else if viewModel.hoveredIndex == index {
                                            viewModel.hoveredIndex = nil
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                        }
                        .scrollDisabled(viewModel.windows.count <= 8)
                        .frame(maxHeight: 640)
                        .onChange(of: viewModel.selectedIndex) { newIndex in
                            if viewModel.windows.count > 8 {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    proxy.scrollTo(newIndex, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            
            // Small discreet help icon in bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    LegendHelpButton()
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 12)
        }
        .padding(10)
    }
}

struct WindowCardView: View {
    let window: WindowModel
    let index: Int
    let isSelected: Bool
    let isHovered: Bool
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Preview thumbnail container
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Color.black.opacity(0.3)
                    
                    if let thumb = window.thumbnail {
                        Image(nsImage: thumb)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let icon = window.appIcon {
                        // Fallback icon placeholder
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 56, height: 56)
                            .opacity(0.7)
                    } else {
                        Image(systemName: "macwindow")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                    
                    if window.isMinimized {
                        VStack {
                            Spacer()
                            HStack {
                                Label("Minimiert", systemImage: "minus.circle.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow.opacity(0.85))
                                    .foregroundColor(.black)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(6)
                        }
                    } else if window.isHidden {
                        VStack {
                            Spacer()
                            HStack {
                                Label("Ausgeblendet", systemImage: "eye.slash.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.85))
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                Spacer()
                            }
                            .padding(6)
                        }
                    }
                }
                .frame(width: 220, height: 135)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Top-left App Icon Badge
                VStack {
                    HStack {
                        if let icon = window.appIcon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 26, height: 26)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                                .padding(6)
                        }
                        Spacer()
                    }
                    Spacer()
                }
                
                // Top-right Number Badge / Close Button on hover
                HStack(spacing: 4) {
                    if isHovered {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, height: 20)
                                .background(Color.red.opacity(0.85))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if index <= 9 {
                        Text("\(index)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(6)
            }
            
            // Window & App Title (fixed height prevents vertical shifting or layout jump)
            VStack(alignment: .leading, spacing: 2) {
                Text(window.appName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Text(window.title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(width: 220, height: 34, alignment: .leading)
            .padding(.horizontal, 2)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.20) : (isHovered && !isSelected ? Color.white.opacity(0.08) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
                .shadow(color: isSelected ? Color.accentColor.opacity(0.6) : .clear, radius: 8, x: 0, y: 0)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.08), value: isSelected)
    }
}

struct LegendHelpButton: View {
    @State private var showPopover: Bool = false
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: { showPopover.toggle() }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(isHovered ? 0.9 : 0.45))
                .padding(6)
                .background(Circle().fill(Color.white.opacity(isHovered ? 0.12 : 0.05)))
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
        .help("Tastatur-Kurzbefehle anzeigen")
        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tastatur-Kurzbefehle")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.bottom, 2)
                
                Group {
                    ShortcutRow(shortcut: "⇥ / ⇧⇥", label: "Nächstes / vorheriges Fenster")
                    ShortcutRow(shortcut: "↑ / ↓ / ← / →", label: "Zeilen- & Spalten-Navigation")
                    ShortcutRow(shortcut: "1 – 9", label: "Direktsprung zu Fenster 1–9")
                    ShortcutRow(shortcut: "W / ⌫", label: "Fenster schließen")
                    ShortcutRow(shortcut: "M", label: "Fenster minimieren")
                    ShortcutRow(shortcut: "H", label: "App ausblenden")
                    ShortcutRow(shortcut: "Leertaste", label: "Vorschau (Quick Look)")
                    ShortcutRow(shortcut: "Esc", label: "Abbrechen")
                }
                
                Divider()
                Text("Modifier loslassen (⌥) zum Umschalten.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .frame(width: 280)
        }
    }
}

struct ShortcutRow: View {
    let shortcut: String
    let label: String
    
    var body: some View {
        HStack {
            Text(shortcut)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            Spacer()
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
