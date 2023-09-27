//
//  ContentView.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 24/09/23.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    
    @ObservedObject var viewModel = WolfConnectionViewModel()
    @State var wasKilled: Bool = false
    @State private var distance : Float = -1.0
    
    var body: some View {
        ZStack {
            
            Image("Home")
                .resizable()
                .scaledToFill()
            
            VStack(spacing: 16) {
                if (self.viewModel.peerName == "") {
                    Text("The wolf is hunting its prey...")
                        .font(.anybodyBold(size: 32))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                } else {
                    if(!self.viewModel.wasKilled) {
                        VStack(spacing: 36) {
                            
                            Text("The wolf found his victim!")
                                .font(.anybodyBold(size: 32))
                                .foregroundColor(Color(hex: "F0675E"))
                                .multilineTextAlignment(.center)
                            
                            VStack(alignment: .center, spacing: 32) {
                                Circle()
                                    .fill(Color(hex: "EAB25E"))
                                    .frame(width: 172, height: 172, alignment: .center)
                                    .overlay(
                                        Image("Village")
                                            .resizable()
                                            .frame(width: 130, height: 130, alignment: .center)
                                    )
                                
                                Text(self.viewModel.peerName)
                                    .font(.anybodyBold(size: 28))
                                  .foregroundColor(.white)
                            }
                            
                            Text(distance < 0.5 ? "You are close enought to Kill!" : "\(distance)")
                                .font(.anybodyRegular(size: 20))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .onReceive(self.viewModel.$distanceToPeer, perform: { updatedDistance in
                                    guard let updatedDistance = updatedDistance else
                                    {
                                        self.distance = -1.0
                                        return
                                    }
                                    self.distance = updatedDistance
                                })
                            
                            Button(action: {
                                self.viewModel.wasKilled.toggle()
                            }, label: {
                                ZStack {
                                    Image("Button")
                                    Text("Kill")
                                        .font(.anybodyBold(size: 17))
                                        .foregroundColor(.black)
                                }
                            }).opacity(distance > 0.5 ? 0.5 : 1.0)
                            .buttonStyle(.borderless)
                            .disabled(distance > 0.5)
                        }
                    } else {
                        Text("The Villager was killed!")
                            .font(.anybodyBold(size: 32))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
}

//VStack(spacing: 16) {
//    
//    Image("Village")
//        .resizable()
//        .frame(width: 100, height: 100, alignment: .center)
//    
//    Text("You are close enough to a villager")
//        .font(.anybodyRegular(size: 17))
//        .foregroundColor(.white)
//    
//    Button(action: {
//        wasKilled.toggle()
//    }, label: {
//        ZStack {
//            Image("Button")
//            Text("Kill")
//                .font(.title2)
//                .foregroundColor(.black)
//        }
//    }).buttonStyle(.borderless)
//}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
