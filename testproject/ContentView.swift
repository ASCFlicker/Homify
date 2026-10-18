//
//  ContentView.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @Binding var user: User?
    @StateObject private var homeManager = HomeKitManager()
    @StateObject private var googleHomeManager = GoogleHomeManager()
    @StateObject private var layout = DeviceLayoutStore()
    @State private var isCustomizing = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HomeKitSection(homeManager: homeManager, layout: layout) {
                        isCustomizing = true
                    }

                    GoogleHomeSection(
                        manager: googleHomeManager,
                        layout: layout,
                        isSignedIn: user != nil,
                        signIn: handleSignUpButton
                    ) {
                        isCustomizing = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background { HomifyBackground() }
            .navigationTitle("Homify")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Customize", systemImage: "slider.horizontal.3") {
                        isCustomizing = true
                    }
                }
                ToolbarSpacer(.fixed, placement: .topBarTrailing)
                ToolbarItem(placement: .topBarTrailing) {
                    accountMenu
                }
            }
            .sheet(isPresented: $isCustomizing) {
                CustomizeLayoutView(
                    layout: layout,
                    appleHomeItems: homeManager.layoutItems,
                    googleHomeItems: googleHomeManager.layoutItems
                )
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    homeManager.refreshPowerStates()
                }
            }
        }
    }

    private var greeting: String {
        guard let name = user?.name, !name.isEmpty else { return "All your devices, in one place." }
        return "Welcome back, \(name)."
    }

    private var accountMenu: some View {
        Menu {
            if let user {
                Section(user.name) {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        signOut()
                    }
                }
            } else {
                Button("Sign In with Google", systemImage: "person.crop.circle.badge.plus") {
                    handleSignUpButton()
                }
            }
        } label: {
            Label("Account", systemImage: user == nil ? "person.crop.circle" : "person.crop.circle.fill")
        }
    }

    private func signOut() {
        Task { await googleHomeManager.disconnect() }
        GIDSignIn.sharedInstance.signOut()
        user = nil
    }

    func handleSignUpButton() {
        if let rootViewController = getRootViewController() {
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                guard let result else {
                    //inspect error
                    return
                }
                self.user = User.init(name: result.user.profile?.name ?? "")
            }
        }
    }

    func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as?
                UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController
        else { return nil }
        return getVisibleViewController(from: rootViewController)
    }

    private func getVisibleViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return getVisibleViewController(from: nav.visibleViewController!)
        }
        if let tab = vc as? UITabBarController {
            return getVisibleViewController(from: tab.selectedViewController!)
        }
        if let presented = vc.presentedViewController {
            return getVisibleViewController(from: presented)
        }
        return vc
    }
}
