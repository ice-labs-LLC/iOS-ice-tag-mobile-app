import SwiftUI

struct InfoView: View {
    var body: some View {
        ZStack {
            // Helper to disable the minimize button
            WindowConfigurator()
                .frame(width: 0, height: 0)

            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                .blue, .red, .indigo,
                .purple, .blue, .red,
                .black, .red, .black
            ])
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "ice.cube.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.white)
                    .shadow(radius: 10)
                
                VStack(spacing: 5) {
                    Text("ice tag")
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(.white)
                    
                    Text("Version 27.4")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("Created by ice labs")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                    // Note: Ensure .glassEffect is defined in your project
                    .glassEffect(in: .capsule)

                Text("A high-speed browser for mods, levels, and community updates.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer()
                
                Text("© 2024-2026 ice labs")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
            .padding(.top, 40)
        }
        .frame(width: 350, height: 450)
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.styleMask.remove(.miniaturizable)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
