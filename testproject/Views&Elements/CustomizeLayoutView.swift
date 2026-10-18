import SwiftUI

struct LayoutItem: Identifiable {
    let id: String
    let name: String
    var detail: String?
    let systemImage: String
    let isSupported: Bool
}

struct CustomizeLayoutView: View {
    @ObservedObject var layout: DeviceLayoutStore
    let appleHomeItems: [LayoutItem]
    let googleHomeItems: [LayoutItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                section(.appleHome, title: "Apple Home", items: appleHomeItems)
                section(.googleHome, title: "Google Home", items: googleHomeItems)

                if appleHomeItems.isEmpty && googleHomeItems.isEmpty {
                    Text("No devices to customize yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func section(_ section: DeviceLayoutSection, title: String, items: [LayoutItem]) -> some View {
        if !items.isEmpty {
            let arranged = layout.arranged(items, in: section, id: \.id)
            Section {
                ForEach(arranged) { item in
                    row(for: item)
                }
                .onMove { source, destination in
                    layout.move(in: section, arrangedIDs: arranged.map(\.id), from: source, to: destination)
                }
            } header: {
                Text(title)
            } footer: {
                Text("Drag to reorder. Hidden devices stay connected but won't appear on the home screen.")
            }
        }
    }

    private func row(for item: LayoutItem) -> some View {
        Toggle(isOn: Binding(
            get: { !layout.isHidden(item.id) },
            set: { layout.setHidden(!$0, for: item.id) }
        )) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                    if let subtitle = subtitle(for: item) {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Image(systemName: item.systemImage)
                    .foregroundStyle(item.isSupported ? Color.accentColor : Color.secondary)
            }
        }
    }

    private func subtitle(for item: LayoutItem) -> String? {
        let parts = [item.detail, item.isSupported ? nil : "Unsupported"].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
