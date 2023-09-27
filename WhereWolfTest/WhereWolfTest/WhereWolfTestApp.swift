//
//  WhereWolfTestApp.swift
//  WhereWolfTest
//
//  Created by Luciano Uchoa on 24/09/23.
//

import SwiftUI
@main

struct WhereWolfTestApp: App {

    var body: some Scene {
        WindowGroup {
            TestMultipeerView(viewModel: MultipeerConnectivityViewModel())
        }
    }
}
