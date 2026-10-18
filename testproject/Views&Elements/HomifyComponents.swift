import SwiftUI

struct DeviceTile: View {
    let name: String
    var detail: String?
    let systemImage: String
    let isOn: Bool
    var isSupported = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .symbolVariant(isOn ? .fill : .none)
                    .foregroundStyle(isOn ? Color.yellow : Color.secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(height: 32)
                Spacer(minLength: 18)
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
            .padding(16)
            .contentShape(.rect(cornerRadius: 26))
        }
        .buttonStyle(.plain)
        .glassEffect(glass, in: .rect(cornerRadius: 26))
        .disabled(!isSupported)
        .opacity(isSupported ? 1 : 0.55)
        .animation(.smooth, value: isOn)
        .sensoryFeedback(.impact(weight: .light), trigger: isOn)
        .accessibilityLabel(name)
        .accessibilityValue(statusText)
        .accessibilityAddTraits(isSupported ? .isToggle : [])
    }

    private var statusText: String {
        guard isSupported else { return "Unsupported" }
        let state = isOn ? "On" : "Off"
        guard let detail, !detail.isEmpty else { return state }
        return "\(detail) · \(state)"
    }

    private var glass: Glass {
        isOn ? .regular.tint(.yellow.opacity(0.3)).interactive() : .regular.interactive(isSupported)
    }
}

struct DeviceSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

struct DeviceGrid<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        // Container spacing stays below the grid gap so idle tiles don't blend into each other.
        GlassEffectContainer(spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                content
            }
        }
    }
}

struct InfoCard<Actions: View>: View {
    let title: String
    let message: String
    let systemImage: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .glassEffect(.regular, in: .rect(cornerRadius: 26))
    }
}

extension InfoCard where Actions == EmptyView {
    init(title: String, message: String, systemImage: String) {
        self.init(title: title, message: message, systemImage: systemImage) { EmptyView() }
    }
}

struct HomifyBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [0.6, 0.45], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: colorScheme == .dark ? Self.darkColors : Self.lightColors
        )
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }

    private static let lightColors: [Color] = [
        .orange.opacity(0.30), .yellow.opacity(0.22), .pink.opacity(0.22),
        .teal.opacity(0.18), .clear, .indigo.opacity(0.16),
        .blue.opacity(0.22), .mint.opacity(0.18), .purple.opacity(0.22),
    ]

    private static let darkColors: [Color] = [
        .indigo.opacity(0.55), .purple.opacity(0.35), .blue.opacity(0.40),
        .teal.opacity(0.25), .clear, .orange.opacity(0.18),
        .blue.opacity(0.30), .indigo.opacity(0.35), .purple.opacity(0.45),
    ]
}
