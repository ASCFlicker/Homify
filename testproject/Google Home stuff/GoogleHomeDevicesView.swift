import SwiftUI

struct GoogleHomeDevicesView: View {
    @ObservedObject var manager: GoogleHomeManager

    var body: some View {
        VStack(spacing: 12) {
            if !manager.isConnected {
                Button {
                    Task { await manager.connect() }
                } label: {
                    if manager.isConnecting {
                        ProgressView()
                    } else {
                        Text("Show Google Home devices")
                    }
                }
                .disabled(manager.isConnecting)
            }

            if let errorMessage = manager.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if manager.isConnected {
                if manager.devices.isEmpty {
                    Text("No Google Home devices found.")
                        .foregroundColor(.gray)
                } else {
                    List(manager.devices) { device in
                        if device.supportsOnOff {
                            Button {
                                Task { await manager.toggle(device) }
                            } label: {
                                Text("[GH] \(device.name)")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(device.isOn ? Color.yellow : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .animation(.easeInOut(duration: 0.3), value: device.isOn)
                        } else {
                            Text("Unsupported device: \(device.name)")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}
