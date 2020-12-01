//
//  WT901BLECL_Demo.swift
//
//  Created by transistorgit on 26.11.20.
//

import SwiftUI

@main
struct WT901BLECL_Demo: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
