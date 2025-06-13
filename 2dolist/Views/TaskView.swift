//
//  TaskView.swift
//  2dolist
//
//  Created by Mohammad Rasoul Noori on 11/5/2024.
//


import SwiftUI
import Combine
import SwiftData

struct TaskView: View {
    @Environment(\.modelContext) private var context
    @State private var isExpanded = false
    @Bindable var task = Task()
    @State private var backgroundColor: Color = .white
    @State private var ImportantbackgroundColor: Color = Color("important")
    @State private var LatebackgroundColor: Color = .yellow
    @State private var backgroundSize: CGFloat = 100
    @State private var cancellable: AnyCancellable?
    @State private var hideContent = false
    @State private var collapseWorkItem: DispatchWorkItem?
    
    private let exoticColors: [Color] = [
        // A rich emerald green
        Color(red: 0/255,   green: 128/255, blue: 96/255),  // “Emerald Heart”

        // A dark teal with depth
        Color(red: 0/255,   green: 105/255, blue: 92/255),  // “Deep Teal”

        // A brilliant sapphire blue
        Color(red: 15/255,  green: 82/255,  blue: 186/255), // “Sapphire Dream”

        // A royal midnight blue
        Color(red: 0/255,   green: 53/255,  blue: 128/255), // “Royal Night”

        // A true metallic gold
        Color(red: 212/255, green: 175/255, blue: 55/255),  // “Golden Opulence”

        // A warm amber-gold
        Color(red: 255/255, green: 193/255, blue: 7/255),   // “Amber Sunset”

        // A bright turquoise for contrast
        Color(red: 64/255,  green: 224/255, blue: 208/255), // “Tropical Turquoise”

        // A vivid teal-blue hybrid
        Color(red: 0/255,   green: 150/255, blue: 199/255)  // “Ocean Jewel”
    ]


    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(task.task)
                        .frame(width: 250, alignment: .leading)
                        .font(.system(size: 25, weight: .semibold))
                        .fontDesign(.monospaced)
                        .foregroundColor(task.important ? .white : .black)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .frame(minHeight: 60)
                    Image(systemName: task.important ? "star.fill" : "timer")
                        .frame(width: 50)
                        .foregroundColor(task.important ? .white : .black)
                }
                .padding()
                
                if isExpanded {
                    HStack {
                        Button(action: {
                            markAsComplete()
                        }) {
                            Text("COMPLETE")
                                .frame(width: task.important ? 300 : 200, height: 60)
                                .lineLimit(nil)
                                .font(.system(size: task.important ? 40 : 20, weight: .bold))
                                .foregroundColor(.white)
                                .background(Color.green)
                                .cornerRadius(25)
                                .shadow(color: Color.green.opacity(0.5), radius: 3.5)
                        }
                        if !task.important {
                            Text(task.formattedTime())
                                .frame(width: 120, height: 60)
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(25)
                                .shadow(color: Color.red.opacity(0.5), radius: 3.5)
                        }
                    }
                    .padding(.top)
                }
                
            }
            .padding(.bottom, 10)
            .opacity(hideContent ? 0 : 1)
            .frame(width: 350)
            .frame(height: isExpanded ? nil : backgroundSize)
            .fixedSize(horizontal: false, vertical: isExpanded)
            .font(.system(size: 30, weight: .medium))
            .background(task.important ? ImportantbackgroundColor : (task.timeRemaining < 3600 ? LatebackgroundColor : backgroundColor))
            .cornerRadius(25)
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
            .highPriorityGesture(longPressToToggleImportant())
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
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
                        ImportantbackgroundColor = exoticColors.randomElement()!
                    } else {
                        task.important = true
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
            backgroundColor = .green
            LatebackgroundColor = .green
            ImportantbackgroundColor = .green
            hideContent = true
        }
        withAnimation(.easeInOut(duration: 1.5)) {
            isExpanded = false
            backgroundSize = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation() {
                context.delete(task)
                try? context.save()
            }
        }
    }
    
}

