//
//  AccessoriesView.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI
import HomeKit

struct AccessoriesView: View {
    @ObservedObject var homeManager: HomeKitManager

    var body: some View {
        List(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
            if accessory.services.contains(where: { $0.serviceType == HMServiceTypeLightbulb }) {
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
            }
            if accessory.services.contains(where: {$0.serviceType == HMServiceTypeSwitch}) {
                Button(action: {
                    toggleAccessoryPower(accessory)
                })
                {
                    Text("[HK] \(accessory.name)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            else {
                Text("Unsupported accessory: \(accessory.name)")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Accessories")
    }
    private func toggleAccessoryPower(_ accessory: HMAccessory) {
            guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb })
            else {
                return
            }
            
            if let powerState = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                powerState.readValue { error in
                    if let error = error {
                        print("Error reading power state: \(error.localizedDescription)")
                        return
                    }
                    
                    // Toggle power state based on the current state
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


