//
//  testprojectApp.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI

@main
struct testprojectApp: App {
    @State var user: User?
    var body: some Scene {
        WindowGroup {
            ContentView(user: self.$user)
        }
    }
}
