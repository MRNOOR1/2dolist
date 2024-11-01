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
    let notifications = NotificationManager()
    @State private var backgroundColor: Color = .white
    @State private var ImportantbackgroundColor: Color = .red
    @State private var LatebackgroundColor: Color = .yellow
    @State private var expandedBackgroundSize: CGFloat = 200
    @State private var backgroundSize: CGFloat = 100
    @State private var cancellable: AnyCancellable?
    
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(task.task)
                        .frame(width: 250, alignment: .leading)
                        .font(.system(size: 25, weight: .semibold))
                        .fontDesign(.monospaced)
                        .foregroundColor(task.important ? .white : .black)
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
                            Text("Complete")
                                .frame(width: task.important ? 300 : 200, height: 50)
                                .lineLimit(nil)
                                .font(.system(size: task.important ? 40 : 20, weight: .bold))
                                .foregroundColor(.white)
                                .background(Color.green)
                                .cornerRadius(15)
                                .shadow(color: Color.green.opacity(0.5), radius: 3.5)
                        }
                        if !task.important {
                            Text(task.formattedTime())
                                .frame(width: 120, height: 50)
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(.white)
                                .background(Color.red)
                                .cornerRadius(15)
                                .shadow(color: Color.red.opacity(0.5), radius: 3.5)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding(10)
            .frame(width: 350, height: isExpanded ? expandedBackgroundSize : backgroundSize)
            .font(.system(size: 30, weight: .medium))
            .background(task.important ? ImportantbackgroundColor : (task.timeRemaining < 3600 ? LatebackgroundColor : backgroundColor))
            .cornerRadius(25)
            .onTapGesture {
                withAnimation(Animation.easeInOut(duration: 0.4)) {
                    isExpanded.toggle()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                task.updateRemainingTime()
                if task.timeRemaining <= 3600 && task.timeRemaining > 3595 {
                    notifications.sendNotification(taskName: task.task)
                }
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
        withAnimation(.easeInOut(duration: 1)) {
            LatebackgroundColor = .green
            ImportantbackgroundColor = .green
            backgroundColor = .green
        }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            backgroundSize = 0
            expandedBackgroundSize = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                context.delete(task)
                do {
                    try context.save()
                } catch {
                    print("Failed to save context: \(error)")
                }
            }
        }
    }
}

