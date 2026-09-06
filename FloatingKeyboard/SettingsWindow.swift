import SwiftUI
import UniformTypeIdentifiers

struct SettingsWindow: View {
    @Bindable var viewModel: KeyboardViewModel
    @State private var currentRotationText: String = "Current: 0°"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Horizontal Style Selector
            HorizontalThemePicker(viewModel: viewModel)
                .padding(.bottom, 2)
            
            Divider()

            Form {
                Toggle("Lock Position (Prevent Dragging)", isOn: $viewModel.isPositionLocked)
                Toggle("Enable Sound", isOn: $viewModel.soundEnabled)
                Toggle("Auto-Show in Text Fields", isOn: $viewModel.isAutoShowEnabled)
                Toggle("Tablet Mode (Bottom Dock)", isOn: $viewModel.isTabletModeEnabled)
                Toggle("Disable Internal Keyboard", isOn: $viewModel.isInternalKeyboardDisabled)
            }
            .padding(.bottom, 6)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Rotation")
                    .font(.headline)
                Text("Rotate the entire display 180° (useful for inverted setups)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Button("Toggle 180° Rotation") {
                        toggleDisplayRotation()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text(currentRotationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Excluded Applications")
                    .font(.headline)
                Text("The keyboard will not automatically show in these apps.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                List {
                    ForEach(Array(viewModel.excludedApps.sorted()), id: \.self) { bundleId in
                        HStack {
                            Text(bundleId)
                            Spacer()
                            Button(role: .destructive) {
                                viewModel.removeExcludedApp(bundleId)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(minHeight: 150)
                .border(Color.secondary.opacity(0.2))
                
                HStack {
                    Spacer()
                    Button("Add Application...") {
                        selectApplication()
                    }
                }
            }
        }
        .padding()
        .frame(width: 450)
        .frame(minHeight: 400)
        .onAppear {
            updateRotationText()
        }
    }
    
    private func updateRotationText() {
        let rotation = DisplayRotationManager.shared.getCurrentRotation()
        currentRotationText = "Current: \(rotation.rawValue)°"
    }
    
    private func toggleDisplayRotation() {
        let success = DisplayRotationManager.shared.toggle180Rotation()
        if success {
            updateRotationText()
        } else {
            // Show error alert
            let alert = NSAlert()
            alert.messageText = "Rotation Failed"
            alert.informativeText = "Unable to rotate the display. This feature requires system-level access and may not work on all displays or macOS versions."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
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
