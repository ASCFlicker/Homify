//
//  testprojectApp.swift
//  testproject
//
//  Created by Jun Huang on 10/29/24.
//

import SwiftUI
import GoogleSignIn

@main
struct testprojectApp: App {
    @State var user: User?
    var body: some Scene {
        WindowGroup {
            ContentView(user: self.$user)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user {
                            self.user = User(name: user.profile?.name ?? "")
                        }
                    }
                }
        }
    }
}
