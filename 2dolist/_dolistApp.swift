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
            // First, try default container which supports lightweight migrations
            container = try ModelContainer(for: Task.self)
            print("✅ Model container initialized successfully")
        } catch {
            print("⚠️ Default container init failed: \(error). Attempting store reset and retry…")
            // Attempt to remove existing store and retry
            do {
                // Build a predictable store URL in Application Support
                let fm = FileManager.default
                let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let storeURL = appSupport.appendingPathComponent("2dolist.store")
                if fm.fileExists(atPath: storeURL.path) {
                    try fm.removeItem(at: storeURL)
                    print("🧹 Removed existing store at: \(storeURL)")
                }
                // Recreate container with explicit configuration at this URL
                let schema = Schema([Task.self])
                let config = ModelConfiguration(schema: schema, url: storeURL)
                container = try ModelContainer(for: schema, configurations: [config])
                print("✅ Model container re-initialized after store reset")
            } catch {
                print("❌ Store reset path failed: \(error). Falling back to in-memory store…")
                // Final fallback: in-memory store to unblock development
                do {
                    let schema = Schema([Task.self])
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: schema, configurations: [config])
                    print("✅ In-memory model container initialized (no persistence)")
                } catch {
                    fatalError("❌ Failed to initialize even in-memory model container: \(error)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(AppSettings.shared)
        }
        .modelContainer(container)
    }
}
