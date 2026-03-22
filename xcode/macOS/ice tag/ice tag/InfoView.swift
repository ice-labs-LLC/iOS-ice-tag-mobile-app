import SwiftUI

struct InfoView: View {
    var body: some View {
        ZStack {
            // Matching Blue and Red Liquid Background
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
                // App Icon Placeholder
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
                    
                    Text("Version 27.1")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }

                Text("Created by ice labs")
                    .font(.system(size: 16, weight: .bold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
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
        // Set the size of the Info Window
        .frame(width: 350, height: 450)
    }
}

#Preview {
    InfoView()
}
