//
//  RevoraApp.swift
//  Revora
//
//  Created by Patrik Repkovsky on 28/09/2026.
//

import FirebaseCore
import SwiftUI

@main
struct RevoraApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
