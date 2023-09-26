//
//  ContentView.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 24/09/23.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @ObservedObject var connect = CoreBluetoothManager()
    
    @State var wasKilled: Bool = false
    
    var body: some View {
        ZStack {
            
            Image("Home")
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 16){
                Spacer()
                
                Text("Discovered Users: \(connect.discoveredPeers.count)")
                    .font(.anybodyBold(size: 32))
                    .foregroundColor(.white)
                
                if (wasKilled) {
                    Text("An user was killed!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                ForEach(connect.discoveredPeers, id: \.self) { users in
                    Text("\(users.token)")
                }
                
                Spacer()
                if(!connect.discoveredPeers.isEmpty) {
                    VStack(spacing: 16) {
                        
                        Image("Village")
                            .resizable()
                            .frame(width: 100, height: 100, alignment: .center)
                        
                        Text("You are close enough to a villager")
                            .font(.anybodyRegular(size: 17))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            wasKilled.toggle()
                        }, label: {
                            ZStack {
                                Image("Button")
                                Text("Kill")
                                    .font(.title2)
                                    .foregroundColor(.black)
                            }
                        }).buttonStyle(.borderless)
                            .disabled(connect.discoveredPeers.last!.distance < 3.0)
                    }
                }
                Spacer()
            }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
