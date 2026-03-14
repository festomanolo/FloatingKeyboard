// KeyboardView.swift
// FloatingKeyboard — macOS 15+ · Swift 6
//
// All SwiftUI views in one file:
//   KeyboardContainerView  – frosted-glass shell + top toolbar
//   FullKeyboardView       – complete QWERTY/ANSI layout (5 rows)
//   NumpadView             – compact numeric keypad
//   KeyRowView             – proportional-width key row (via GeometryReader)
//   KeyButtonView          – individual key with press feedback
//   GlassKeyButtonStyle    – custom ButtonStyle for the glass key look
//   KeySpec                – value type describing one key
// ─────────────────────────────────────────────────────────────────────────────

import SwiftUI
import AppKit
import Combine
import Observation
import UniformTypeIdentifiers

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – KeySpec (data model for one key)
// ═══════════════════════════════════════════════════════════════════════════

struct KeySpec: Identifiable {
    enum Action {
        case character(CGKeyCode)   // normal printable key (respects shift)
        case fixed(CGKeyCode)       // fixed key: backspace, return, tab, esc …
        case shift                  // toggles shift modifier
        case capsLock               // toggles caps lock
        case modifier(CGKeyCode)    // stateless modifier tap: cmd, opt, ctrl
        case emojiPicker            // opens system emoji picker
    }

    let id        = UUID()
    let primary   : String          // label when un-shifted
    let secondary : String          // label when shifted (or Caps Lock on)
    let sfSymbol  : String?         // SF Symbols name to show instead of text
    let flex      : CGFloat         // relative key width (1.0 = one standard key)
    let action    : Action

    // ── Convenience: normal character key ───────────────────────────────────
    init(_ primary: String, _ secondary: String, keyCode: CGKeyCode, flex: CGFloat = 1) {
        self.primary  = primary
        self.secondary = secondary
        self.sfSymbol = nil
        self.flex     = flex
        self.action   = .character(keyCode)
    }

    // ── Convenience: special/fixed key ──────────────────────────────────────
    init(label: String, symbol: String? = nil, flex: CGFloat, action: Action) {
        self.primary   = label
        self.secondary = label
        self.sfSymbol  = symbol
        self.flex      = flex
        self.action    = action
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – QWERTY Key-layout tables
// ═══════════════════════════════════════════════════════════════════════════
// macOS virtual key codes (Carbon/HID, same since Mac OS X 10.0):
//   https://developer.apple.com/documentation/carbon/1klkb13_virtualkeys

private let kRowF: [KeySpec] = [
    .init(label: "F1",  flex: 1, action: .fixed(122)), .init(label: "F2",  flex: 1, action: .fixed(120)),
    .init(label: "F3",  flex: 1, action: .fixed(99)),  .init(label: "F4",  flex: 1, action: .fixed(118)),
    .init(label: "F5",  flex: 1, action: .fixed(96)),  .init(label: "F6",  flex: 1, action: .fixed(97)),
    .init(label: "F7",  flex: 1, action: .fixed(98)),  .init(label: "F8",  flex: 1, action: .fixed(100)),
    .init(label: "F9",  flex: 1, action: .fixed(101)), .init(label: "F10", flex: 1, action: .fixed(109)),
    .init(label: "F11", flex: 1, action: .fixed(103)), .init(label: "F12", flex: 1, action: .fixed(111))
]

private let kRow1: [KeySpec] = [
    .init("`", "~",  keyCode: 50),  .init("1", "!",  keyCode: 18),
    .init("2", "@",  keyCode: 19),  .init("3", "#",  keyCode: 20),
    .init("4", "$",  keyCode: 21),  .init("5", "%",  keyCode: 23),
    .init("6", "^",  keyCode: 22),  .init("7", "&",  keyCode: 26),
    .init("8", "*",  keyCode: 28),  .init("9", "(",  keyCode: 25),
    .init("0", ")",  keyCode: 29),  .init("-", "_",  keyCode: 27),
    .init("=", "+",  keyCode: 24),
    .init(label: "", symbol: "delete.backward.fill", flex: 1.7,
          action: .fixed(51)),
]

private let kRow2: [KeySpec] = [
    .init(label: "tab", symbol: "arrow.right.to.line", flex: 1.5, action: .fixed(48)),
    .init("q","Q", keyCode: 12), .init("w","W", keyCode: 13),
    .init("e","E", keyCode: 14), .init("r","R", keyCode: 15),
    .init("t","T", keyCode: 17), .init("y","Y", keyCode: 16),
    .init("u","U", keyCode: 32), .init("i","I", keyCode: 34),
    .init("o","O", keyCode: 31), .init("p","P", keyCode: 35),
    .init("[", "{", keyCode: 33), .init("]", "}", keyCode: 30),
    .init("\\","|", keyCode: 42),
]

private let kRow3: [KeySpec] = [
    .init(label: "caps", symbol: nil, flex: 1.8, action: .capsLock),
    .init("a","A", keyCode:  0), .init("s","S", keyCode:  1),
    .init("d","D", keyCode:  2), .init("f","F", keyCode:  3),
    .init("g","G", keyCode:  5), .init("h","H", keyCode:  4),
    .init("j","J", keyCode: 38), .init("k","K", keyCode: 40),
    .init("l","L", keyCode: 37), .init(";",":", keyCode: 41),
    .init("'","\"",keyCode: 39),
    .init(label: "", symbol: "return.left", flex: 2.1, action: .fixed(36)),
]

private let kRow4: [KeySpec] = [
    .init(label: "", symbol: "shift.fill", flex: 2.3, action: .shift),
    .init("z","Z", keyCode:  6), .init("x","X", keyCode:  7),
    .init("c","C", keyCode:  8), .init("v","V", keyCode:  9),
    .init("b","B", keyCode: 11), .init("n","N", keyCode: 45),
    .init("m","M", keyCode: 46), .init(",","<", keyCode: 43),
    .init(".",">" ,keyCode: 47), .init("/","?", keyCode: 44),
    .init(label: "", symbol: "shift.fill", flex: 2.3, action: .shift),
]

private let kRow5: [KeySpec] = [
    .init(label: "esc",   symbol: nil, flex: 1.2, action: .fixed(53)),
    .init(label: "ctrl",  symbol: nil, flex: 1.2, action: .modifier(59)),
    .init(label: "opt",   symbol: nil, flex: 1.2, action: .modifier(58)),
    .init(label: "⌘",     symbol: nil, flex: 1.3, action: .modifier(55)),
    .init(label: "space", symbol: nil, flex: 5.8, action: .fixed(49)),
    .init(label: "⌘",     symbol: nil, flex: 1.3, action: .modifier(55)),
    .init(label: "", symbol: "face.smiling", flex: 1.2, action: .emojiPicker),
    .init(label: "", symbol: "arrow.left",  flex: 1.0, action: .fixed(123)),
    .init(label: "", symbol: "arrow.down",  flex: 1.0, action: .fixed(125)),
    .init(label: "", symbol: "arrow.up",    flex: 1.0, action: .fixed(126)),
    .init(label: "", symbol: "arrow.right", flex: 1.0, action: .fixed(124)),
]

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – KeyboardContainerView  (glass shell + toolbar)
// ═══════════════════════════════════════════════════════════════════════════

struct KeyboardContainerView: View {
    let viewModel: KeyboardViewModel
    @State private var isAXTrusted = AXIsProcessTrusted()
    @State private var isDockButtonPressed = false
    
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            glassBackground
            VStack(spacing: 0) {
                if !isAXTrusted {
                    Text("⚠️ Accessibility Permissions Required! Please enable in System Settings.")
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                        .padding(.top, 8)
                        .onTapGesture {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                }
                
                topBar
                    .padding(.horizontal, 16)
                    .padding(.top, 24) // Added padding to push content below traffic lights
                    .padding(.bottom, 4)
                    
                DragHandleView()

                Divider().opacity(0.25)

                ZStack {
                    // MARK: - Live Background Layer
                    if viewModel.theme == .fire {
                        LiveFireBackground()
                    } else if viewModel.theme == .neon {
                        ReactiveNeonBackground()
                    } else if viewModel.theme == .thunder {
                        ThunderRainBackground(viewModel: viewModel)
                    }
                    
                    // MARK: - Shockwave Animation Layer
                    ShockwaveLayer(viewModel: viewModel)
                    
                    HStack(spacing: 0) {
                        layoutContent
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(x: (viewModel.isSettingsVisible || viewModel.isClipboardVisible || viewModel.isAboutVisible) ? 0.95 : 1.0, anchor: .leading)
                            .offset(x: viewModel.isLightningActive ? CGFloat.random(in: -4...4) : 0,
                                   y: viewModel.isLightningActive ? CGFloat.random(in: -4...4) : 0)
                            .animation(.interactiveSpring(response: 0.1, dampingFraction: 0.2), value: viewModel.isLightningActive)
                        
                        if viewModel.isSettingsVisible {
                            Divider()
                            InlineSettingsView(viewModel: viewModel)
                                .frame(width: max(280, 280))
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else if viewModel.isClipboardVisible {
                            Divider()
                            InlineClipboardView(viewModel: viewModel)
                                .frame(width: 420) 
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else if viewModel.isAboutVisible {
                            Divider()
                            InlineAboutView(viewModel: viewModel)
                                .frame(width: 380)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isSettingsVisible)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isClipboardVisible)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isAboutVisible)
                }
            }
        }
        // Apply the opacity the user set with the slider.
        .opacity(viewModel.opacity)
        // ── Swipe down → hide ──────────────────────────────────────────────
        .gesture(
            DragGesture(minimumDistance: 40, coordinateSpace: .local)
                .onEnded { value in
                    guard value.translation.height > 55 else { return }
                    AppDelegate.shared?.keyboardPanel?.hide()
                }
        )
        .onReceive(timer) { _ in
            isAXTrusted = AXIsProcessTrusted()
        }
    }

    // MARK: Glass layers

    @ViewBuilder
    private var glassBackground: some View {
        if viewModel.theme == .neon {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(colors: [.cyan, .purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                        .blur(radius: 4)
                )
        } else if viewModel.theme == .fire {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(colors: [Color(red: 0.2, green: 0, blue: 0), Color(red: 0.4, green: 0.1, blue: 0)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(colors: [.orange, .red, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 2
                        )
                )
        } else if viewModel.theme == .thunder {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(colors: [Color(red: 0.05, green: 0.05, blue: 0.15), Color(red: 0.1, green: 0.1, blue: 0.25)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3), .blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
            // Subtle gradient shimmer on the border
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.30), .white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }


    // MARK: Top toolbar

    private var topBar: some View {
        HStack(spacing: 10) {
            // ── Layout switcher (Safari-style Pill) ────────────────────────
            HStack(spacing: 0) {
                Picker("Layout", selection: Binding(
                    get: { viewModel.layout },
                    set: { viewModel.layout = $0 }
                )) {
                    ForEach(KeyboardLayout.allCases) { l in
                        Text(l.rawValue).tag(l)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
                .labelsHidden()
            }
            .padding(4)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
            
            Spacer()
            
            // ── System Controls Group ──────────────────────────────────────
            HStack(spacing: 8) {
                // Volume Control (Wider)
                PillSlider(icon: volumeIcon, value: $volume, color: .blue, width: 140) {
                    setSystemVolume(volume)
                }
                
                // Brightness Control (Wider)
                PillSlider(icon: "sun.max.fill", value: $brightness, color: .orange, width: 140) {
                    setSystemBrightness(brightness)
                }

                // Opacity slider (Wider)
                PillSlider(icon: "circle.dotted", value: Binding(
                    get: { viewModel.opacity },
                    set: { viewModel.opacity = $0 }
                ), color: .secondary, width: 140, range: 0.25...1.0) { }
            }
            
            Spacer()

            // ── Actions Group (Safari-style Pill) ──────────────────────────
            HStack(spacing: 12) {
                // Dock Toggle
                Button {
                    viewModel.toggleSystemDock()
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                        isDockButtonPressed = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                            isDockButtonPressed = false
                        }
                    }
                } label: {
                    Image(systemName: "menubar.dock.rectangle")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(topBarForeground)
                        .scaleEffect(isDockButtonPressed ? 1.3 : 1.0)
                }
                .buttonStyle(.plain)
                .help("Toggle Dock Visibility")

                // About button
                Button {
                    withAnimation {
                        viewModel.isAboutVisible.toggle()
                    }
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(viewModel.isAboutVisible ? Color.accentColor : topBarForeground)
                }
                .buttonStyle(.plain)
                .help("About")

                // Clipboard button
                Button {
                    withAnimation {
                        viewModel.isClipboardVisible.toggle()
                    }
                } label: {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(viewModel.isClipboardVisible ? Color.accentColor : topBarForeground)
                }
                .buttonStyle(.plain)
                .help("Clipboard History")

                // Settings button
                Button {
                    withAnimation {
                        viewModel.isSettingsVisible.toggle()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(viewModel.isSettingsVisible ? Color.accentColor : topBarForeground)
                }
                .buttonStyle(.plain)
                .help("Settings")

                Divider().frame(height: 16).padding(.horizontal, 2)

                // Hide button
                Button {
                    AppDelegate.shared?.keyboardPanel?.hide()
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(topBarForeground)
                }
                .buttonStyle(.plain)
                .help("Hide")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.primary.opacity(0.06)))
        }
        .onAppear {
            volume = getSystemVolume()
            brightness = getSystemBrightness()
        }
    }
    
    private var topBarForeground: Color {
        viewModel.theme.adaptiveForeground.opacity(0.7)
    }
    
    @State private var volume: Double = 0.5
    @State private var brightness: Double = 0.7
    
    private var volumeIcon: String {
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
    
    private func getSystemVolume() -> Double {
        let script = "output volume of (get volume settings)"
        if let result = viewModel.runAppleScript(script), let vol = Double(result) {
            return vol / 100.0
        }
        return 0.5
    }
    
    private func setSystemVolume(_ value: Double) {
        let volume = Int(value * 100)
        let script = "set volume output volume \(volume)"
        _ = viewModel.runAppleScript(script)
    }
    
    private func getSystemBrightness() -> Double {
        return Double(viewModel.getBrightness())
    }
    
    private func setSystemBrightness(_ value: Double) {
        viewModel.setBrightness(Float(value))
    }
    

    @State private var isShowingClipboard = false

    // MARK: Layout content

    @ViewBuilder
    private var layoutContent: some View {
        switch viewModel.layout {
        case .full:   FullKeyboardView(viewModel: viewModel)
        case .numpad: NumpadView(viewModel: viewModel)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – CompactSlider (Volume & Brightness)
// ═══════════════════════════════════════════════════════════════════════════

struct CompactSlider: View {
    let icon: String
    @Binding var value: Double
    let color: Color
    let width: CGFloat
    let onChange: () -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 4) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 16)
            
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 3)
                    
                    // Active track
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * value, height: 3)
                    
                    // Thumb
                    Circle()
                        .fill(color)
                        .frame(width: isDragging ? 10 : 8, height: isDragging ? 10 : 8)
                        .shadow(color: color.opacity(0.4), radius: isDragging ? 4 : 2)
                        .offset(x: geometry.size.width * value - (isDragging ? 5 : 4))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            isDragging = true
                            let newValue = min(max(gesture.location.x / geometry.size.width, 0), 1)
                            value = newValue
                            onChange()
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 16)
        }
        .frame(width: width)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isDragging)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – DragHandleView
// ═══════════════════════════════════════════════════════════════════════════

struct DragHandleView: View {
    @State private var isHovered = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(Color.primary.opacity(isHovered ? 0.45 : 0.25))
            .frame(width: 36, height: 3)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
            .padding(.bottom, 4)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – CompactSlider (Volume & Brightness)
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – FullKeyboardView
// ═══════════════════════════════════════════════════════════════════════════

struct FullKeyboardView: View {
    let viewModel: KeyboardViewModel

    var body: some View {
        VStack(spacing: 4) {
            KeyRowView(keys: kRowF, viewModel: viewModel)
            KeyRowView(keys: kRow1, viewModel: viewModel)
            KeyRowView(keys: kRow2, viewModel: viewModel)
            KeyRowView(keys: kRow3, viewModel: viewModel)
            KeyRowView(keys: kRow4, viewModel: viewModel)
            KeyRowView(keys: kRow5, viewModel: viewModel)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – NumpadView
// ═══════════════════════════════════════════════════════════════════════════
// Numpad virtual key codes (kVK_ANSI_Keypad*):
//   7=89  8=91  9=92  4=86  5=87  6=88  1=83  2=84  3=85  0=82  .=65  Enter=76

private let kNumpadRows: [[KeySpec]] = [
    [
        .init(label: "esc", symbol: nil, flex: 1, action: .fixed(53)),
        .init(label: "", symbol: "delete.backward.fill", flex: 1, action: .fixed(51)),
        .init(label: "", symbol: "return.left",          flex: 1, action: .fixed(76)),
    ],
    [ .init("7","7",keyCode:89), .init("8","8",keyCode:91), .init("9","9",keyCode:92) ],
    [ .init("4","4",keyCode:86), .init("5","5",keyCode:87), .init("6","6",keyCode:88) ],
    [ .init("1","1",keyCode:83), .init("2","2",keyCode:84), .init("3","3",keyCode:85) ],
    [ .init("0","0",keyCode:82, flex:2),                    .init(".",".",keyCode:65)  ],
]

struct NumpadView: View {
    let viewModel: KeyboardViewModel

    var body: some View {
        VStack(spacing: 4) {
            ForEach(kNumpadRows.indices, id: \.self) { i in
                KeyRowView(keys: kNumpadRows[i], viewModel: viewModel)
            }
        }
        .frame(maxWidth: 260)
        .frame(maxWidth: .infinity)    // centre in wider windows
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – KeyRowView  (proportional-width row)
// ═══════════════════════════════════════════════════════════════════════════
// Uses GeometryReader to distribute the available width among keys according
// to each key's `flex` value, exactly like CSS flex-grow.

struct KeyRowView: View {
    let keys     : [KeySpec]
    let viewModel: KeyboardViewModel
    private let spacing: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            let totalFlex  = keys.map(\.flex).reduce(0, +)
            let totalGaps  = spacing * CGFloat(max(keys.count - 1, 0))
            let available  = geo.size.width - totalGaps
            let unitWidth  = available / totalFlex

            HStack(spacing: spacing) {
                ForEach(keys) { key in
                    KeyButtonView(
                        key: key,
                        viewModel: viewModel,
                        width: unitWidth * key.flex,
                        height: geo.size.height
                    )
                }
            }
        }
        .frame(height: 38)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – KeyButtonView
// ═══════════════════════════════════════════════════════════════════════════

struct KeyButtonView: View {
    let key      : KeySpec
    let viewModel: KeyboardViewModel
    let width    : CGFloat
    let height   : CGFloat

    @State private var isPressingDown = false
    @State private var isShowingAlternates = false
    @State private var isDisabled = false
    @State private var shakeOffset: CGSize = .zero
    @State private var warpOffset: CGSize = .zero
    @State private var warpScale: CGFloat = 1.0
    @State private var keyCenterInGlobal: CGPoint = .zero

    private var fontSize: CGFloat {
        let calculated = height * 0.36
        return min(max(calculated, 9), 22)
    }

    var body: some View {
        Button(action: {
            if !isShowingAlternates && !isDisabled {
                if viewModel.theme == .manolo {
                    triggerManoloEffect()
                }
                triggerKey()
            }
        }) {
            keyLabel
                .frame(width: width, height: height)
                .contentShape(Rectangle())
                .offset(shakeOffset)
        }
        .opacity(isDisabled ? 0.3 : 1.0)
        .buttonStyle(
            GlassKeyButtonStyle(isActive: isActive, theme: viewModel.theme)
        )
        .offset(warpOffset)
        .scaleEffect(warpScale)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { keyCenterInGlobal = CGPoint(x: geo.frame(in: .global).midX, y: geo.frame(in: .global).midY) }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        keyCenterInGlobal = CGPoint(x: newFrame.midX, y: newFrame.midY)
                    }
            }
        )
        .onChange(of: viewModel.shockwaveActive) { _, active in
            if active { startWarpAnimation() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShockwaveTriggered"))) { notification in
            if viewModel.theme == .manolo {
                applyBoundEffect()
            }
        }
        .contextMenu {
            if case .character(_) = key.action {
                Button("Copy Character") {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(displayText, forType: .string)
                }
            }
            Button("Show Key Code") {
                let alert = NSAlert()
                alert.messageText = "Key Code Information"
                if case .character(let kc) = key.action {
                    alert.informativeText = "Key code for \(displayText) is \(kc)"
                } else if case .fixed(let kc) = key.action {
                    alert.informativeText = "Key code is \(kc)"
                } else if case .modifier(let kc) = key.action {
                    alert.informativeText = "Key code is \(kc)"
                } else {
                    alert.informativeText = "No direct integer keycode."
                }
                alert.runModal()
            }
            Button(isDisabled ? "Enable Key" : "Disable Key") {
                isDisabled.toggle()
            }
        }
        .popover(isPresented: $isShowingAlternates) {
            if let alts = alternateCharacters[key.primary.lowercased()] {
                AlternateCharacterPicker(characters: alts) { selectedChar in
                    isShowingAlternates = false
                    sendUnicodeCharacter(selectedChar)
                }
            }
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    if alternateCharacters[key.primary.lowercased()] != nil {
                        isShowingAlternates = true
                    }
                }
        )
        .simultaneousGesture(                    // visual press state
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressingDown = true  }
                .onEnded   { _ in isPressingDown = false }
        )
    }
    
    // MARK: - Manolo Effects
    
    private func triggerManoloEffect() {
        // Trigger a global shockwave notification so all keys "bound"
        NotificationCenter.default.post(name: NSNotification.Name("ShockwaveTriggered"), object: nil)
        
        // Haptic feedback (not all Macs support this but it's good practice)
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
    
    private func applyBoundEffect() {
        let intensity: CGFloat = 8.0
        withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0)) {
            shakeOffset = CGSize(
                width: CGFloat.random(in: -intensity...intensity),
                height: CGFloat.random(in: -intensity...intensity)
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                shakeOffset = .zero
            }
        }
    }

    // MARK: Label

    @ViewBuilder
    private var keyLabel: some View {
        if let sym = key.sfSymbol {
            Image(systemName: sym)
                .font(.system(size: fontSize, weight: .medium))
                .foregroundStyle(viewModel.theme.keyForeground) // Ensure symbols use theme color
        } else {
            if shouldStackLabels {
                VStack(spacing: height * 0.02) {
                    Text(key.secondary)
                        .font(.system(size: fontSize * 0.70, weight: .medium, design: .rounded))
                        .foregroundStyle(viewModel.theme.keyForeground.opacity(viewModel.isUpperCase ? 1.0 : 0.4))
                    Text(key.primary)
                        .font(.system(size: fontSize, weight: viewModel.isUpperCase ? .regular : .semibold, design: .rounded))
                        .foregroundStyle(viewModel.theme.keyForeground.opacity(!viewModel.isUpperCase ? 1.0 : 0.4))
                }
            } else {
                let text = displayText
                Text(text)
                    .font(
                        .system(size: fontSize, weight: text.count == 1 ? .regular : .semibold, design: .rounded)
                    )
                    .foregroundStyle(viewModel.theme.keyForeground)
                    .shadow(color: .black.opacity(viewModel.theme.textShadow ? 0.5 : 0), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var shouldStackLabels: Bool {
        if case .character = key.action {
            let letters = CharacterSet.letters
            if let scalar = key.primary.unicodeScalars.first, letters.contains(scalar) {
                return false
            }
            return key.primary != key.secondary
        }
        return false
    }

    private var displayText: String {
        if case .character = key.action {
            return viewModel.isUpperCase ? key.secondary : key.primary
        }
        return key.primary
    }

    private var isActive: Bool {
        switch key.action {
        case .shift:    return viewModel.heldModifiers.contains(.shift)
        case .capsLock: return viewModel.isCapsLockActive
        default:        return false
        }
    }

    // MARK: Action

    private func triggerKey() {
        switch key.action {
        case .character(let kc): viewModel.pressCharacter(keyCode: kc)
        case .fixed(let kc):     viewModel.pressRaw(keyCode: kc)
        case .modifier(let kc):  viewModel.pressModifier(keyCode: kc)
        case .shift:             viewModel.toggleModifier(.shift)
        case .capsLock:          viewModel.toggleCapsLock()
        case .emojiPicker:
            KeyEventSender.shared.openEmojiPicker()
        }
    }
    
    private func sendUnicodeCharacter(_ char: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else { return }
        
        var uniChars = Array(char.utf16)
        keyDown.keyboardSetUnicodeString(stringLength: uniChars.count, unicodeString: &uniChars)
        keyUp.keyboardSetUnicodeString(stringLength: uniChars.count, unicodeString: &uniChars)
        
        keyDown.post(tap: .cgSessionEventTap)
        keyUp.post(tap: .cgSessionEventTap)
        
        if viewModel.shouldAutoReleaseModifier(.shift) {
            viewModel.heldModifiers.remove(.shift)
        }
    }
    
    // MARK: – Shockwave Refractive Warp
    
    private func startWarpAnimation() {
        let displayLink = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let now = Date().timeIntervalSinceReferenceDate
            let elapsed = now - viewModel.shockwaveStartTime
            
            // Increased duration to 1.8s
            if elapsed > 1.8 || !viewModel.shockwaveActive {
                timer.invalidate()
                withAnimation(.easeOut(duration: 0.15)) {
                    warpOffset = .zero
                    warpScale = 1.0
                }
                return
            }
            
            let origin = viewModel.shockwaveOrigin
            let dx = keyCenterInGlobal.x - origin.x
            let dy = keyCenterInGlobal.y - origin.y
            let distance = sqrt(dx * dx + dy * dy)
            
            let speed: CGFloat = 1800.0 // slightly faster
            let damping: CGFloat = 2.0 // less damping, carries further
            let frequency: CGFloat = 25.0 // slightly wider waves
            
            let waveFront = speed * elapsed
            let distFromWave = abs(distance - waveFront)
            
            // Widened the interaction threshold so keys feel it longer
            guard distFromWave < 250 else {
                warpOffset = .zero
                warpScale = 1.0
                return
            }
            
            let falloff = exp(-damping * elapsed) * (1.0 - distFromWave / 250.0)
            let phase = (distance / speed - elapsed) * frequency
            let amplitude = sin(Double(phase)) * falloff
            
            // Massively increased the visual displacement (18 -> 45)
            warpOffset = CGSize(
                width: (distance > 0 ? dx / distance : 0) * amplitude * 45,
                height: (distance > 0 ? dy / distance : 0) * amplitude * 45
            )
            // Increased scale warping (12% -> 25%)
            warpScale = 1.0 + amplitude * 0.25
        }
        RunLoop.main.add(displayLink, forMode: .common)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – AlternateCharacterPicker
// ═══════════════════════════════════════════════════════════════════════════

struct AlternateCharacterPicker: View {
    let characters: [String]
    let onSelect: (String) -> Void
    
    @State private var hoveredIndex: Int?
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(characters.enumerated()), id: \.offset) { index, char in
                Text(char)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .frame(width: 30, height: 38)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    .onHover { hovering in
                        if hovering { hoveredIndex = index }
                        else if hoveredIndex == index { hoveredIndex = nil }
                    }
                    .onTapGesture {
                        onSelect(char)
                    }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – ClipboardHistoryView
// ═══════════════════════════════════════════════════════════════════════════

struct ClipboardHistoryView: View {
    let viewModel: KeyboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard")
                    .font(.headline)
                Spacer()
                Button("Clear All") {
                    viewModel.clipboardItems.removeAll(where: { !$0.isPinned })
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .padding()
            .background(Color.secondary.opacity(0.05))

            if viewModel.clipboardItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No items copied")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.clipboardItems) { item in
                            HStack {
                                Button {
                                    ClipboardService.shared.copyToPasteboard(item.content)
                                    KeyEventSender.shared.sendKey(keyCode: 9, modifiers: [.command]) 
                                    dismiss()
                                } label: {
                                    Text(item.content)
                                        .lineLimit(2)
                                        .font(.system(.body, design: .monospaced))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                
                                Button {
                                    viewModel.togglePin(item: item)
                                } label: {
                                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                        .foregroundStyle(item.isPinned ? Color.accentColor : .secondary)
                                }
                                .padding(.horizontal, 8)
                                .buttonStyle(.plain)
                                
                                Button {
                                    viewModel.removeClipboardItem(item: item)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary.opacity(0.5))
                                }
                                .padding(.trailing, 12)
                                .buttonStyle(.plain)
                            }
                            .background(Color.primary.opacity(0.03))
                            
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 350)
            }
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – InlineClipboardView
// ═══════════════════════════════════════════════════════════════════════════

struct InlineClipboardView: View {
    let viewModel: KeyboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clipboard")
                        .font(.headline)
                        .foregroundStyle(viewModel.theme.adaptiveForeground)
                    Text("\(viewModel.clipboardItems.count) items • Persisted")
                        .font(.caption2)
                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                }
                Spacer()
                Button {
                    withAnimation { viewModel.isClipboardVisible = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.primary.opacity(0.04))

            if viewModel.clipboardItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 48))
                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground.opacity(0.3))
                    Text("Everything you copy will appear here")
                        .font(.subheadline)
                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            viewModel.clipboardItems.removeAll(where: { !$0.isPinned })
                        }
                    }) {
                        Label("Clear Unpinned", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.red.opacity(0.8))
                    .padding(.trailing)
                    .padding(.vertical, 8)
                }
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.clipboardItems) { item in
                            ClipboardItemRow(viewModel: viewModel, item: item)
                                .padding(.horizontal, 8)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.05))
    }
}

struct ClipboardItemRow: View {
    let viewModel: KeyboardViewModel
    let item: ClipboardItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let appName = item.sourceApp {
                    Text(appName)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                }
                
                Text(relativeTime(from: item.timestamp))
                    .font(.caption2)
                    .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                
                Spacer()
                
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor)
                }
            }
            
            Button {
                ClipboardService.shared.copyToPasteboard(item.content)
                KeyEventSender.shared.sendKey(keyCode: 9, modifiers: [.command]) 
            } label: {
                Text(item.content)
                    .lineLimit(3)
                    .font(.system(.subheadline, design: .monospaced))
                    .multilineTextAlignment(.leading)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            
            HStack {
                Button {
                    viewModel.togglePin(item: item)
                } label: {
                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin")
                        .font(.caption2)
                }
                .foregroundStyle(item.isPinned ? Color.accentColor : Color.secondary)
                
                Spacer()
                
                Button {
                    viewModel.removeClipboardItem(item: item)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption2)
                }
                .foregroundStyle(Color.red.opacity(0.6))
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.03)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.isPinned ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – ThemeButton (with shockwave trigger)
// ═══════════════════════════════════════════════════════════════════════════

struct ThemeButton: View {
    let theme: KeyboardTheme
    @Bindable var viewModel: KeyboardViewModel
    @State private var buttonCenter: CGPoint = .zero
    
    var body: some View {
        Button {
            withAnimation {
                viewModel.theme = theme
            }
            if theme == .manolo {
                // Delay slightly so the theme switch animation doesn't swallow the shockwave effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.triggerShockwave(at: buttonCenter)
                }
            }
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(theme == .manolo ? Color.primary.opacity(0.1) : (theme.keyBackground ?? Color.gray.opacity(0.2)))
                    .frame(width: 44, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(viewModel.theme == theme ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .contentShape(Rectangle())
                Text(theme.rawValue)
                    .font(.caption2)
                    .foregroundStyle(viewModel.theme == theme ? viewModel.theme.adaptiveForeground : viewModel.theme.adaptiveSecondaryForeground)
            }
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        let frame = geo.frame(in: .global)
                        buttonCenter = CGPoint(x: frame.midX, y: frame.midY)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        buttonCenter = CGPoint(x: newFrame.midX, y: newFrame.midY)
                    }
            }
        )
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – InlineSettingsView
// ═══════════════════════════════════════════════════════════════════════════


struct InlineSettingsView: View {
    @Bindable var viewModel: KeyboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.headline)
                    .foregroundStyle(viewModel.theme.adaptiveForeground)
                Spacer()
                Button {
                    withAnimation { viewModel.isSettingsVisible = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("AESTHETICS").font(.caption).foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(KeyboardTheme.allCases) { theme in
                                    ThemeButton(theme: theme, viewModel: viewModel)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Divider()
                    
                    Group {
                        Text("FEATURES").font(.caption).foregroundStyle(Color.secondary)
                        Toggle("Click Sounds", isOn: $viewModel.soundEnabled)
                        
                        if viewModel.soundEnabled {
                            Picker("Sound Profile", selection: $viewModel.selectedSoundProfile) {
                                ForEach(SoundProfile.allCases) { profile in
                                    Text(profile.rawValue).tag(profile)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding(.leading, 8)
                        }
                        
                        Toggle("Auto-Show", isOn: $viewModel.isAutoShowEnabled)
                        Toggle("Tablet Mode", isOn: $viewModel.isTabletModeEnabled)
                        Toggle("Suppress Internal", isOn: $viewModel.isInternalKeyboardDisabled)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.accentColor))
                    .foregroundStyle(Color.primary)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("EXCLUDED APPS").font(.caption).foregroundStyle(Color.secondary)
                        ForEach(Array(viewModel.excludedApps.sorted()), id: \.self) { bundleId in
                            HStack {
                                Text(bundleId).font(.caption).lineLimit(1).foregroundStyle(Color.primary)
                                Spacer()
                                Button { viewModel.removeExcludedApp(bundleId) } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(Color.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button("+ Add App...") {
                            selectApplication()
                        }
                        .font(.caption).buttonStyle(.borderless)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.02))
    }
    
    private func selectApplication() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url), let bundleId = bundle.bundleIdentifier {
                viewModel.addExcludedApp(bundleId)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – InlineAboutView (Thunder Effect Profile)
// ═══════════════════════════════════════════════════════════════════════════

struct InlineAboutView: View {
    @Bindable var viewModel: KeyboardViewModel
    @State private var isCheckingUpdates = false
    @State private var updateMessage = ""
    
    var body: some View {
        ZStack {
            // Thunder background effect
            ThunderBackgroundEffect()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("About")
                        .font(.headline)
                        .foregroundStyle(viewModel.theme.adaptiveForeground)
                    Spacer()
                    Button {
                        withAnimation { viewModel.isAboutVisible = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section with Thunder Effect
                        ZStack {
                            // Animated thunder glow
                            ThunderGlowEffect()
                            
                            VStack(spacing: 16) {
                                // Avatar with lightning border
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.purple, Color.blue, Color.cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 110, height: 110)
                                    
                                    // Profile Image
                                    if let profileImg = NSImage(contentsOfFile: "/Users/festomanolo/Desktop/projects/Floatingkeyboard/FloatingKeyboard/festomanolo.jpeg") {
                                        Image(nsImage: profileImg)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.cyan, .blue],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    }
                                    
                                    // Lightning border overlay
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.yellow, Color.orange, Color.yellow],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                        .frame(width: 100, height: 100)
                                        .shadow(color: .yellow.opacity(0.6), radius: 20)
                                }
                                
                                // Name with electric effect
                                Text("festomanolo")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cyan, .blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .cyan.opacity(0.5), radius: 10)
                                
                                Text("Creator & Developer")
                                    .font(.subheadline)
                                    .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                            }
                            .padding(.vertical, 24)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.primary.opacity(0.03))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        
                        Divider()
                        
                        // App Info
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(icon: "keyboard.fill", title: "FloatingKeyboard", subtitle: "v1.0.0")
                            InfoRow(icon: "swift", title: "Built with", subtitle: "Swift 6 + SwiftUI")
                            InfoRow(icon: "apple.logo", title: "Platform", subtitle: "macOS 15+")
                        }
                        
                        Divider()
                        
                        // Links Section
                        VStack(spacing: 12) {
                            Button {
                                if let url = URL(string: "https://github.com/festomanolo") {
                                    NSWorkspace.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.title3)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.purple, .blue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("GitHub Profile")
                                            .font(.headline)
                                            .foregroundStyle(viewModel.theme.adaptiveForeground)
                                        Text("github.com/festomanolo")
                                            .font(.caption)
                                            .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                                }
                                .padding()
                                .background(viewModel.theme.adaptiveForeground.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            
                            Button {
                                checkForUpdates()
                            } label: {
                                HStack {
                                    if isCheckingUpdates {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.title3)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.green, .cyan],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Check for Updates")
                                            .font(.headline)
                                            .foregroundStyle(viewModel.theme.adaptiveForeground)
                                        if !updateMessage.isEmpty {
                                            Text(updateMessage)
                                                .font(.caption)
                                                .foregroundStyle(viewModel.theme.adaptiveSecondaryForeground)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.primary.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                            .disabled(isCheckingUpdates)
                        }
                        
                        Divider()
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("Made with ⚡️ and 💙")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("© 2026 festomanolo")
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func checkForUpdates() {
        isCheckingUpdates = true
        updateMessage = ""
        
        // Simulate update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCheckingUpdates = false
            updateMessage = "You're up to date! ✨"
            
            // Clear message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                updateMessage = ""
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
}

struct ThunderBackgroundEffect: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            
            Canvas { context, size in
                // Random lightning flashes
                if Int(now * 10) % 50 == 0 {
                    let path = createLightningPath(size: size, seed: now)
                    context.stroke(
                        path,
                        with: .color(.yellow.opacity(0.3)),
                        lineWidth: 2
                    )
                }
            }
        }
        .blur(radius: 8)
        .blendMode(.plusLighter)
    }
    
    private func createLightningPath(size: CGSize, seed: Double) -> Path {
        var path = Path()
        let startX = CGFloat.random(in: 0...size.width)
        path.move(to: CGPoint(x: startX, y: 0))
        
        var currentY: CGFloat = 0
        var currentX = startX
        
        while currentY < size.height {
            currentY += CGFloat.random(in: 20...40)
            currentX += CGFloat.random(in: -30...30)
            path.addLine(to: CGPoint(x: currentX, y: currentY))
        }
        
        return path
    }
}

struct ThunderGlowEffect: View {
    @State private var glowIntensity: Double = 0.3
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let pulse = sin(now * 3) * 0.2 + 0.3
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.yellow.opacity(pulse),
                            Color.orange.opacity(pulse * 0.5),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 40)
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – ShockwaveLayer
// ═══════════════════════════════════════════════════════════════════════════

struct ShockwaveLayer: View {
    @Bindable var viewModel: KeyboardViewModel
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation(minimumInterval: 0.016)) { timeline in
                Canvas { context, size in
                    guard viewModel.shockwaveActive else { return }
                    
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let elapsed = now - viewModel.shockwaveStartTime
                    if elapsed > 1.8 || elapsed < 0 { return }
                    
                    // Convert global origin to local Canvas space
                    let globalOrigin = viewModel.shockwaveOrigin
                    let localFrame = geo.frame(in: .global)
                    let origin = CGPoint(x: globalOrigin.x - localFrame.minX, y: globalOrigin.y - localFrame.minY)
                let speed: CGFloat = 1800.0 
                let dampingRatio: CGFloat = 2.0
                let frequency: CGFloat = 25.0
                
                let falloff = exp(-dampingRatio * elapsed)
                
                // Draw multiple high-frequency rings for "stone in water" effect
                for i in 0..<5 { // Increased from 4 to 5 rings
                    let travelDist = speed * elapsed - CGFloat(i) * 60.0 // More spaced out
                    if travelDist <= 0 { continue }
                    
                    // Boundary Reflection Reflection Formula (Subtle rebound)
                    var radius = travelDist
                    let maxR = max(size.width, size.height)
                    if radius > maxR {
                        radius = maxR - (radius - maxR) * 0.5 // Damped rebound
                    }
                    
                    if radius <= 0 { continue }
                    
                    let phase = (radius / speed - elapsed) * frequency
                    let amplitude = cos(Double(phase)) * falloff
                    
                    if amplitude > 0{
                        // Increased opacity for visibility
                        let opacity = Double(amplitude * 0.9)
                        var path = Path()
                        path.addEllipse(in: CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2))
                        
                        context.stroke(
                            path,
                            with: .color(.white.opacity(opacity)),
                            lineWidth: 4.0 * amplitude // Thicker rings
                        )
                    }
                }
            }
            }
            .allowsHitTesting(false)
            .blendMode(.plusLighter)
        }
    }
}

// Shockwave warp logic is now inside KeyButtonView.startWarpAnimation()

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – GlassKeyButtonStyle
// ═══════════════════════════════════════════════════════════════════════════

struct GlassKeyButtonStyle: ButtonStyle {
    var isActive: Bool
    var theme: KeyboardTheme

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed

        configuration.label
            .foregroundStyle(isActive ? Color.accentColor : theme.keyForeground)
            .background(keyBackground(pressed: pressed))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isActive
                            ? Color.accentColor.opacity(0.55)
                            : strokeColor(pressed: pressed),
                        lineWidth: strokeWidth(isActive: isActive)
                    )
            )
            .shadow(color: glowColor(pressed: pressed), radius: glowRadius(pressed: pressed))
            .scaleEffect(pressed ? 0.94 : 1)
            .shadow(color: theme == .glass ? .black.opacity(pressed ? 0.05 : 0.18) : .clear,
                    radius: pressed ? 1 : 3, y: pressed ? 0 : 1.5)
    }

    private func strokeColor(pressed: Bool) -> Color {
        if theme == .neon {
            return Color.cyan.opacity(pressed ? 0.8 : 0.4)
        } else if theme == .fire {
            return Color.orange.opacity(pressed ? 0.9 : 0.5)
        } else if theme == KeyboardTheme.manolo {
            return theme.keyForeground.opacity(0.3)
        } else {
            return Color.white.opacity(pressed ? 0.20 : 0.12)
        }
    }

    private func strokeWidth(isActive: Bool) -> CGFloat {
        if theme == .neon || theme == .fire {
            return 1.5
        }
        return theme.borderStyle && !isActive ? 1.0 : 0.75
    }

    private func glowColor(pressed: Bool) -> Color {
        if theme == .neon {
            return Color.cyan.opacity(pressed ? 0.6 : 0.3)
        } else if theme == .fire {
            return Color.red.opacity(pressed ? 0.5 : 0.2)
        }
        return .clear
    }

    private func glowRadius(pressed: Bool) -> CGFloat {
        if theme == .neon || theme == .fire {
            return pressed ? 8 : 4
        }
        return 0
    }

    @ViewBuilder
    private func keyBackground(pressed: Bool) -> some View {
        if isActive {
            Color.accentColor.opacity(0.20)
        } else if pressed {
            if let bg = theme.keyBackground {
                if theme == .manolo { bg } else { bg.opacity(0.5) }
            } else {
                Color(NSColor.selectedContentBackgroundColor).opacity(0.22)
            }
        } else {
            if let bg = theme.keyBackground {
                bg
            } else {
                Color(NSColor.controlBackgroundColor).opacity(0.30)
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – VisualEffectView (NSVisualEffectView wrapper)
// ═══════════════════════════════════════════════════════════════════════════

struct VisualEffectView: NSViewRepresentable {
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

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – LiveFireBackground (Animated Fire Effect)
// ═══════════════════════════════════════════════════════════════════════════

struct LiveFireBackground: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                // Create multiple flame layers
                for i in 0..<8 {
                    let offset = CGFloat(i) * 0.3
                    let phase = (now + Double(offset)).truncatingRemainder(dividingBy: 3.0)
                    
                    let path = createFlamePath(
                        size: size,
                        phase: CGFloat(phase),
                        offset: offset
                    )
                    
                    let opacity = 0.15 - (CGFloat(i) * 0.015)
                    let color = flameColor(for: i)
                    
                    context.fill(
                        path,
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
        .blur(radius: 20)
        .blendMode(.plusLighter)
    }
    
    private func createFlamePath(size: CGSize, phase: CGFloat, offset: CGFloat) -> Path {
        var path = Path()
        
        let waveHeight = size.height * 0.4
        let waveOffset = sin(phase * .pi * 2) * waveHeight
        
        path.move(to: CGPoint(x: 0, y: size.height))
        
        for x in stride(from: 0, through: size.width, by: 10) {
            let normalizedX = x / size.width
            let wave1 = sin((normalizedX + phase + offset) * .pi * 4) * 20
            let wave2 = cos((normalizedX + phase * 0.7) * .pi * 6) * 15
            let y = size.height - waveOffset - wave1 - wave2 - (size.height * 0.3)
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()
        
        return path
    }
    
    private func flameColor(for layer: Int) -> Color {
        switch layer {
        case 0...2:
            return .yellow
        case 3...5:
            return .orange
        default:
            return .red
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – ReactiveNeonBackground (Reactive Neon Effect)
// ═══════════════════════════════════════════════════════════════════════════

struct ReactiveNeonBackground: View {
    @State private var pulsePhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            let pulse = sin(now * 2) * 0.5 + 0.5
            
            ZStack {
                Color.black.opacity(0.8)
                
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.1 + pulse * 0.1),
                        Color.purple.opacity(0.1 + pulse * 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated grid lines
                Canvas { context, size in
                    let spacing: CGFloat = 40
                    let offset = (now.truncatingRemainder(dividingBy: 1.0)) * spacing
                    
                    for x in stride(from: -spacing + offset, through: size.width + spacing, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(.cyan.opacity(0.05)), lineWidth: 1)
                    }
                    
                    for y in stride(from: -spacing + offset, through: size.height + spacing, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(.purple.opacity(0.05)), lineWidth: 1)
                    }
                }
            }
        }
    }
}
// ═══════════════════════════════════════════════════════════════════════════
// MARK: – PillSlider
// ═══════════════════════════════════════════════════════════════════════════

struct PillSlider: View {
    let icon: String
    @Binding var value: Double
    let color: Color
    let width: CGFloat
    var range: ClosedRange<Double> = 0...1
    let onChange: () -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(isDragging ? .white : color)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                    
                    Capsule()
                        .fill(isDragging ? color : color.opacity(0.3))
                        .frame(width: geo.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            isDragging = true
                            let percent = v.location.x / geo.size.width
                            let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(min(max(percent, 0), 1))
                            value = newValue
                            onChange()
                        }
                        .onEnded { _ in isDragging = false }
                )
            }
            .frame(height: 18)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(width: width)
        .background(
            Capsule()
                .fill(isDragging ? Color.primary.opacity(0.2) : Color.primary.opacity(0.05))
        )
        .animation(.spring(response: 0.2), value: isDragging)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: – ThunderRainBackground
// ═══════════════════════════════════════════════════════════════════════════

struct ThunderRainBackground: View {
    let viewModel: KeyboardViewModel
    @State private var lightningOpacity: Double = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Rain animation
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    let now = timeline.date.timeIntervalSinceReferenceDate
                    let particleCount = 60
                    
                    for i in 0..<particleCount {
                        let x = CGFloat((Double(i) * 137.5).truncatingRemainder(dividingBy: Double(size.width)))
                        let speed = 600.0 + Double(i % 5) * 200.0 // Faster falling rain
                        let y = CGFloat((now * speed + Double(i * 20)).truncatingRemainder(dividingBy: Double(size.height)))
                        
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x - 1, y: y + 25)) // Longer, thinner droplets
                        
                        context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 1.5)
                    }
                }
            }
            
            // Lightning flash
            Rectangle()
                .fill(Color.white)
                .opacity(lightningOpacity)
                .blendMode(.plusLighter)
        }
        .onReceive(timer) { _ in
            if lightningOpacity > 0 {
                withAnimation(.easeOut(duration: 0.2)) {
                    lightningOpacity = 0
                }
            } else if Double.random(in: 0...100) < 2 {
                withAnimation(.easeInOut(duration: 0.05)) {
                    lightningOpacity = Double.random(in: 0.2...0.5)
                    viewModel.isLightningActive = true
                }
                
                // Reset strike after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    viewModel.isLightningActive = false
                }
            }
        }
    }
}
