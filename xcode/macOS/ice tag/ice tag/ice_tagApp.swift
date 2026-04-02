import SwiftUI

@main
struct ice_tag_app: App {
    @Environment(\.openWindow) private var openWindow
    @AppStorage("usesystemsettings") private var usesystemsettings = true
    @AppStorage("appearancemode") private var appearancemode = "light"
    
    // App-wide accent color
    @AppStorage("accentcolor") private var accentColorData: Data = try! NSKeyedArchiver.archivedData(withRootObject: NSColor.systemBlue, requiringSecureCoding: false)
    var accentColor: Color {
        if let nsColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(accentColorData) as? NSColor {
            return Color(nsColor)
        }
        return .blue
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 900, minHeight: 600)
                .accentColor(accentColor)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(action: { openWindow(id: "info") }) {
                    Label("About ice tag", systemImage: "info.circle")
                }
            }
            CommandGroup(after: .appTermination) {
                Button(action: { exit(0) }) {
                    Label("Force Quit", systemImage: "power")
                }
                .keyboardShortcut("q", modifiers: [.command, .option])
            }
        }

        Settings {
            VStack(alignment: .leading, spacing: 25) {
                // Appearance Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("APPEARANCE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $appearancemode) {
                        Text("Dark").tag("dark") // Swapped order
                        Text("Light").tag("light") // Swapped order
                    }
                    .pickerStyle(.segmented)
                    .accentColor(accentColor)
                    .disabled(usesystemsettings)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("ACCENT COLOR")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    ColorPicker("Accent Color", selection: Binding(
                        get: {
                            if let nsColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(accentColorData) as? NSColor {
                                return Color(nsColor)
                            }
                            return .blue
                        },
                        set: { newValue in
                            if let cgColor = newValue.cgColor,
                               let nsColor = NSColor(cgColor: cgColor),
                               let data = try? NSKeyedArchiver.archivedData(withRootObject: nsColor, requiringSecureCoding: false) {
                                accentColorData = data
                            }
                        }
                    ))
                    .labelsHidden()
                }
                
                Divider()
                
                // Native System Slider Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("SYSTEM")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    // This is the Native SDK "Liquid Glass" Slider
                    Toggle("Match System Settings", isOn: $usesystemsettings)
                        .toggleStyle(.switch)
                        .font(.system(size: 13, weight: .semibold))
                        .tint(accentColor) // Sets the "Liquid" color when ON
                }
            }
            .padding(30)
            .frame(width: 420, height: 300)
        }

        // Loads content from InfoView.swift
        Window("About ice tag", id: "info") {
            InfoView()
        }
        .windowResizability(.contentSize)
    }
}

