import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @State private var newTaskName: String = ""
    @State private var isImportant: Bool = false
    
    var body: some View {
        VStack {
            Text("Create New Task")
                .frame(width: 330, height: 80)
                .font(.system(size: 30))
                .fontDesign(.monospaced)
                .padding(.bottom)
            VStack{
                TextField("Enter new task", text: $newTaskName)
                    .frame(width: 330, height: 50)
                    .font(.system(size: 20, design: .monospaced))
                    .padding(.leading, 10)
                    .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.red]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .cornerRadius(10)
                    .padding(5)
                    .foregroundColor(.black)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(LinearGradient(gradient: Gradient(colors: [Color.red, Color.green]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2.5))
                    .shadow(radius: 10)
                
                Toggle("IMPORTANT", isOn: $isImportant)
                    .fontDesign(.monospaced)
                    .tint(.black)
                    .frame(width: 330, height: 50)
                    .padding(5)
                
                
            }
            .padding()
            Button(action: {
                let task = Task(task: newTaskName, important: isImportant)
                context.insert(task)
                dismiss()
            }) {
                Text("CREATE")
                    .frame(width: 330, height: 50)
                    .font(.system(size: 25))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
            .disabled(newTaskName.isEmpty)
            .padding(.top)
            
        }
        .frame(width: 400, height: 300)
        .background(Color.white)
        .environment(\.colorScheme, .light)
    }
    
}

