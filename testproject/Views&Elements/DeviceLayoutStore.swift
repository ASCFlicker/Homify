import SwiftUI

enum DeviceLayoutSection: String {
    case appleHome, googleHome
}

final class DeviceLayoutStore: ObservableObject {
    @Published private var order: [DeviceLayoutSection: [String]]
    @Published private var hidden: Set<String>

    private let defaults: UserDefaults
    private static let hiddenKey = "layout.hidden"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hidden = Set(defaults.stringArray(forKey: Self.hiddenKey) ?? [])
        order = [
            .appleHome: defaults.stringArray(forKey: Self.orderKey(.appleHome)) ?? [],
            .googleHome: defaults.stringArray(forKey: Self.orderKey(.googleHome)) ?? [],
        ]
    }

    func isHidden(_ id: String) -> Bool {
        hidden.contains(id)
    }

    func setHidden(_ isHidden: Bool, for id: String) {
        if isHidden {
            hidden.insert(id)
        } else {
            hidden.remove(id)
        }
        defaults.set(Array(hidden), forKey: Self.hiddenKey)
    }

    /// Saved order first; devices that were never reordered keep their incoming order at the end.
    func arranged<Item>(_ items: [Item], in section: DeviceLayoutSection, id: (Item) -> String) -> [Item] {
        let rank = (order[section] ?? []).enumerated().reduce(into: [String: Int]()) { ranks, entry in
            ranks[entry.element] = ranks[entry.element] ?? entry.offset
        }
        return items.enumerated()
            .sorted { lhs, rhs in
                switch (rank[id(lhs.element)], rank[id(rhs.element)]) {
                case let (l?, r?): l < r
                case (.some, nil): true
                case (nil, .some): false
                case (nil, nil): lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    func visible<Item>(_ items: [Item], in section: DeviceLayoutSection, id: (Item) -> String) -> [Item] {
        arranged(items, in: section, id: id).filter { !hidden.contains(id($0)) }
    }

    func move(in section: DeviceLayoutSection, arrangedIDs: [String], from source: IndexSet, to destination: Int) {
        var ids = arrangedIDs
        ids.move(fromOffsets: source, toOffset: destination)
        order[section] = ids
        defaults.set(ids, forKey: Self.orderKey(section))
    }

    private static func orderKey(_ section: DeviceLayoutSection) -> String {
        "layout.order.\(section.rawValue)"
    }
}
