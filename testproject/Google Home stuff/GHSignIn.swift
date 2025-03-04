//
//  GIDSingin.swift
//  Homify2
//
//  Created by Jun Huang on 2/28/25.
//

import SwiftUI
import GoogleSignIn


struct GHSignIn: App {
    @State var user: User?
    var body: some Scene {
        WindowGroup{
            ContentView(user: self.$user)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                        if let user {
                            self.user = .init(name: user.profile?.name ?? "")
                        }
                    }
                }
        }
    }
}

struct User{
    var name: String
}
