import SwiftUI
import UniformTypeIdentifiers

struct SettingsWindow: View {
    @Bindable var viewModel: KeyboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Form {
                Picker("Theme", selection: $viewModel.theme) {
                    ForEach(KeyboardTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                
                Toggle("Enable Sound", isOn: $viewModel.soundEnabled)
                Toggle("Auto-Show in Text Fields", isOn: $viewModel.isAutoShowEnabled)
                Toggle("Tablet Mode (Bottom Dock)", isOn: $viewModel.isTabletModeEnabled)
                Toggle("Disable Internal Keyboard", isOn: $viewModel.isInternalKeyboardDisabled)
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
