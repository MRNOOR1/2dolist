//
//  TaskView.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 11/5/2024.
//

import SwiftUI
import Combine
import SwiftData
import UIKit

struct TaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @Bindable var task: Task
    let isCompleted: Bool // Track if task is in completed section
    @Environment(AppSettings.self) private var settings
    
    @State private var ImportantbackgroundColor: Color = .clear
    @State private var LatebackgroundColor: Color = .yellow
    @State private var backgroundSize: CGFloat = 100
    @State private var cancellable: AnyCancellable?
    @State private var hideContent = false
    @State private var collapseWorkItem: DispatchWorkItem?
    
    private func colorForImportantIndex(_ index: Int) -> Color {
        ImportantColorPalette.color(for: index, in: settings.selectedImportantGroup)
    }
    
    // Computed property for background color based on color scheme
    private var regularBackgroundColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    // Computed property for text color based on background
    private var regularTextColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Text(task.task)
                        .frame(width: 240, alignment: .leading)
                        .font(.system(size: 22, weight: .semibold))
                        .fontDesign(.monospaced)
                        .foregroundColor(
                            isCompleted ? .gray :
                            (task.important ? .white : regularTextColor)
                        )
                        .strikethrough(isCompleted, color: .gray)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(minHeight: 50)
                    
                    Spacer()
                    
                    Image(systemName:
                        isCompleted ? "checkmark.circle.fill" :
                        (task.important ? "star.fill" : "timer")
                    )
                        .font(.system(size: 24))
                        .foregroundColor(
                            isCompleted ? .green :
                            (task.important ? .white : regularTextColor)
                        )
                    
                    if task.important && !isExpanded && !isCompleted {
                        Capsule()
                            .fill(ImportantbackgroundColor)
                            .frame(width: 14, height: 6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                
                if isExpanded && !isCompleted {
                    if task.important {
                        // Important task - full width complete button
                        Button(action: {
                            markAsComplete()
                        }) {
                            Text("COMPLETE")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .background(Color.green)
                                .cornerRadius(20)
                                .shadow(color: Color.green.opacity(0.5), radius: 3.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    } else {
                        // Regular task - complete button + timer side by side
                        HStack(spacing: 8) {
                            Button(action: {
                                markAsComplete()
                            }) {
                                Text("COMPLETE")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .background(Color.green)
                                    .cornerRadius(20)
                                    .shadow(color: Color.green.opacity(0.5), radius: 3.5)
                            }
                            
                            Text(task.formattedTime())
                                .frame(width: 100)
                                .padding(.vertical, 14)
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(20)
                                .shadow(color: Color.red.opacity(0.5), radius: 3.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
                
                // Show completion info for completed tasks
                if isExpanded && isCompleted {
                    VStack(spacing: 6) {
                        Text("✓ COMPLETED")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                        if let completedAt = task.completedAt {
                            Text(completedAt, style: .date)
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom, 8)
                }
                
            }
            .padding(.top, 4)
            .opacity(hideContent ? 0 : 1)
            .frame(maxWidth: .infinity)
            .frame(height: isExpanded ? nil : backgroundSize)
            .fixedSize(horizontal: false, vertical: isExpanded)
            .background(
                // Determine background color based on completion status
                isCompleted ? Color.gray.opacity(0.3) :
                (task.important ? ImportantbackgroundColor :
                 (task.timeRemaining < 3600 ? LatebackgroundColor : regularBackgroundColor))
            )
            .cornerRadius(20)
            .padding(.horizontal, 4)
            .onTapGesture {
                 collapseWorkItem?.cancel()
                 withAnimation(.easeInOut(duration: 0.5)) {
                   isExpanded.toggle()
                 }
                 if isExpanded {
                   let item = DispatchWorkItem {
                     withAnimation(.easeInOut(duration: 0.5)) {
                       isExpanded = false
                     }
                   }
                   collapseWorkItem = item
                     DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: item)
                 }
               }
            .highPriorityGesture(isCompleted ? nil : longPressToToggleImportant())
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if task.important {
                ImportantbackgroundColor = colorForImportantIndex(task.importantColorIndex)
            } else {
                ImportantbackgroundColor = settings.importantTaskColor.color
            }
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    private func longPressToToggleImportant() -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    if task.important {
                        // Cycle to next color index
                        task.importantColorIndex = (task.importantColorIndex + 1) % ImportantColorPalette.count(for: settings.selectedImportantGroup)
                        ImportantbackgroundColor = colorForImportantIndex(task.importantColorIndex)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } else {
                        task.important = true
                        task.importantColorIndex = 0
                        ImportantbackgroundColor = colorForImportantIndex(task.importantColorIndex)
                        if let id = task.notificationID {
                            notifications.cancelNotification(with: id)
                        }
                    }
                }
                do {
                    try context.save()
                } catch {
                    print("Failed to save important flag:", error)
                }
            }
    }

    private func startTimer() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                task.updateRemainingTime()
                if task.timeRemaining <= 0 {
                    if !task.important {
                        markAsComplete()
                    }
                    stopTimer()
                }
            }
    }
    
    
    private func stopTimer() {
        cancellable?.cancel()
    }
    
    internal func markAsComplete() {
        if let id = task.notificationID {
            notifications.cancelNotification(with: id)
        }
        withAnimation(.easeInOut(duration: 1)) {
            LatebackgroundColor = .green
            ImportantbackgroundColor = .green
            hideContent = true
        }
        withAnimation(.easeInOut(duration: 1.5)) {
            isExpanded = false
            backgroundSize = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            task.isCompleted = true
            task.completedAt = Date()
            do {
                try context.save()
            } catch {
                print("Failed to save completed state:", error)
            }
        }
    }
    
}

