//
//  TaskManager.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 20/7/2024.
//

import Foundation
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedTaskID: UUID?
    @State private var isAddingTask = false
    @State private var searchQuery: String = ""
    @State private var settings = AppSettings.shared
    @Query var Tasks : [Task]
    let notifications = NotificationManager()
    
    enum Filter: String, CaseIterable, Identifiable { case active = "Active", completed = "Completed"; var id: String { rawValue } }
    @State private var selectedFilter: Filter = .active
    
    private var sortedTasks: [Task] {
        Tasks.sorted { (lhs, rhs) in
            if lhs.important != rhs.important { return lhs.important && !rhs.important }
            return lhs.expirationDate < rhs.expirationDate
        }
    }

    private var visibleTasks: [Task] {
        // First filter by completion status
        let filtered: [Task]
        switch selectedFilter {
        case .active:
            filtered = sortedTasks.filter { !$0.isCompleted }
        case .completed:
            filtered = sortedTasks.filter { $0.isCompleted }
        }
        
        // Then apply search query if present
        guard !searchQuery.isEmpty else { return filtered }
        return filtered.filter { $0.task.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
            if Tasks.isEmpty{
                ContentUnavailableView(label: {
                    Label("NO TASKS", systemImage: "list.bullet.rectangle.portrait")
                }, description: {
                    Text("ADD TASKS TO SEE YOUR LIST")
                        .foregroundColor(colorScheme == .dark ? Color(red: 223/255, green: 255/255, blue: 0/255) : Color(red: 0/255, green: 100/255, blue: 0/255))
                        .fontWeight(.bold)
                }, actions: {
                    Button {
                        isAddingTask = true
                    }label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(settings.getButtonColor(for: colorScheme))
                    }
                    
                    .padding()
                    .sheet(isPresented: $isAddingTask) {
                        AddTaskView()
                            .presentationDetents([
                                .height(480),
                                .medium,
                                .large])
                            .presentationDragIndicator(.visible)
                    }
                }
                                       
                )}
            
            else {
                VStack(spacing: 0) {
                    // Custom Filter Picker with colored text
                    HStack(spacing: 0) {
                        Button(action: {
                            selectedFilter = .active
                        }) {
                            Text("Active")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(selectedFilter == .active ? .white : .red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedFilter == .active ? Color.red : Color.clear)
                                .contentShape(Rectangle())
                        }
                        
                        Button(action: {
                            selectedFilter = .completed
                        }) {
                            Text("Completed")
                                .font(.system(size: 16, weight: .semibold, design: .default))
                                .foregroundColor(selectedFilter == .completed ? .white : .green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(selectedFilter == .completed ? Color.green : Color.clear)
                                .contentShape(Rectangle())
                        }
                    }
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Task List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(visibleTasks) { task in
                                TaskView(task: task, isCompleted: task.isCompleted)
                                .swipeActions(edge: .leading) {
                                    if !task.isCompleted {
                                        Button {
                                            task.isCompleted = true
                                            task.completedAt = Date()
                                            if let id = task.notificationID {
                                                notifications.cancelNotification(with: id)
                                            }
                                            try? context.save()
                                        } label: {
                                            Label("Complete", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    if selectedFilter == .active {
                                        Button(role: .destructive) {
                                            context.delete(task)
                                            try? context.save()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        Button {
                                            task.important.toggle()
                                            try? context.save()
                                        } label: {
                                            Label("Important", systemImage: task.important ? "star.slash" : "star")
                                        }
                                    } else {
                                        Button {
                                            task.isCompleted = false
                                            task.completedAt = nil
                                            try? context.save()
                                        } label: {
                                            Label("Restore", systemImage: "arrow.uturn.left")
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 12)
                    }
                    .searchable(text: $searchQuery, placement: .automatic, prompt: "Search tasks")
                    .scrollIndicators(.hidden)
                    
                    // Add Task Button
                    Button {
                        isAddingTask = true
                    }label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(settings.getButtonColor(for: colorScheme))
                    }
                    .padding(.vertical, 16)
                    .sheet(isPresented: $isAddingTask) {
                        AddTaskView()
                            .presentationDetents([
                                .height(480),
                                .medium,
                                .large])
                            .presentationDragIndicator(.visible)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            print("📋 TaskListView appeared. Total tasks: \(Tasks.count)")
            for task in Tasks {
                print("  - Task: \(task.task), ID: \(task.id), Completed: \(task.isCompleted)")
            }
            
            // Try to fetch manually to debug
            let descriptor = FetchDescriptor<Task>()
            do {
                let allTasks = try context.fetch(descriptor)
                print("🔍 Manual fetch found \(allTasks.count) tasks")
                for task in allTasks {
                    print("  - Manual: \(task.task), ID: \(task.id)")
                }
            } catch {
                print("❌ Manual fetch error: \(error)")
            }
        }
    }
}

