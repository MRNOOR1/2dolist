import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppSettings.self) private var settings
    @State private var newTaskName: String = ""
    @State private var isImportant: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(24 * 3600)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create New Task")
                .font(.system(size: 32, weight: .bold))
                .fontDesign(.monospaced)
                .padding(.top, 24)
            
            VStack(spacing: 16) {
                TextField("Enter new task", text: $newTaskName)
                    .font(.system(size: 20, design: .monospaced))
                    .padding(16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .foregroundColor(.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.green]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(radius: 10)
                
                Toggle("IMPORTANT", isOn: $isImportant)
                    .fontDesign(.monospaced)
                    .font(.system(size: 18, weight: .semibold))
                    .tint(settings.getButtonColor(for: colorScheme))
                    .padding(.vertical, 8)

                DatePicker("DUE", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    .fontDesign(.monospaced)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(.vertical, 8)
            }
            .padding(.horizontal, 24)
            
            Button(action: {
                let task = Task(task: newTaskName, important: isImportant)
                // Assign a varied color index for important tasks
                if isImportant {
                    let count = ImportantColorPalette.count(for: settings.selectedImportantGroup)
                    task.importantColorIndex = count > 0 ? abs(task.id.hashValue) % count : 0
                }
                task.expirationDate = dueDate
                if !isImportant {
                    task.notificationID = notifications.sendNotification(taskName: newTaskName, at: dueDate)
                }
                
                print("🔵 About to insert task: \(task.task), ID: \(task.id)")
                context.insert(task)
                print("🟡 Task inserted into context")
                
                do {
                    try context.save()
                    print("✅ Task saved successfully: \(task.task)")
                    print("🟢 Context has changes: \(context.hasChanges)")
                } catch {
                    print("❌ Failed to save task: \(error)")
                }
                
                dismiss()
            }) {
                Text("CREATE")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(settings.getButtonTextColor(for: colorScheme))
                    .background(settings.getButtonColor(for: colorScheme))
                    .cornerRadius(12)
                    .shadow(radius: 5)
            }
            .disabled(newTaskName.isEmpty)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(Color(uiColor: .systemBackground))
    }
    
}

