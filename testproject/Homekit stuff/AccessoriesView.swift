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
                        .background(isAccessoryOn(accessory) ? Color.yellow : Color.gray)
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

    private func isAccessoryOn(_ accessory: HMAccessory) -> Bool {
        guard let service = accessory.services.first(where: {
            $0.serviceType == HMServiceTypeOutlet ||
            $0.serviceType == HMServiceTypeSwitch ||
            $0.serviceType == HMServiceTypeLightbulb
        }) else {
            return false
        }

        if let powerState = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypePowerState
        }), let value = powerState.value as? Bool {
            return value
        }

        return false
    }

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

    private func toggleAccessoryPower(_ accessory: HMAccessory) {
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

        if let powerState = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
            powerState.readValue { error in
                if let error = error {
                    print("Error reading power state: \(error.localizedDescription)")
                    return
                }

                if let currentState = powerState.value as? Bool {
                    powerState.writeValue(!currentState) { error in
                        if let error = error {
                            print("Error toggling power state: \(error.localizedDescription)")
                        } else {
                            print("Accessory \(accessory.name) turned \(currentState ? "off" : "on")")
                            // Notify the homeManager that a change has occurred
                            self.homeManager.objectWillChange.send()
                        }
                    }
                }
            }
        }
    }
}
