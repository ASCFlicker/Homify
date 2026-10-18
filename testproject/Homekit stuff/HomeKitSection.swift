import SwiftUI
import HomeKit

struct HomeKitSection: View {
    @ObservedObject var homeManager: HomeKitManager
    @ObservedObject var layout: DeviceLayoutStore
    let onCustomize: () -> Void

    var body: some View {
        DeviceSection(title: "Apple Home", systemImage: "homekit") {
            let visible = layout.visible(homeManager.accessories, in: .appleHome, id: \.layoutID)

            if homeManager.accessories.isEmpty {
                InfoCard(
                    title: "No accessories yet",
                    message: "Lights, switches, and outlets you add in the Home app will show up here.",
                    systemImage: "house"
                )
            } else if visible.isEmpty {
                InfoCard(
                    title: "All accessories hidden",
                    message: "Choose which accessories to show in Customize.",
                    systemImage: "eye.slash"
                ) {
                    Button("Customize", action: onCustomize)
                        .buttonStyle(.glass)
                }
            } else {
                DeviceGrid {
                    ForEach(visible, id: \.uniqueIdentifier) { accessory in
                        DeviceTile(
                            name: accessory.name,
                            detail: accessory.room?.name,
                            systemImage: accessory.tileSystemImage,
                            isOn: homeManager.isOn(accessory),
                            isSupported: accessory.powerService != nil
                        ) {
                            homeManager.toggle(accessory)
                        }
                    }
                }
            }
        }
    }
}

extension HMAccessory {
    var layoutID: String { uniqueIdentifier.uuidString }

    var tileSystemImage: String {
        switch powerService?.serviceType {
        case HMServiceTypeLightbulb: "lightbulb"
        case HMServiceTypeOutlet: "powerplug"
        case HMServiceTypeSwitch: "switch.2"
        default: "square.dashed"
        }
    }
}

extension HomeKitManager {
    var layoutItems: [LayoutItem] {
        accessories.map {
            LayoutItem(
                id: $0.layoutID,
                name: $0.name,
                detail: $0.room?.name,
                systemImage: $0.tileSystemImage,
                isSupported: $0.powerService != nil
            )
        }
    }
}
