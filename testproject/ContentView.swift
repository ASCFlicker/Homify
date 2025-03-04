//
//  ContentView.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI
import HomeKit
import Foundation
import GoogleSignIn

struct ContentView: View {
    @Binding var user: User?
    @StateObject private var homeManager = HomeKitManager()
    @State private var isShowingAccessoriesView = false // State to control AccessoriesView visibility

    var body: some View {
        if let user {
            Text("Hi there, \(user.name)")
            Button {
                GIDSignIn.sharedInstance.signOut()
                self.user = nil
            } label: {
                Text("Log out")
            }
        } else {
            VStack { // Removed NavigationStack
                VStack(spacing: 20) {
                    Button(action: {
                        homeManager.homeManager?.delegate = homeManager
                        isShowingAccessoriesView = true // Show AccessoriesView when button is tapped
                    }) {
                        Text(homeManager.isAuthorized ? "See HomeKit accessories" : "Connect to HomeKit") // Conditional button text
                    }
                    .padding()

                    Button {
                        handleSignUpButton()
                    } label: {
                        Text("Connect to Google Home")
                    }

                }

                if isShowingAccessoriesView { // Conditionally show AccessoriesView
                    AccessoriesView(homeManager: homeManager)
                        .transition(.move(edge: .bottom)) // Optional: Add a transition for visual effect
                        .zIndex(1) // Ensure it's on top if needed
                }


            } // Removed NavigationStack
        }
    }

    func handleSignUpButton() {
        print ("Sign in with Google Clicked")
        if let rootViewController = getRootViewController() {
            GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
                guard let result else {
                    //inspect error
                    return
                }
                self.user = User.init(name: result.user.profile?.name ?? "")
                //do something with result
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
