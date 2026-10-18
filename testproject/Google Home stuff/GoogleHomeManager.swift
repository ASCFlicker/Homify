//
//  GoogleHomeManager.swift
//  Homify2
//

import Foundation
import GoogleHomeSDK
import GoogleHomeTypes

private typealias OnOffTrait = GoogleHomeTypes.Matter.OnOffTrait

struct GoogleHomeDevice: Identifiable {
    let id: String
    let name: String
    var supportsOnOff: Bool
    var isOn: Bool
}

@MainActor
final class GoogleHomeManager: ObservableObject {
    @Published private(set) var devices: [GoogleHomeDevice] = []
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published var errorMessage: String?

    private var home: Home?
    private var homeDevices: Set<HomeDevice> = []
    private var onOffTraits: [String: OnOffTrait] = [:]
    private var deviceListTask: Task<Void, Never>?
    private var deviceTypeTasks: [String: Task<Void, Never>] = [:]

    // DeviceTypeCollection can't be enumerated, so probe the types that carry an OnOff trait.
    private static let onOffDeviceTypes: [any DeviceType.Type] = [
        OnOffLightDeviceType.self,
        DimmableLightDeviceType.self,
        ColorTemperatureLightDeviceType.self,
        ExtendedColorLightDeviceType.self,
        OnOffPluginUnitDeviceType.self,
        DimmablePlugInUnitDeviceType.self,
    ]

    private static let appleTeamID = "MMGNY4PX8S"
    private static var isConfigured = false

    // Reuses the iOS OAuth client from Info.plist; that Cloud project must have the Home API enabled.
    private static func configureIfNeeded() throws {
        guard !isConfigured else { return }
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            throw HomeError.failedPrecondition("GIDClientID is missing from Info.plist")
        }
        Home.configure {
            $0.teamID = appleTeamID
            $0.clientID = clientID
        }
        isConfigured = true
    }

    func connect() async {
        guard home == nil, !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }

        do {
            try Self.configureIfNeeded()
            let home = try await Home.connect()
            self.home = home
            isConnected = true
            errorMessage = nil
            observeDevices(in: home)
        } catch {
            errorMessage = "Couldn't connect to Google Home: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        deviceListTask?.cancel()
        deviceListTask = nil
        deviceTypeTasks.values.forEach { $0.cancel() }
        deviceTypeTasks.removeAll()
        onOffTraits.removeAll()
        homeDevices.removeAll()
        devices = []
        isConnected = false
        await home?.disconnect()
        home = nil
    }

    func toggle(_ device: GoogleHomeDevice) async {
        guard let trait = onOffTraits[device.id] else { return }
        do {
            try await trait.toggle()
        } catch {
            errorMessage = "Couldn't toggle \(device.name): \(error.localizedDescription)"
        }
    }

    private func observeDevices(in home: Home) {
        deviceListTask = Task { [weak self] in
            do {
                for try await devices in home.devices().batched().values {
                    self?.handleDeviceList(devices)
                }
            } catch {
                self?.errorMessage = "Lost Google Home device updates: \(error.localizedDescription)"
            }
        }
    }

    private func handleDeviceList(_ newDevices: Set<HomeDevice>) {
        let currentIDs = Set(newDevices.map(\.id))
        for id in deviceTypeTasks.keys where !currentIDs.contains(id) {
            deviceTypeTasks.removeValue(forKey: id)?.cancel()
            onOffTraits.removeValue(forKey: id)
        }

        homeDevices = newDevices
        for device in newDevices where deviceTypeTasks[device.id] == nil {
            observeTypes(of: device)
        }
        rebuildDevices()
    }

    private func observeTypes(of device: HomeDevice) {
        let id = device.id
        deviceTypeTasks[id] = Task { [weak self] in
            do {
                for try await types in device.types.subscribeAll().values {
                    self?.onOffTraits[id] = Self.onOffTrait(in: types)
                    self?.rebuildDevices()
                }
            } catch {
                self?.errorMessage = "Lost updates for \(device.name): \(error.localizedDescription)"
            }
        }
    }

    private func rebuildDevices() {
        devices = homeDevices
            .map { device in
                let trait = onOffTraits[device.id]
                return GoogleHomeDevice(
                    id: device.id,
                    name: device.name,
                    supportsOnOff: trait != nil,
                    isOn: trait?.attributes.onOff ?? false
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func onOffTrait(in types: DeviceTypeCollection) -> OnOffTrait? {
        for type in onOffDeviceTypes {
            if let trait = onOffTrait(of: type, in: types) {
                return trait
            }
        }
        return nil
    }

    private static func onOffTrait<T: DeviceType>(of type: T.Type, in types: DeviceTypeCollection) -> OnOffTrait? {
        types[type]?.traits[OnOffTrait.self]
    }
}
