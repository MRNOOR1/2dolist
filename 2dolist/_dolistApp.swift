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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.colorScheme, .light)
        }
        .modelContainer(for: Task.self)
    }
}
