//
//  MultipeerConnectivityManager.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 26/09/23.
//

import MultipeerConnectivity
import NearbyInteraction
import SwiftUI

class MultipeerConnectivityManager: NSObject, PeersListProtocol {
    private var _niSession: NISession!
    private var _mcSession: MCSession!
    private var _mcPeerID: MCPeerID!
    private var _mcAdvertiser: MCNearbyServiceAdvertiser!
    private var _mcBrowser: MCNearbyServiceBrowser!

    @Published var discoveredPeers = [DiscoveredPeer]()

    override init() {
        super.init()

        _niSession = NISession()
        _niSession.delegate = self

        _mcPeerID = MCPeerID(displayName: UIDevice.current.name)
        _mcSession = MCSession(peer: _mcPeerID, securityIdentity: nil, encryptionPreference: .required)
        _mcSession.delegate = self

        _mcAdvertiser = MCNearbyServiceAdvertiser(peer: _mcPeerID, discoveryInfo: nil, serviceType: "radar")
        _mcAdvertiser.delegate = self
        _mcAdvertiser.startAdvertisingPeer()

        _mcBrowser = MCNearbyServiceBrowser(peer: _mcPeerID, serviceType: "radar")
        _mcBrowser.delegate = self
        _mcBrowser.startBrowsingForPeers()
    }

    private func sendDiscoveryToken() {
        guard let discoveryToken = _niSession.discoveryToken else {
            return
        }

        let data = try! NSKeyedArchiver.archivedData(withRootObject: discoveryToken, requiringSecureCoding: true)

        try! _mcSession.send(data, toPeers: _mcSession.connectedPeers, with: .reliable)
    }
}

extension MultipeerConnectivityManager: NISessionDelegate {
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        for object in nearbyObjects {
            let discoveredPeer = DiscoveredPeer(token: object.discoveryToken, distance: object.distance ?? 0.0)

            if let index = discoveredPeers.firstIndex(where: { $0.token == object.discoveryToken }) {
                discoveredPeers[index] = discoveredPeer
            } else {
                discoveredPeers.append(discoveredPeer)
            }
        }
    }
}

extension MultipeerConnectivityManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard state == .connected else { return }
        sendDiscoveryToken()
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            guard let discoveryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
                return
            }

            let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
            _niSession.run(config)
        } catch {}
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerConnectivityManager: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, _mcSession)
    }
}

extension MultipeerConnectivityManager: MCNearbyServiceBrowserDelegate {

    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        _mcBrowser.invitePeer(peerID, to: _mcSession, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}

