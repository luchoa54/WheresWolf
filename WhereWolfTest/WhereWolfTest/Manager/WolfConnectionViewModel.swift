//
//  MultipeerManager.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 26/09/23.
//
import NearbyInteraction
import MultipeerConnectivity

import Combine
import Foundation

internal class WolfConnectionViewModel: NSObject, ObservableObject {
    
    ///
    @Published internal var invitationClosed = false
    ///
    @Published internal private(set) var peerName = ""
    ///
    @Published internal private(set) var distanceToPeer: Float?
    ///
    @Published internal private(set) var isDirectionAvailable = false
    ///
    @Published internal private(set) var directionAngle = 0.0
    ///
    @Published internal private(set) var isConnectionLost = false
    
    @Published internal var wasKilled = false
    
    ///
    private var nearbySession: NISession?
    
    ///
    private let serviceIdentity: String
    ///
    private var multipeerSession: MCSession?
    ///
    private var peer: MCPeerID?
    ///
    private var peerToken: NIDiscoveryToken?
    ///
    private var multipeerAdvertiser: MCNearbyServiceAdvertiser?
    ///
    private var multipeerBrowser: MCNearbyServiceBrowser?
    ///
    private var maxPeersInSession = 1
    ///
    private var sharedTokenWithPeer = false
    
    ///
    internal static var nearbySessionAvailable: Bool
    {
        return NISession.isSupported
    }

    /**
        Arrancamos las sesiones de `NearbyInteraction`
        y de `MultipeerConnectivity`
    */
    override internal init()
    {
        // Avoid any simulator instances from finding any actual devices.
        #if targetEnvironment(simulator)
        self.serviceIdentity = "com.desappstre.Cerca./simulator_ni"
        #else
        self.serviceIdentity = "com.desappstre.Cerca./device_ni"
        #endif
        
        super.init()
        
        self.startNearbySession()
        self.startMultipeerSession()
    }
    
    /**
     
    */
    deinit
    {
        self.stopMultipeerSession()
        
        self.multipeerSession?.disconnect()
    }
    
    /**
        Arranca la sesión de `NearbyInteraction`.
     
        También se inicia la sesión de `MultipeerConectivity`
        en caso que sea la primera vez que se inica la app.
    */
    internal func startNearbySession() -> Void
    {
        // Creamos la NISession.
        self.nearbySession = NISession()
        
        // Ahora el delegado.
        // Recibimos datos sobre el estado de la sesión
        self.nearbySession?.delegate = self
    
        // Es una nueva sesión así que tendremos que
        // intercambiar nuestro token.
        sharedTokenWithPeer = false

        // Si la variable `peer` existe es porque se ha reiniciado
        // la sesión así que tenemos qque volver a compartir el token.
        if self.peer != nil && self.multipeerSession != nil
        {
            if !self.sharedTokenWithPeer
            {
                shareTokenWithAllPeers()
            }
        }
        else
        {
            self.startMultipeerSession()
        }
    }
    
    /**
        Arranca la sesión de `MultipeerConnectivity`
     
        Lo principal son los tres objetos que se crean aquí
     
        * `MCSession`: La sesión de MultipeerConnectivity
        * `MCNearbyServiceAdvertiser`: Se encarga de decir a todos que
                estamos aquí.
        * `MCNearbyServiceBrowser`: Nos dice si hay otros dispositivos
                ahí fuera.
     
        Todos estos objetos tienen sus respectivos delegados
        **donde recibimos actualizaión del estado** de todo lo relacionado
        con `MultipeerConnectivity`
     */
    private func startMultipeerSession() -> Void
    {
        if self.multipeerSession == nil
        {
            let localPeer = MCPeerID(displayName: UIDevice.current.name)
            
            self.multipeerSession = MCSession(peer: localPeer,
                                              securityIdentity: nil,
                                              encryptionPreference: .required)
            
            self.multipeerAdvertiser = MCNearbyServiceAdvertiser(peer: localPeer,
                                                     discoveryInfo: [ "identity" : serviceIdentity],
                                                     serviceType: "desappstrecerca")
            
            self.multipeerBrowser = MCNearbyServiceBrowser(peer: localPeer,
                                                           serviceType: "desappstrecerca")
            
            self.multipeerSession?.delegate = self
            self.multipeerAdvertiser?.delegate = self
            self.multipeerBrowser?.delegate = self
        }
        
        self.stopMultipeerSession()
        
        self.multipeerAdvertiser?.startAdvertisingPeer()
        self.multipeerBrowser?.startBrowsingForPeers()
    }
    
    /**
        Paramos los servicios de *advertising* y de
        *browsing* del `MultipeerConnectivity`
    */
    private func stopMultipeerSession() -> Void
    {
        self.multipeerAdvertiser?.stopAdvertisingPeer()
        self.multipeerBrowser?.stopBrowsingForPeers()
    }
    
    /**
        Desde aquí compartimos nuestro token de
        `NearbyInteraction` con los otros dispositivos.
     */
    private func shareTokenWithAllPeers() -> Void
    {
        guard let token = nearbySession?.discoveryToken,
              let multipeerSession = self.multipeerSession,
              let encodedData = try?  NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        else
        {
            fatalError("Ese token no se puede codificar. 😭")
        }

        do
        {
            try self.multipeerSession?.send(encodedData,
                                            toPeers: multipeerSession.connectedPeers,
                                            with: .reliable)
        }
        catch let error
        {
            print("No se puede enviar el token a los dispositivos. \(error.localizedDescription)")
        }
        
        // Ya hemos compartido el token.
        self.sharedTokenWithPeer = true
    }
}

//
// MARK: - NISessionDelegate protocol implementation -
//

extension WolfConnectionViewModel: NISessionDelegate {
    
    func session(_ session: NISession, didInvalidateWith error: Error) -> Void {
        self.startNearbySession()
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) -> Void {
        session.invalidate()
        self.startNearbySession()
        
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) -> Void {
        guard let nearbyObject = nearbyObjects.first else {
            return
        }
        
        self.distanceToPeer = nearbyObject.distance
        
        if let direction = nearbyObject.direction {
            self.isDirectionAvailable = true
            self.directionAngle = direction.x > 0.0 ? 90.0 : -90.0
        }
        else {
            self.isDirectionAvailable = false
        }
    }
    
    func sessionSuspensionEnded(_ session: NISession) -> Void {
        guard let peerToken = self.peerToken else {
            return
        }
        
        let config = NINearbyPeerConfiguration(peerToken: peerToken)
        
        self.nearbySession?.run(config)
        
        self.shareTokenWithAllPeers()
    }
    
    func sessionWasSuspended(_ session: NISession) -> Void {
        print("\(#function). Session Suspended")
    }
}

//
// MARK: - MCSessionDelegate protocol implementation -
//

extension WolfConnectionViewModel: MCSessionDelegate {
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("\(#function)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("\(#function)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("\(#function)")
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.peerName = peerID.displayName
                self.peer = peerID
                
                self.shareTokenWithAllPeers()
                
                self.isConnectionLost = false
                
            case .notConnected:
                self.isConnectionLost = true
                
            case .connecting:
                self.peerName = "Connecting..."
                
            @unknown default:
                fatalError("Default enum")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard peerID.displayName == self.peerName else {
            return
        }
        
        guard let discoveryToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
            fatalError("Failed to read token from another device")
        }
        
        let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
        
        self.nearbySession?.run(config)
        
        self.peerToken = discoveryToken
        
        DispatchQueue.main.async {
            self.isConnectionLost = false
        }
    }
}

//
// MARK: - MCNearbyServiceAdvertiserDelegate protocol implementation -
//

extension WolfConnectionViewModel: MCNearbyServiceAdvertiserDelegate {
    ///
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        guard let multipeerSession = self.multipeerSession else {
            return
        }
        
        if multipeerSession.connectedPeers.count < self.maxPeersInSession {
            invitationHandler(true, multipeerSession)
        }
    }
}

//
// MARK: - MCNearbyServiceBrowserDelegate protocol implementation -
//

extension WolfConnectionViewModel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if self.peerName == peerID.displayName {
            self.isConnectionLost = true
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) -> Void {
        guard let info = info,
              let identity = info["identity"],
              let multipeerSession = self.multipeerSession,
              (identity == self.serviceIdentity && multipeerSession.connectedPeers.count < self.maxPeersInSession)
        else {
            return
        }
        
        browser.invitePeer(peerID, to: multipeerSession, withContext: nil, timeout: 10)
    }
}
