//
//  MainMenuView.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 26/09/23.
//

import SwiftUI

struct MainMenuView: View {
    
    @State private var isAlertPresented : Bool = false
    
    var body: some View {
        ZStack {
            
            Image("Home")
                .resizable()
                .scaledToFill()
            
            VStack {
                
                Spacer()
                
                VStack(alignment: .center, spacing: 32) {
                    Circle()
                        .fill(Color(hex: "EAB25E"))
                        .frame(width: 172, height: 172, alignment: .center)
                    
                    Text("Belleco")
                        .font(.anybodyBold(size: 28))
                      .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 10) {
                    Button(action: /*@START_MENU_TOKEN@*/{}/*@END_MENU_TOKEN@*/, label: {
                        ZStack {
                            Image("Button")
                            Text("Criar uma sala")
                                .font(.anybodyBold(size: 17))
                                .foregroundColor(Color(hex: "1F203D"))
                        }
                    })
                    
                    Button(action: {
                        isAlertPresented.toggle()
                    }, label: {
                        ZStack {
                            Image("Button2")
                            Text("Entrar em uma sala")
                                .font(.anybodyBold(size: 17))
                                .foregroundColor(Color(hex: "1F203D"))
                        }
                    })
                }
                .padding(.bottom, 56)
            }
        }.alert("Calma po", isPresented: $isAlertPresented){
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    MainMenuView()
}
