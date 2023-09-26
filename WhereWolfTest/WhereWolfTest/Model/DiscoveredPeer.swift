//
//  User.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 26/09/23.
//

import Foundation
import Combine
import NearbyInteraction

protocol PeersListProtocol: ObservableObject {
    var discoveredPeers: [DiscoveredPeer] {get set}
}

struct DiscoveredPeer : Hashable {
    let token: NIDiscoveryToken
    let distance: Float
}

