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
                // Important Task Color Section - Grouped by Theme
                ForEach(ColorGroup.allCases) { group in
                    Section(header: Text(group.rawValue)) {
                        ForEach(group.colors) { taskColor in
                            Button(action: {
                                settings.importantTaskColor = taskColor
                            }) {
                                HStack {
                                    Circle()
                                        .fill(taskColor.color)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    Text(taskColor.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if settings.importantTaskColor == taskColor {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
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
                                        .fill(Color.blue)
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
                    Text("Button background and text color will adapt based on your selection.")
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
