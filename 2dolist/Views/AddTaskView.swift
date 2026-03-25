import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppSettings.self) private var settings
    @Binding var selectedDetent: PresentationDetent

    @State private var newTaskName: String = ""
    @State private var notes: String = ""
    @State private var isImportant: Bool = false
    @State private var isRepeating: Bool = false
    @State private var dueDate: Date = Date().addingTimeInterval(24 * 3600)
    @State private var repeatDays: [Int] = []
    @FocusState private var fieldFocused: Bool

    private let dayAbbrevs = ["SUN","MON","TUE","WED","THU","FRI","SAT"]

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

    private var accent: Color     { settings.getButtonColor(for: colorScheme) }
    private var accentText: Color { settings.getButtonTextColor(for: colorScheme) }

    // ── Recurrence: first scheduled date ──────────────────────────────────
    /// Returns end-of-day (23:59:59) for the next scheduled repeat day.
    private func firstRepeatDate() -> Date {
        guard !repeatDays.isEmpty else { return Date().addingTimeInterval(86400) }
        let cal = Calendar.current
        for offset in 0...6 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let weekday = cal.component(.weekday, from: candidate) - 1
            if repeatDays.contains(weekday) {
                var dc = cal.dateComponents([.year, .month, .day], from: candidate)
                dc.hour = 23; dc.minute = 59; dc.second = 59
                if let d = cal.date(from: dc), d > Date() { return d }
            }
        }
        return cal.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
    }

    // CREATE is enabled when: name non-empty AND (not repeating, OR at least one day selected)
    private var canCreate: Bool {
        !newTaskName.isEmpty && (!isRepeating || !repeatDays.isEmpty)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Header ─────────────────────────────────────────────────
                Text("NEW TASK")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(pt)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 0) {

                        // Task name field
                        TextField("", text: $newTaskName, prompt:
                            Text("TASK NAME")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(st)
                        )
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .focused($fieldFocused)
                        .padding(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(fieldFocused ? pt.opacity(0.5) : pt.opacity(0.2), lineWidth: 1)
                        )
                        .animation(.easeInOut(duration: 0.15), value: fieldFocused)
                        .padding(.horizontal, 24)

                        // Notes field
                        TextField("", text: $notes, prompt:
                            Text("NOTES  (optional)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(st),
                            axis: .vertical
                        )
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .lineLimit(1...4)
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(pt.opacity(0.15), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        divider.padding(.vertical, 16)

                        // IMPORTANT toggle
                        row {
                            Toggle(isOn: $isImportant) {
                                Text("IMPORTANT")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .tracking(3)
                                    .foregroundColor(pt)
                            }
                            .tint(accent)
                        }

                        divider.padding(.vertical, 16)

                        // REPEATING toggle
                        row {
                            Toggle(isOn: $isRepeating.animation(.easeInOut(duration: 0.2))) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("REPEATING")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(pt)
                                    Text("Task resets to next scheduled day on completion")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(st)
                                }
                            }
                            .tint(accent)
                        }

                        if isRepeating {
                            divider.padding(.vertical, 16)

                            // Day selector
                            VStack(alignment: .leading, spacing: 10) {
                                Text("REPEAT ON")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .tracking(3)
                                    .foregroundColor(st)

                                HStack(spacing: 5) {
                                    ForEach(0..<7, id: \.self) { i in
                                        let on = repeatDays.contains(i)
                                        Button(action: {
                                            if on { repeatDays.removeAll { $0 == i } }
                                            else  { repeatDays.append(i); repeatDays.sort() }
                                        }) {
                                            Text(dayAbbrevs[i])
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 34)
                                                .foregroundColor(on ? accentText : st)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(on ? accent : Color.clear)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .stroke(on ? accent : pt.opacity(0.2), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.easeInOut(duration: 0.1), value: on)
                                    }
                                }

                                if repeatDays.isEmpty {
                                    Text("SELECT AT LEAST ONE DAY")
                                        .font(.system(size: 9, design: .monospaced))
                                        .tracking(1)
                                        .foregroundColor(Color(red: 204/255, green: 34/255, blue: 0/255).opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 24)

                        } else {
                            divider.padding(.vertical, 16)

                            // DUE DATE picker (one-time tasks only)
                            row {
                                DatePicker(selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) {
                                    Text("DUE DATE")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(pt)
                                }
                                .tint(accent)
                                .colorScheme(colorScheme == .dark ? .dark : .light)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                }
                .scrollIndicators(.hidden)

                // ── CREATE button ──────────────────────────────────────────
                Button(action: createTask) {
                    Text("CREATE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(canCreate ? accentText : accent)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(canCreate ? accent : Color.clear)
                        )
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent, lineWidth: 1))
                        .opacity(canCreate ? 1.0 : 0.35)
                }
                .disabled(!canCreate)
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.15), value: canCreate)
            }
        }
        .onChange(of: isRepeating) { _, repeating in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDetent = repeating ? .height(640) : .height(540)
            }
        }
    }

    // ── Sub-views ──────────────────────────────────────────────────────────
    private var divider: some View {
        Rectangle().fill(hl).frame(height: 1).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func row<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().padding(.horizontal, 24)
    }

    // ── Task creation logic ────────────────────────────────────────────────
    private func createTask() {
        let task = Task(task: newTaskName, important: isImportant)
        task.notes = notes

        if isImportant {
            let count = ImportantColorPalette.count(for: settings.selectedImportantGroup)
            task.importantColorIndex = count > 0 ? abs(task.id.hashValue) % count : 0
        }

        if isRepeating && !repeatDays.isEmpty {
            task.repeatDays     = repeatDays
            task.expirationDate = firstRepeatDate()
            if !isImportant {
                task.notificationID = notifications.sendNotification(taskName: newTaskName, at: task.expirationDate)
            }
        } else {
            task.expirationDate = dueDate
            if !isImportant {
                task.notificationID = notifications.sendNotification(taskName: newTaskName, at: dueDate)
            }
        }

        task.updateRemainingTime()
        context.insert(task)
        try? context.save()
        dismiss()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - EditTaskView
// ─────────────────────────────────────────────────────────────────────────────
struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppSettings.self) private var settings
    @Binding var selectedDetent: PresentationDetent
    @Bindable var task: Task

    @State private var taskName: String
    @State private var notes: String
    @State private var isImportant: Bool
    @State private var isRepeating: Bool
    @State private var dueDate: Date
    @State private var repeatDays: [Int]
    @FocusState private var fieldFocused: Bool

    private let dayAbbrevs = ["SUN","MON","TUE","WED","THU","FRI","SAT"]

    init(task: Task, selectedDetent: Binding<PresentationDetent>) {
        self.task = task
        self._selectedDetent = selectedDetent
        self._taskName    = State(initialValue: task.task)
        self._notes       = State(initialValue: task.notes)
        self._isImportant = State(initialValue: task.important)
        self._isRepeating = State(initialValue: task.isRepeating)
        self._dueDate     = State(initialValue: task.expirationDate)
        self._repeatDays  = State(initialValue: task.repeatDays)
    }

    // ── Adaptive theme ──────────────────────────────────────────────────────
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
    private var accent: Color     { settings.getButtonColor(for: colorScheme) }
    private var accentText: Color { settings.getButtonTextColor(for: colorScheme) }

    private var canSave: Bool {
        !taskName.isEmpty && (!isRepeating || !repeatDays.isEmpty)
    }

    private func firstRepeatDate() -> Date {
        guard !repeatDays.isEmpty else { return Date().addingTimeInterval(86400) }
        let cal = Calendar.current
        for offset in 0...6 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: Date()) else { continue }
            let weekday = cal.component(.weekday, from: candidate) - 1
            if repeatDays.contains(weekday) {
                var dc = cal.dateComponents([.year, .month, .day], from: candidate)
                dc.hour = 23; dc.minute = 59; dc.second = 59
                if let d = cal.date(from: dc), d > Date() { return d }
            }
        }
        return Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86400)
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {

                Text("EDIT TASK")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .tracking(6)
                    .foregroundColor(pt)
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                ScrollView {
                    VStack(spacing: 0) {

                        // Task name
                        TextField("", text: $taskName, prompt:
                            Text("TASK NAME")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(st)
                        )
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .focused($fieldFocused)
                        .padding(16)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                            .stroke(fieldFocused ? pt.opacity(0.5) : pt.opacity(0.2), lineWidth: 1))
                        .animation(.easeInOut(duration: 0.15), value: fieldFocused)
                        .padding(.horizontal, 24)

                        // Notes
                        TextField("", text: $notes, prompt:
                            Text("NOTES  (optional)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(st),
                            axis: .vertical
                        )
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .lineLimit(1...4)
                        .padding(12)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(pt.opacity(0.15), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        editDivider.padding(.vertical, 16)

                        // IMPORTANT
                        editRow {
                            Toggle(isOn: $isImportant) {
                                Text("IMPORTANT")
                                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                    .tracking(3)
                                    .foregroundColor(pt)
                            }
                            .tint(accent)
                        }

                        editDivider.padding(.vertical, 16)

                        // REPEATING
                        editRow {
                            Toggle(isOn: $isRepeating.animation(.easeInOut(duration: 0.2))) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("REPEATING")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(pt)
                                    Text("Task resets to next scheduled day on completion")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(st)
                                }
                            }
                            .tint(accent)
                        }

                        if isRepeating {
                            editDivider.padding(.vertical, 16)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("REPEAT ON")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .tracking(3)
                                    .foregroundColor(st)
                                HStack(spacing: 5) {
                                    ForEach(0..<7, id: \.self) { i in
                                        let on = repeatDays.contains(i)
                                        Button(action: {
                                            if on { repeatDays.removeAll { $0 == i } }
                                            else  { repeatDays.append(i); repeatDays.sort() }
                                        }) {
                                            Text(dayAbbrevs[i])
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 34)
                                                .foregroundColor(on ? accentText : st)
                                                .background(RoundedRectangle(cornerRadius: 3).fill(on ? accent : Color.clear))
                                                .overlay(RoundedRectangle(cornerRadius: 3).stroke(on ? accent : pt.opacity(0.2), lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        .animation(.easeInOut(duration: 0.1), value: on)
                                    }
                                }
                                if repeatDays.isEmpty {
                                    Text("SELECT AT LEAST ONE DAY")
                                        .font(.system(size: 9, design: .monospaced))
                                        .tracking(1)
                                        .foregroundColor(Color(red: 204/255, green: 34/255, blue: 0/255).opacity(0.8))
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            editDivider.padding(.vertical, 16)
                            editRow {
                                DatePicker(selection: $dueDate, displayedComponents: [.date, .hourAndMinute]) {
                                    Text("DUE DATE")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(pt)
                                }
                                .tint(accent)
                                .colorScheme(colorScheme == .dark ? .dark : .light)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                }
                .scrollIndicators(.hidden)

                Button(action: saveTask) {
                    Text("SAVE")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(canSave ? accentText : accent)
                        .background(RoundedRectangle(cornerRadius: 4).fill(canSave ? accent : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent, lineWidth: 1))
                        .opacity(canSave ? 1.0 : 0.35)
                }
                .disabled(!canSave)
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .animation(.easeInOut(duration: 0.15), value: canSave)
            }
        }
        .onChange(of: isRepeating) { _, repeating in
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDetent = repeating ? .height(640) : .height(540)
            }
        }
    }

    private var editDivider: some View {
        Rectangle().fill(hl).frame(height: 1).padding(.horizontal, 24)
    }
    @ViewBuilder
    private func editRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().padding(.horizontal, 24)
    }

    private func saveTask() {
        task.task = taskName
        task.notes = notes
        task.important = isImportant

        // Cancel existing notification before rescheduling
        if let oldID = task.notificationID {
            notifications.cancelNotification(with: oldID)
            task.notificationID = nil
        }

        if isRepeating && !repeatDays.isEmpty {
            let daysChanged = task.repeatDays != repeatDays
            task.repeatDays = repeatDays
            if daysChanged || !task.isRepeating {
                task.expirationDate = firstRepeatDate()
            }
        } else {
            task.repeatDays = []
            task.expirationDate = dueDate
        }

        if !task.important {
            task.notificationID = notifications.sendNotification(taskName: taskName, at: task.expirationDate)
        }

        task.updateRemainingTime()
        try? context.save()
        dismiss()
    }
}
