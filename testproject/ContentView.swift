//
//  ContentView.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI
import HomeKit
import Foundation

struct ContentView: View {
    @StateObject private var homeManager = HomeKitManager()
    var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Button("Connect to HomeKit") {
                        homeManager.homeManager?.delegate = homeManager
                    }
                    .padding()
                    
                    if homeManager.isAuthorized{// UpdateButton()
                        NavigationLink("Go to Accessories", value: true)
                    }
                }
                // Navigation destination based on a boolean condition
                .navigationDestination(isPresented: $homeManager.isAuthorized) {
                    AccessoriesView(homeManager: homeManager)
                }
            }
        }
    }

#Preview {
    ContentView()
}
