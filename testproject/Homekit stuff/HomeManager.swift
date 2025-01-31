//
//  HomeManager.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import HomeKit

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published var homeManager: HMHomeManager?
    @Published var isAuthorized = false
    @Published var accessories: [HMAccessory] = []
    @Published var services: [HMService] = []
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
    func toggleLightAccessory(_ accessory: HMAccessory, turnOn: Bool) {
        for service in accessory.services where service.serviceType == HMServiceTypeLightbulb {
            // Find the characteristic for power state
            if let powerState = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                powerState.writeValue(turnOn) { error in
                    if let error = error {
                        print("Error updating light state: \(error.localizedDescription)")
                    } else {
                        print("Light turned \(turnOn ? "on" : "off") successfully.")
                    }
                }
            }
        }
    }
    // Additional methods to control devices can go here
}
