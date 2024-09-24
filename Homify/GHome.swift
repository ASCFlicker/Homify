//
//  GHome.swift
//  Homify
//
//  Created by Jun Huang on 9/20/24.
//

import SwiftUI

struct GHome: View {
    var body: some View {
        Button {
            
        }
        label:{
            VStack(alignment: .center){
                HStack{
                    Text("Link with:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .font(.largeTitle)
                        .multilineTextAlignment(.leading)
                        .padding()
                    Spacer()
                }
                ZStack
                {
                    RoundedRectangle(cornerRadius: 30)
                        .frame(width: 250.0, height: 150.0)
                        .foregroundStyle(.black)
                        .overlay{
                            RoundedRectangle(cornerRadius: 20).stroke(.white,lineWidth: 4)
                        }
                    Image("GHomeLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20.0)
                        .frame(width: 260)
                    
                }
            }
        }
    }
}

#Preview {
    GHome()
}
