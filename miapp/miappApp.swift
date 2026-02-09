//
//  miappApp.swift
//  miapp
//
//  Created by Pedro Carrasco lopez brea on 8/2/26.
//

import SwiftUI

@main
struct miappApp: App {
    @StateObject private var container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            ContentView(container: container)
        }
    }
}
