//
//  ContentView.swift
//  Homify
//
//  Created by Jun Huang on 9/17/24.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        VStack{
            Text("Homify")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            Spacer()
            GHome()
            }
        .padding()
        }
        
    }

#Preview {
    ContentView()
}
