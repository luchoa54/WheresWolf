//
//  TestMultipeerView.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 27/09/23.
//

import SwiftUI

struct TestMultipeerView: View {
    
    @ObservedObject var viewModel : MultipeerConnectivityViewModel
    var mp = MultipeerConnectivityController.shared
    var peersTitle: String { viewModel.peersTitle }
    var peersList: String { viewModel.peersList }
    
    var body: some View {
        VStack {
            
            Text("You: \(peersTitle)")
                .font(.anybodyBold(size: 17))
                .foregroundColor(.white)
            
            Text(peersList)
                .font(.anybodyBold(size: 17))
                .foregroundColor(.white)
            Button(action: {
                mp.startBrowsing()
            }, label: {
                ZStack {
                    Image("Button")
                    Text("Criar sala")
                        .font(.anybodyBold(size: 17))
                        .foregroundColor(.black)
                }
            })
            .buttonStyle(.borderless)
            
            Button(action: {
                mp.startAdvertising()
            }, label: {
                ZStack {
                    Image("Button2")
                    Text("Entrar em uma Sala")
                        .font(.anybodyBold(size: 17))
                        .foregroundColor(.black)
                }
            })
            .buttonStyle(.borderless)
        }
    }
}
