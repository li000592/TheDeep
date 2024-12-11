//
//  TheDeepApp.swift
//  TheDeep
//
//  Created by Haorong Li on 2024-12-10.
//

import SwiftUI

@main
struct TheDeepApp: App {
    init() {
        requestHealthKitAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
