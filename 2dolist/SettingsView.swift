//
//  SettingsView.swift
//  2dolist
//
//  Settings view for customization
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Query(filter: #Predicate<Task> { $0.isCompleted == true }) private var completedTasks: [Task]
    @State private var settings = AppSettings.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                // Important Task Color Theme Section
                Section {
                    ForEach(ColorGroup.allCases) { group in
                        Button(action: {
                            // Select the first color in the group
                            settings.importantTaskColor = group.colors.first!
                        }) {
                            HStack {
                                // Show preview of colors in the group
                                HStack(spacing: 4) {
                                    ForEach(group.colors.prefix(4)) { color in
                                        Circle()
                                            .fill(color.color)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                
                                Text(group.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if group.colors.contains(settings.importantTaskColor) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Important Task Color Theme")
                } footer: {
                    Text("Choose a color theme for tasks marked as important")
                }
                
                // Button Color Section
                Section {
                    ForEach(ButtonColorScheme.allCases) { scheme in
                        Button(action: {
                            settings.buttonColorScheme = scheme
                        }) {
                            HStack {
                                if scheme == .default {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 15, height: 15)
                                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                        
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 15, height: 15)
                                    }
                                } else {
                                    Circle()
                                        .fill(scheme.previewColor)
                                        .frame(width: 30, height: 30)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(scheme.rawValue)
                                        .foregroundColor(.primary)
                                    Text(scheme.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if settings.buttonColorScheme == scheme {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Button Color")
                } footer: {
                    Text("Default adapts to dark/light mode. Colored uses blue.")
                }
                
                // Clear Completed Tasks Section
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Label("Clear Completed Tasks", systemImage: "trash")
                            Spacer()
                            Text("\(completedTasks.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(completedTasks.isEmpty)
                } header: {
                    Text("Data Management")
                } footer: {
                    Text("Permanently delete all completed tasks")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear Completed Tasks?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete \(completedTasks.count) Tasks", role: .destructive) {
                    deleteCompletedTasks()
                }
            } message: {
                Text("This will permanently delete all \(completedTasks.count) completed tasks. This action cannot be undone.")
            }
        }
    }
    
    private func deleteCompletedTasks() {
        for task in completedTasks {
            context.delete(task)
        }
        
        do {
            try context.save()
            print("✅ Deleted \(completedTasks.count) completed tasks")
        } catch {
            print("❌ Failed to delete completed tasks: \(error)")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Task.self, inMemory: true)
}
