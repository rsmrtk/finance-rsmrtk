//
//  finance_rsmrtkApp.swift
//  finance-rsmrtk
//
//  Created by rsmrtk on 11.09.2026.
//

import SwiftUI
import SwiftData

@main
struct finance_rsmrtkApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(AppModelContainer.shared)
    }
}
