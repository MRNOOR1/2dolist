import SwiftUI
import SwiftData

// MARK: - Outlined button style
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
    @Query(filter: #Predicate<Task> { $0.isCompleted == false }) private var activeTasks: [Task]
    @Query(filter: #Predicate<Task> { $0.isCompleted == true })  private var completedTasks: [Task]
    @State private var showingSettings = false
    @State private var showConfetti = false
    @Environment(AppSettings.self) private var settings
    let notificationManager = NotificationManager()

    // ── Derived forecast — always in sync with live task data ───────────────
    // Only count tasks the user actually sees as active:
    // non-repeating tasks count always; repeating tasks only count when due today.
    private var visibleActiveCount: Int {
        activeTasks.filter { task in
            !task.isRepeating || Calendar.current.isDateInToday(task.expirationDate)
        }.count
    }
    private var weather: String {
        visibleActiveCount == 0 ? "CLEAR" : (visibleActiveCount > 7 ? "STORM" : "CLOUDY")
    }
    private var forecastProgress: Double { min(Double(visibleActiveCount) / 8.0, 1.0) }

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

                        // Weather word animates when value changes
                        Text(weather)
                            .font(.system(size: 72, weight: .bold, design: .monospaced))
                            .foregroundColor(pt)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .allowsTightening(true)
                            .id(weather)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.85).combined(with: .opacity),
                                removal:   .scale(scale: 1.15).combined(with: .opacity)
                            ))
                            .animation(.easeInOut(duration: 0.35), value: weather)

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

                        Text("\(visibleActiveCount) ACTIVE  ·  \(completedTasks.count) COMPLETE")
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(st)
                            .animation(.easeInOut(duration: 0.3), value: activeTasks.count)
                            .contentTransition(.numericText())
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

                // ── Confetti overlay ───────────────────────────────────────
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(settings)
            }
        }
        .onAppear { notificationManager.askPermission() }
        .onChange(of: visibleActiveCount) { oldCount, newCount in
            if newCount == 0 && oldCount > 0 && !completedTasks.isEmpty {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    showConfetti = false
                }
            }
        }
    }
}

// MARK: - ConfettiView
struct ConfettiView: View {

    struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let color: Color
        let width: CGFloat
        let height: CGFloat
        let delay: Double
        let duration: Double
        let startRotation: Double
        let endRotation: Double
        let swayAmount: CGFloat
    }

    private static let confettiColors: [Color] = [
        Color(red: 0/255,   green: 122/255, blue: 255/255),
        Color(red: 52/255,  green: 199/255, blue: 89/255),
        Color(red: 255/255, green: 149/255, blue: 0/255),
        Color(red: 255/255, green: 45/255,  blue: 85/255),
        Color(red: 175/255, green: 82/255,  blue: 222/255),
        Color(red: 90/255,  green: 200/255, blue: 250/255),
        Color(red: 255/255, green: 214/255, blue: 10/255),
        Color(red: 0/255,   green: 199/255, blue: 190/255),
    ]

    private let particles: [Particle] = (0..<70).map { i in
        let colors = ConfettiView.confettiColors
        return Particle(
            x:             CGFloat.random(in: 0...1),
            color:         colors[i % colors.count],
            width:         CGFloat.random(in: 5...11),
            height:        CGFloat.random(in: 3...6),
            delay:         Double.random(in: 0...0.6),
            duration:      Double.random(in: 1.8...2.8),
            startRotation: Double.random(in: 0...360),
            endRotation:   Double.random(in: 360...1080),
            swayAmount:    CGFloat.random(in: -40...40)
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.width, height: p.height)
                    .rotationEffect(.degrees(animate ? p.endRotation : p.startRotation))
                    .offset(
                        x: geo.size.width * p.x + (animate ? p.swayAmount : 0),
                        y: animate ? geo.size.height + 60 : -20
                    )
                    .animation(
                        .easeIn(duration: p.duration).delay(p.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
