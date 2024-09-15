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
    @State private var isAddingTask = false
    @Query var Tasks : [Task]
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            if Tasks.isEmpty{
                ContentUnavailableView(label: {
                    Label("NO TASKS", systemImage: "list.bullet.rectangle.portrait")
                        .foregroundColor(.white)
                }, description: {
                    Text("ADD TASKS TO SEE YOUR LIST")
                        .foregroundColor(Color.green)
                }, actions: {
                    Button {
                        isAddingTask = true
                    }label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    .padding()
                    .sheet(isPresented: $isAddingTask) {
                        ZStack {
                            Color.white.edgesIgnoringSafeArea(.all)
                            AddTaskView()
                                .presentationDetents([
                                    .height(400),   // 100 points
                                    .fraction(0.5), // 20% of the available height
                                    .medium,        // Takes up about half the screen
                                    .large])        // The previously default sheet size
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                }
                                       
                )}
            
            else {
                VStack{
                    ScrollView {
                        ForEach(Tasks) { task in
                            TaskView(task: task)
                        }
                    }
                    Button {
                        isAddingTask = true
                    }label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .sheet(isPresented: $isAddingTask) {
                        ZStack {
                            Color.white.edgesIgnoringSafeArea(.all)
                            AddTaskView()
                                .presentationDetents([
                                    .height(400),   // 100 points
                                    .fraction(0.5), // 20% of the available height
                                    .medium,        // Takes up about half the screen
                                    .large])        // The previously default sheet size
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                }
            }
        }
       // .navigationBarBackButtonHidden(false)
    }
}

