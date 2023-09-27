//
//  MultipeerConnectivityController.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 27/09/23.
//

import SwiftUI
import MultipeerConnectivity

public protocol MultipeerConnectivityControllerDelegate : AnyObject {
    func didChange()
    func received(data: Data, viaStream: Bool)
}

public typealias peerName = String

class MultipeerConnectivityController : NSObject {
    
    public static var shared = MultipeerConnectivityController()
    
    let serviceType = "wolf"
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let startTime = Date().timeIntervalSince1970

    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    public var peerState = [peerName: MCSessionState]()
    public var hasPeers = false
    public var peersDelegates = [any MultipeerConnectivityControllerDelegate]()
    public func remove(peersDelegate: any MultipeerConnectivityControllerDelegate) {
        peersDelegates = peersDelegates.filter { return $0 !== peersDelegate }
    }
    
    public lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerID)
        session.delegate = self
        return session
    }()
    
    public lazy var myName: peerName = {
        return session.myPeerID.displayName
    }()
    
    override init() {
        super.init()
    }
    
    deinit {
        stopServices()
        session.disconnect()
        session.delegate = nil
    }

    func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    private func stopServices() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil

        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
    }
    
    private func elapsedTime() -> TimeInterval {
        Date().timeIntervalSince1970 - startTime
    }

    func logPeer(_ body: peerName) {
        let logTime = String(format: "%.2f", elapsedTime())
        print("⚡️ \(logTime) \(myName): \(body)")
    }
    
    func fixConnectedState(for peerName: String) {
        peerState[peerName] = .connected
    }
}

extension MultipeerConnectivityController: MCSessionDelegate {

    public func session(_ session: MCSession,
                        peer peerID: MCPeerID,
                        didChange state: MCSessionState) {

        let peerName = peerID.displayName
        logPeer("session \"\(peerName)\" \(state.description())")
        peerState[peerName] = state

        if state == .connected {
            hasPeers = true
        } else {
            // test if no longer connected
            var hasPeersNow = false
            for state in peerState.values {
                if state == .connected {
                    hasPeersNow = true
                    break
                }
            }
            hasPeers = hasPeersNow
        }

        DispatchQueue.main.async {
            for peersDelegate in self.peersDelegates {
                peersDelegate.didChange()
            }
        }
    }

    /// receive message via session
    public func session(_ session: MCSession,
                        didReceive data: Data,
                        fromPeer peerID: MCPeerID) {

        let peerName = peerID.displayName
        logPeer("⚡️didReceive: \"\(peerName)\"")
        fixConnectedState(for: peerName)

        DispatchQueue.main.async {
            for delegate in self.peersDelegates {
                delegate.received(data: data, viaStream: false)
            }
        }
    }

    public func session(_ session: MCSession,
                        didReceive inputStream: InputStream,
                        withName streamName: String,
                        fromPeer: MCPeerID) {
    }

    // files not implemented
    public func session(_ session: MCSession, didStartReceivingResourceWithName _: String, fromPeer: MCPeerID, with _: Progress) {}
    public func session(_ session: MCSession, didFinishReceivingResourceWithName _: String, fromPeer: MCPeerID, at _: URL?, withError _: Error?) {}
}

extension MultipeerConnectivityController: MCNearbyServiceBrowserDelegate {

    // Found a nearby advertising peer
    public func browser(_ browser: MCNearbyServiceBrowser,
                        foundPeer peerID: MCPeerID,
                        withDiscoveryInfo info: [String : String]?) {

        let peerName = peerID.displayName
        let shouldInvite = ((myName != peerName) &&
                            (peerState[peerName] == nil ||
                             peerState[peerName] != .connected))

        if shouldInvite {
            logPeer("Inviting \"\(peerName)\"")
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30.0)
        } else {
            logPeer("Not inviting \"\(peerName)\"")
        }

        for delegate in peersDelegates {
            delegate.didChange()
        }
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        lostPeer peerID: MCPeerID) {
        let peerName = peerID.displayName
        logPeer("lostPeer: \"\(peerName)\"")
    }

    public func browser(_ browser: MCNearbyServiceBrowser,
                        didNotStartBrowsingForPeers error: Error) {

        logPeer("didNotStartBrowsingForPeers: \(error)")
    }
}

extension MultipeerConnectivityController: MCNearbyServiceAdvertiserDelegate {

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didReceiveInvitationFromPeer peerID: MCPeerID,
                           withContext _: Data?,
                           invitationHandler: @escaping (Bool, MCSession?) -> Void) {

        logPeer("didReceiveInvitationFromPeer:  \"\(peerID.displayName)\"")

        invitationHandler(true, session)
    }

    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                           didNotStartAdvertisingPeer error: Error) {

        logPeer("didNotStartAdvertisingPeer \(error)")
    }
}

extension MCSessionState {
    func description() -> String {
        switch self {
            case .connecting:   return "connecting"
            case .connected:    return "connected"
            case .notConnected: return "notConnected"
            @unknown default:   return "unknown"
        }
    }
    func icon() -> String {
        switch self {
            case .connecting:   return "❓"
            case .connected:    return "🤝"
            case .notConnected: return "🚫"
            @unknown default:   return "‼️"
        }
    }
}
