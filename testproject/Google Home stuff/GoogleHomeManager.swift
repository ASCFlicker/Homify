//
//  GoogleHomeManager.swift
//  Homify2
//

import Foundation
import GoogleHomeSDK
import GoogleHomeTypes

private typealias OnOffTrait = GoogleHomeTypes.Matter.OnOffTrait

struct GoogleHomeDevice: Identifiable {
    enum Kind {
        case light, plug, other

        var systemImage: String {
            switch self {
            case .light: "lightbulb"
            case .plug: "powerplug"
            case .other: "square.dashed"
            }
        }
    }

    let id: String
    let name: String
    var kind: Kind
    var supportsOnOff: Bool
    var isOn: Bool
}

@MainActor
final class GoogleHomeManager: ObservableObject {
    @Published private(set) var devices: [GoogleHomeDevice] = []
    @Published private(set) var homeNames: [String] = []
    @Published private(set) var hasLoadedHomes = false
    @Published private(set) var hasLoadedDevices = false
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published var errorMessage: String?

    private typealias OnOffControl = (trait: OnOffTrait, kind: GoogleHomeDevice.Kind)

    private var home: Home?
    private var homeDevices: Set<HomeDevice> = []
    private var controls: [String: OnOffControl] = [:]
    private var deviceListTask: Task<Void, Never>?
    private var structureListTask: Task<Void, Never>?
    private var deviceTypeTasks: [String: Task<Void, Never>] = [:]
    // Bumped by disconnect() so a Home.connect() that finishes after sign-out is discarded.
    private var connectionGeneration = 0

    // DeviceTypeCollection can't be enumerated, so probe the types that carry an OnOff trait.
    private static let lightTypes: [any DeviceType.Type] = [
        OnOffLightDeviceType.self,
        DimmableLightDeviceType.self,
        ColorTemperatureLightDeviceType.self,
        ExtendedColorLightDeviceType.self,
    ]
    private static let plugTypes: [any DeviceType.Type] = [
        OnOffPluginUnitDeviceType.self,
        DimmablePlugInUnitDeviceType.self,
    ]

    private static let appleTeamID = "MMGNY4PX8S"
    private static let appGroup = "group.CSProj.Homify2"
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
            $0.sharedAppGroup = appGroup
        }
        isConfigured = true
    }

    func connect() async {
        guard home == nil, !isConnecting else { return }
        isConnecting = true
        defer { isConnecting = false }
        let generation = connectionGeneration

        do {
            try Self.configureIfNeeded()
            let home = try await Home.connect()
            guard generation == connectionGeneration else {
                await home.disconnect()
                return
            }
            self.home = home
            isConnected = true
            errorMessage = nil
            observeStructures(in: home)
            observeDevices(in: home)
        } catch {
            guard generation == connectionGeneration else { return }
            errorMessage = "Couldn't connect to Google Home: \(error.localizedDescription)"
        }
    }

    func disconnect() async {
        connectionGeneration += 1
        deviceListTask?.cancel()
        deviceListTask = nil
        structureListTask?.cancel()
        structureListTask = nil
        deviceTypeTasks.values.forEach { $0.cancel() }
        deviceTypeTasks.removeAll()
        controls.removeAll()
        homeDevices.removeAll()
        devices = []
        homeNames = []
        hasLoadedHomes = false
        hasLoadedDevices = false
        isConnected = false
        errorMessage = nil
        let home = self.home
        self.home = nil
        await home?.disconnect()
    }

    func toggle(_ device: GoogleHomeDevice) async {
        guard let trait = controls[device.id]?.trait else { return }
        do {
            try await trait.toggle()
        } catch {
            errorMessage = "Couldn't toggle \(device.name): \(error.localizedDescription)"
        }
    }

    func manageAccess() {
        home?.presentPermissionsUpdate()
    }

    func reload() async {
        await disconnect()
        await connect()
    }

    private func observeStructures(in home: Home) {
        structureListTask = Task { [weak self] in
            do {
                for try await structures in home.structures().batched().values {
                    self?.homeNames = structures.map(\.name).sorted()
                    self?.hasLoadedHomes = true
                }
            } catch {
                self?.errorMessage = "Lost Google Home updates: \(error.localizedDescription)"
            }
        }
    }

    private func observeDevices(in home: Home) {
        deviceListTask = Task { [weak self] in
            do {
                for try await devices in home.devices().batched().values {
                    self?.hasLoadedDevices = true
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
            controls.removeValue(forKey: id)
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
                    self?.controls[id] = Self.onOffControl(in: types)
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
                let control = controls[device.id]
                return GoogleHomeDevice(
                    id: device.id,
                    name: device.name,
                    kind: control?.kind ?? .other,
                    supportsOnOff: control != nil,
                    isOn: control?.trait.attributes.onOff ?? false
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private static func onOffControl(in types: DeviceTypeCollection) -> OnOffControl? {
        for type in lightTypes {
            if let trait = onOffTrait(of: type, in: types) { return (trait, .light) }
        }
        for type in plugTypes {
            if let trait = onOffTrait(of: type, in: types) { return (trait, .plug) }
        }
        return nil
    }

    private static func onOffTrait<T: DeviceType>(of type: T.Type, in types: DeviceTypeCollection) -> OnOffTrait? {
        types[type]?.traits[OnOffTrait.self]
    }
}
