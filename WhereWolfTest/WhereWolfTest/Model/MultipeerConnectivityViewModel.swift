//
//  MultipeerConnectivityViewModel.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 27/09/23.
//

import Foundation
import MultipeerConnectivity

class MultipeerConnectivityViewModel: ObservableObject {

    public static let shared = MultipeerConnectivityViewModel()

    @Published var peersTitle = ""

    @Published var peersList = ""

    private var peersController: MultipeerConnectivityController
    private var peerCounter = [String: Int]()
    private var peerStreamed = [String: Bool]()

    init() {
        peersController = MultipeerConnectivityController.shared
        peersController.peersDelegates.append(self)
        oneSecondCounter()
    }
    deinit {
        peersController.remove(peersDelegate: self)
    }

    private func oneSecondCounter() {
        var count = Int(0)
        let myName = peersController.myName
        func loopNext() {
            count += 1

//            peersController.sendMessage(["peerName": myName, "count": count],
//                                        viaStream: true)
            peersTitle = "\(myName): \(count)"
        }
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true)  {_ in
            loopNext()
        }
    }
}
extension MultipeerConnectivityViewModel: MultipeerConnectivityControllerDelegate {

    func didChange() {

        var peerList = ""

        for (name,state) in peersController.peerState {
            peerList += "\n \(state.icon()) \(name)"

            if let count = peerCounter[name]  {
                peerList += ": \(count)"
            }
            if let streamed = peerStreamed[name] {
                peerList += streamed ? "💧" : "⚡️"
            }
        }
        self.peersList = peerList
    }


    func received(data: Data, viaStream: Bool) {

        do {
            let message = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : Any]

            if  let peerName = message["peerName"] as? String,
                let count = message["count"] as? Int {

                peersController.fixConnectedState(for: peerName)

                peerCounter[peerName] = count
                peerStreamed[peerName] = viaStream
                didChange()
            }
        }
        catch {

        }
    }

}
