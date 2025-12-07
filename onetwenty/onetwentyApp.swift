//
//  onetwentyApp.swift
//  onetwenty
//
//  Created by sujay Chandra on 12/7/25.
//

import SwiftUI
import CoreData

@main
struct onetwentyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
