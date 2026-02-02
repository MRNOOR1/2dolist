//
//  _dolistApp.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 8/4/2024.
//

import SwiftUI
import SwiftData

@main
struct _dolistApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Create container with explicit configuration
            let schema = Schema([Task.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            print("✅ Model container initialized successfully")
        } catch {
            fatalError("❌ Failed to initialize model container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
