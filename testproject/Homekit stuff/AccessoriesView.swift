import SwiftUI
import HomeKit

struct AccessoriesView: View {
    @ObservedObject var homeManager: HomeKitManager

    var body: some View {
        List(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
            if isAccessorySupported(accessory) {
                Button(action: {
                    toggleAccessoryPower(accessory)
                }) {
                    Text("[HK] \(accessory.name)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            } else {
                Text("Unsupported accessory: \(accessory.name)")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Accessories")
    }

    // Check if the accessory is supported (lightbulb, switch, outlet, etc.)
    private func isAccessorySupported(_ accessory: HMAccessory) -> Bool {
        let supportedServiceTypes: [String] = [
            HMServiceTypeLightbulb,
            HMServiceTypeSwitch,
            HMServiceTypeOutlet // Add more service types as needed
        ]
        return accessory.services.contains { service in
            supportedServiceTypes.contains(service.serviceType)
        }
    }

    // Toggle power state for supported accessories
    private func toggleAccessoryPower(_ accessory: HMAccessory) {
        // Find the first supported service (lightbulb, switch, outlet, etc.)
        guard let service = accessory.services.first(where: { service in
            let supportedServiceTypes: [String] = [
                HMServiceTypeLightbulb,
                HMServiceTypeSwitch,
                HMServiceTypeOutlet // Add more service types as needed
            ]
            return supportedServiceTypes.contains(service.serviceType)
        }) else {
            return
        }

        // Find the power state characteristic
        if let powerState = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
            powerState.readValue { error in
                if let error = error {
                    print("Error reading power state: \(error.localizedDescription)")
                    return
                }

                // Toggle the power state
                if let currentState = powerState.value as? Bool {
                    powerState.writeValue(!currentState) { error in
                        if let error = error {
                            print("Error toggling power state: \(error.localizedDescription)")
                        } else {
                            print("Accessory \(accessory.name) turned \(currentState ? "off" : "on")")
                        }
                    }
                }
            }
        }
    }
}
