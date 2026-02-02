import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Query var Tasks : [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == false }) private var activeTasks: [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == true }) private var completedTasks: [Task]
    @State var weather : String = ""
    @State private var showingSettings = false
    @State private var settings: AppSettings = AppSettings.shared
    let notificationManager = NotificationManager()
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Forecast Section
                    VStack(spacing: 12) {
                        Text("Today's Forecast")
                            .font(.system(size: 32, weight: .light, design: .serif))
                            .foregroundColor(.primary)
                        
                        Text(weather)
                            .font(.system(size: 72, weight: .semibold, design: .monospaced))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .allowsTightening(true)
                            .foregroundColor(.primary)
                    }
                    .frame(maxHeight: .infinity)
                    
                    // START Button
                    NavigationLink(destination: TaskListView()) {
                        Text("START")
                            .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            .foregroundColor(settings.getButtonTextColor(for: colorScheme))
                            .frame(width: 140, height: 140)
                            .background(Circle().fill(settings.getButtonColor(for: colorScheme)))
                            .shadow(color: settings.getButtonColor(for: colorScheme).opacity(0.3), radius: 10)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 40)
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("2DoList")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .onAppear{
            forecast()
            notificationManager.askPermission()
            print("📱 ContentView appeared. Active tasks: \(activeTasks.count), Total tasks: \(Tasks.count)")
        }
        .onChange(of: activeTasks.count) {
            forecast()
        }
        
    }
    private func forecast(){
        let activeCount = activeTasks.count
        if activeCount == 0 {
            weather = "Clear"
        }
        else if activeCount > 7 {
            weather = "Stormy"
        }
        else{
            weather = "Cloudy"
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}

