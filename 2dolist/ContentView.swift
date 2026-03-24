import SwiftUI
import SwiftData

// MARK: - Outlined button style used for the START button
struct OutlinedNavButtonStyle: ButtonStyle {
    let accentColor: Color
    let bgColor: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? bgColor : accentColor)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(configuration.isPressed ? accentColor : Color.clear)
            )
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(accentColor, lineWidth: 1))
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Query var tasks: [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == false }) private var activeTasks: [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == true })  private var completedTasks: [Task]
    @State private var weather: String = ""
    @State private var showingSettings = false
    @Environment(AppSettings.self) private var settings
    let notificationManager = NotificationManager()

    // ── Adaptive theme ─────────────────────────────────────────────────────
    private var bg: Color {
        colorScheme == .dark
            ? Color(red: 10/255,  green: 10/255,  blue: 10/255)
            : Color(red: 248/255, green: 247/255, blue: 245/255)
    }
    private var pt: Color {
        colorScheme == .dark
            ? Color(red: 240/255, green: 240/255, blue: 240/255)
            : Color(red: 18/255,  green: 18/255,  blue: 18/255)
    }
    private var st: Color { pt.opacity(0.4) }
    private var hl: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private var accent: Color { settings.getButtonColor(for: colorScheme) }
    private var forecastProgress: Double { min(Double(activeTasks.count) / 8.0, 1.0) }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // ── Central gauge ──────────────────────────────────────
                    VStack(spacing: 20) {
                        Text("TASK FORECAST")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(st)

                        Text(weather)
                            .font(.system(size: 72, weight: .bold, design: .monospaced))
                            .foregroundColor(pt)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .allowsTightening(true)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(hl).frame(height: 2)
                                Rectangle()
                                    .fill(accent)
                                    .frame(width: geo.size.width * forecastProgress, height: 2)
                                    .animation(.easeInOut(duration: 0.4), value: forecastProgress)
                            }
                        }
                        .frame(height: 2)

                        Text("\(activeTasks.count) ACTIVE  ·  \(completedTasks.count) COMPLETE")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(st)
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    // ── START button ───────────────────────────────────────
                    NavigationLink(destination: TaskListView()) {
                        Text("START")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .tracking(6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .buttonStyle(OutlinedNavButtonStyle(accentColor: accent, bgColor: bg))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("2DOLIST")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .foregroundColor(pt)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 15))
                            .foregroundColor(st)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
        .onAppear {
            forecast()
            notificationManager.askPermission()
        }
        .onChange(of: activeTasks.count) { _, _ in forecast() }
    }

    private func forecast() {
        let n = activeTasks.count
        weather = n == 0 ? "CLEAR" : (n > 7 ? "STORM" : "CLOUDY")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
