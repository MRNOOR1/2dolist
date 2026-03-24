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
            container = try ModelContainer(for: Task.self)
        } catch {
            do {
                let fm = FileManager.default
                let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let storeURL = appSupport.appendingPathComponent("2dolist.store")
                if fm.fileExists(atPath: storeURL.path) {
                    try fm.removeItem(at: storeURL)
                }
                let schema = Schema([Task.self])
                let config = ModelConfiguration(schema: schema, url: storeURL)
                container = try ModelContainer(for: schema, configurations: [config])
            } catch {
                do {
                    let schema = Schema([Task.self])
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: schema, configurations: [config])
                } catch {
                    fatalError("Failed to initialize model container: \(error)")
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
