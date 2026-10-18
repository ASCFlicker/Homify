//
//  HomeManager.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import HomeKit

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryDelegate {
    @Published var homeManager: HMHomeManager?
    @Published var isAuthorized = false
    @Published var accessories: [HMAccessory] = []
    @Published var services: [HMService] = []
    @Published private(set) var powerStates: [UUID: Bool] = [:]

    override init() {
        super.init()
        self.homeManager = HMHomeManager()
        self.homeManager?.delegate = self
    }

    // Delegate method to handle updates
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        // Access and manage devices
        guard let home = manager.homes.first else {
                print("No home found in HomeKit.")
                return
            }

        self.accessories = home.accessories
        self.isAuthorized = true
        home.accessories.forEach { $0.delegate = self }
        refreshPowerStates()

            // List each accessory in the home
        for accessory in home.accessories {
            print("Accessory name: \(accessory.name), is reachable: \(accessory.isReachable)")

            for service in accessory.services {
                print("  Service type: \(service.serviceType)")

                // Optionally, you can list characteristics for each service
                for characteristic in service.characteristics {
                    print("    Characteristic type: \(characteristic.characteristicType)")
                }
            }
        }
    }

    // HomeKit's cached characteristic values go stale, so read fresh ones and subscribe to changes.
    func refreshPowerStates() {
        for accessory in accessories {
            guard let powerState = accessory.powerState else { continue }
            powerState.enableNotification(true) { _ in }
            read(powerState, of: accessory)
        }
    }

    func isOn(_ accessory: HMAccessory) -> Bool {
        powerStates[accessory.uniqueIdentifier] ?? (accessory.powerState?.value as? Bool ?? false)
    }

    func toggle(_ accessory: HMAccessory) {
        guard let powerState = accessory.powerState else { return }
        let id = accessory.uniqueIdentifier
        let newValue = !isOn(accessory)
        powerStates[id] = newValue

        powerState.writeValue(newValue) { [weak self] error in
            guard let error else { return }
            print("Error toggling power state: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self?.powerStates[id] = !newValue
            }
        }
    }

    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        guard characteristic.characteristicType == HMCharacteristicTypePowerState,
              let isOn = characteristic.value as? Bool else { return }
        DispatchQueue.main.async {
            self.powerStates[accessory.uniqueIdentifier] = isOn
        }
    }

    func accessoryDidUpdateReachability(_ accessory: HMAccessory) {
        guard accessory.isReachable, let powerState = accessory.powerState else { return }
        read(powerState, of: accessory)
    }

    private func read(_ powerState: HMCharacteristic, of accessory: HMAccessory) {
        powerState.readValue { [weak self] error in
            if let error {
                print("Error reading power state for \(accessory.name): \(error.localizedDescription)")
                return
            }
            guard let isOn = powerState.value as? Bool else { return }
            DispatchQueue.main.async {
                self?.powerStates[accessory.uniqueIdentifier] = isOn
            }
        }
    }
}

extension HMAccessory {
    static let supportedPowerServiceTypes: [String] = [
        HMServiceTypeLightbulb,
        HMServiceTypeSwitch,
        HMServiceTypeOutlet,
    ]

    var powerService: HMService? {
        services.first { Self.supportedPowerServiceTypes.contains($0.serviceType) }
    }

    var powerState: HMCharacteristic? {
        powerService?.characteristics.first { $0.characteristicType == HMCharacteristicTypePowerState }
    }
}
