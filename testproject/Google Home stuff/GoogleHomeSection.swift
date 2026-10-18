import SwiftUI

struct GoogleHomeSection: View {
    @ObservedObject var manager: GoogleHomeManager
    @ObservedObject var layout: DeviceLayoutStore
    let isSignedIn: Bool
    let signIn: () -> Void
    let onCustomize: () -> Void

    var body: some View {
        DeviceSection(title: "Google Home", systemImage: "house.fill") {
            VStack(alignment: .leading, spacing: 14) {
                content

                if let errorMessage = manager.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !isSignedIn {
            InfoCard(
                title: "Connect Google Home",
                message: "Sign in with Google to control the devices in your Google Home.",
                systemImage: "person.crop.circle.badge.plus"
            ) {
                Button("Sign In with Google", action: signIn)
                    .buttonStyle(.glassProminent)
            }
        } else if !manager.isConnected {
            InfoCard(
                title: "Show your Google devices",
                message: "Google will ask which home and devices Homify can control.",
                systemImage: "house.fill"
            ) {
                Button {
                    Task { await manager.connect() }
                } label: {
                    if manager.isConnecting {
                        ProgressView()
                    } else {
                        Text("Connect")
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(manager.isConnecting)
            }
        } else {
            connectedContent
        }
    }

    @ViewBuilder
    private var connectedContent: some View {
        HStack {
            Label(homeLabel, systemImage: "location.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    Button("Manage Access", systemImage: "key") {
                        manager.manageAccess()
                    }
                    Button("Reload", systemImage: "arrow.clockwise") {
                        Task { await manager.reload() }
                    }
                    .labelStyle(.iconOnly)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        }

        let visible = layout.visible(manager.devices, in: .googleHome, id: \.id)

        if !manager.hasLoadedDevices {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else if manager.devices.isEmpty {
            InfoCard(
                title: manager.homeNames.isEmpty ? "No home shared" : "No devices shared",
                message: manager.homeNames.isEmpty
                    ? "Choose a home to share with Homify."
                    : "Choose which devices Homify can control.",
                systemImage: manager.homeNames.isEmpty ? "house" : "lightbulb.slash"
            ) {
                Button("Manage Access") { manager.manageAccess() }
                    .buttonStyle(.glass)
            }
        } else if visible.isEmpty {
            InfoCard(
                title: "All devices hidden",
                message: "Choose which devices to show in Customize.",
                systemImage: "eye.slash"
            ) {
                Button("Customize", action: onCustomize)
                    .buttonStyle(.glass)
            }
        } else {
            DeviceGrid {
                ForEach(visible) { device in
                    DeviceTile(
                        name: device.name,
                        systemImage: device.kind.systemImage,
                        isOn: device.isOn,
                        isSupported: device.supportsOnOff
                    ) {
                        Task { await manager.toggle(device) }
                    }
                }
            }
        }
    }

    private var homeLabel: String {
        guard manager.hasLoadedHomes else { return "Loading…" }
        return manager.homeNames.isEmpty ? "No home shared" : manager.homeNames.joined(separator: ", ")
    }
}

extension GoogleHomeManager {
    var layoutItems: [LayoutItem] {
        devices.map {
            LayoutItem(id: $0.id, name: $0.name, systemImage: $0.kind.systemImage, isSupported: $0.supportsOnOff)
        }
    }
}
