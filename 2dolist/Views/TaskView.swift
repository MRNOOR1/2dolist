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
    @State private var colorIndex = 0
    private let exoticColors: [Color] = [
        // Emerald Abyss – Deep, dark green with blue undertones
        Color(red:   0/255, green: 100/255, blue:  80/255),
        // Sapphire Storm – Intense blue with violet sparks
        Color(red:  20/255, green:  50/255, blue: 180/255),
        // Blood Garnet – Lush red with hints of black
        Color(red: 120/255, green:   0/255, blue:  20/255),
        // Solar Citrine – Bright yellow-gold, glows like a lantern
        Color(red: 255/255, green: 204/255, blue:   0/255),
        // Obsidian Rose – Near-black purple with red glint
        Color(red:  40/255, green:   0/255, blue:  40/255),
        // Frozen Lapis – Icy cobalt with hints of grey
        Color(red:   0/255, green:  80/255, blue: 150/255),
        // Deep Amaranth – Bold magenta-red with rare depth
        Color(red: 155/255, green:   0/255, blue:  75/255),
        // Peacock Vein – Vivid turquoise-green
        Color(red:   0/255, green: 170/255, blue: 140/255),
        // Crushed Topaz – Metallic burnt orange
        Color(red: 204/255, green:  85/255, blue:   0/255),
        // Midnight Malachite – Saturated forest green
        Color(red:   0/255, green:  90/255, blue:  60/255),
        // Glacial Orchid – Blue-leaning pale violet
        Color(red: 115/255, green:  90/255, blue: 170/255),
        // Dragonite Bronze – Rich bronze-gold alloy
        Color(red: 160/255, green: 110/255, blue:  50/255),
        // Nocturne Cyanide – Toxic teal-blue glow
        Color(red:   0/255, green: 210/255, blue: 170/255),
        // Cursed Ruby – Blackened crimson red
        Color(red:  90/255, green:   0/255, blue:   0/255),
        // Celestial Void – Blue-black with cosmic energy
        Color(red:  10/255, green:  15/255, blue:  40/255),
        Color(red: 134/255, green:   0/255, blue:   0/255)   // <— Your Bloodstone
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
                colorIndex = (colorIndex + 1) % exoticColors.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    if task.important {
                        ImportantbackgroundColor = exoticColors[colorIndex]
                    } else {
                        task.important = true
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

