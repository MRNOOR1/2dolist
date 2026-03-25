//
//  TaskManager.swift
//  2dolist
//

import Foundation
import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @State private var isAddingTask = false
    @State private var searchQuery: String = ""
    @State private var showSearch = false
    @State private var addTaskDetent: PresentationDetent = .height(540)
    @State private var quickAddText: String = ""
    @State private var parsedPreview: String = ""
    @Environment(AppSettings.self) private var settings
    @Query private var tasks: [Task]
    let notifications = NotificationManager()

    enum Filter: String, CaseIterable, Identifiable {
        case active = "ACTIVE"
        case closed = "CLOSED"
        var id: String { rawValue }
    }
    @State private var selectedFilter: Filter = .active

    enum SortOrder: String, CaseIterable {
        case dueDate    = "DUE DATE"
        case importance = "IMPORTANCE"
        case name       = "NAME"
    }
    @State private var sortOrder: SortOrder = .dueDate

    // ── Adaptive theme ─────────────────────────────────────────────────────
    private var bg: Color {
        colorScheme == .dark
            ? Color(red: 10/255,  green: 10/255,  blue: 10/255)
            : Color(red: 248/255, green: 247/255, blue: 245/255)
    }
    private var surf: Color {
        colorScheme == .dark
            ? Color(red: 28/255,  green: 28/255,  blue: 28/255)
            : Color(red: 238/255, green: 237/255, blue: 235/255)
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
    private let missedAmber = Color(red: 200/255, green: 130/255, blue: 0/255)
    private let activeRed   = Color(red: 200/255, green: 55/255,  blue: 55/255)
    private let closedGreen = Color(red: 55/255,  green: 165/255, blue: 85/255)

    private var accent: Color { settings.getButtonColor(for: colorScheme) }

    // Filter tab tint: ACTIVE → red, CLOSED → green
    private func tabBg(_ filter: Filter) -> Color {
        guard selectedFilter == filter else { return Color.clear }
        return filter == .active
            ? activeRed.opacity(0.12)
            : closedGreen.opacity(0.12)
    }
    private func tabFg(_ filter: Filter) -> Color {
        guard selectedFilter == filter else { return st }
        return filter == .active ? activeRed : closedGreen
    }

    // ── Data ───────────────────────────────────────────────────────────────
    private var sortedTasks: [Task] {
        tasks.sorted { lhs, rhs in
            switch sortOrder {
            case .dueDate:
                if lhs.important != rhs.important { return lhs.important && !rhs.important }
                return lhs.expirationDate < rhs.expirationDate
            case .importance:
                if lhs.important != rhs.important { return lhs.important && !rhs.important }
                return lhs.task.localizedCaseInsensitiveCompare(rhs.task) == .orderedAscending
            case .name:
                return lhs.task.localizedCaseInsensitiveCompare(rhs.task) == .orderedAscending
            }
        }
    }

    private var visibleTasks: [Task] {
        let filtered: [Task]
        switch selectedFilter {
        case .active:
            // Exclude overdue (go to OVERDUE/MISSED sections).
            // Also hide repeating tasks scheduled for a future day — only show them when due today.
            filtered = sortedTasks.filter { task in
                !task.isCompleted &&
                task.timeRemaining >= 0 &&
                (!task.isRepeating || Calendar.current.isDateInToday(task.expirationDate))
            }
        case .closed:
            filtered = sortedTasks.filter { $0.isCompleted }
        }
        guard !searchQuery.isEmpty else { return filtered }
        return filtered.filter { $0.task.localizedCaseInsensitiveContains(searchQuery) }
    }

    private var missedRepeatTasks: [Task] {
        let base = sortedTasks.filter { !$0.isCompleted && $0.isRepeating && $0.timeRemaining < 0 }
        guard !searchQuery.isEmpty else { return base }
        return base.filter { $0.task.localizedCaseInsensitiveContains(searchQuery) }
    }

    private var overdueTasks: [Task] {
        let base = sortedTasks.filter { !$0.isCompleted && !$0.isRepeating && $0.timeRemaining < 0 }
        guard !searchQuery.isEmpty else { return base }
        return base.filter { $0.task.localizedCaseInsensitiveContains(searchQuery) }
    }

    private var activeIsEmpty: Bool {
        visibleTasks.isEmpty && missedRepeatTasks.isEmpty && overdueTasks.isEmpty
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Filter + Search toggle ─────────────────────────────────
                HStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(Filter.allCases) { filter in
                            Button(action: { selectedFilter = filter }) {
                                Text(filter.rawValue)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(tabFg(filter))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(tabBg(filter))
                            }
                            .buttonStyle(.plain)
                            .animation(.easeInOut(duration: 0.15), value: selectedFilter)
                        }
                    }
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))

                    // Sort menu
                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button(action: { sortOrder = order }) {
                                if sortOrder == order {
                                    Label(order.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(order.rawValue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(sortOrder != .dueDate ? accent : st)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .menuStyle(.automatic)

                    // Search toggle button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearch.toggle()
                            if !showSearch { searchQuery = "" }
                        }
                    }) {
                        Image(systemName: showSearch ? "magnifyingglass.circle.fill" : "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(showSearch ? accent : st)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, showSearch ? 6 : 8)

                // ── Search bar (slide-in) ──────────────────────────────────
                if showSearch {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(st)
                        TextField("", text: $searchQuery, prompt:
                            Text("SEARCH TASKS")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(st)
                        )
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .autocorrectionDisabled()
                        if !searchQuery.isEmpty {
                            Button(action: { searchQuery = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(st)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(surf)
                    .cornerRadius(4)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal:   .move(edge: .top).combined(with: .opacity)
                    ))
                }

                // ── Content ────────────────────────────────────────────────
                let isEmpty = selectedFilter == .active ? activeIsEmpty : visibleTasks.isEmpty
                if isEmpty {
                    Spacer()
                    VStack(spacing: 10) {
                        Text(selectedFilter == .active ? "ALL CLEAR" : "NOTHING HERE")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(st)
                        Text(selectedFilter == .active
                             ? (tasks.isEmpty ? "TAP + ADD TASK TO GET STARTED" : "NO ACTIVE TASKS")
                             : "COMPLETED TASKS WILL APPEAR HERE")
                            .font(.system(size: 10, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(st.opacity(0.5))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 6) {

                            ForEach(visibleTasks) { task in
                                taskRow(task)
                            }

                            // ── OVERDUE section ────────────────────────────
                            if selectedFilter == .active && !overdueTasks.isEmpty {
                                HStack(spacing: 8) {
                                    Text("OVERDUE")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(activeRed)
                                    Rectangle()
                                        .fill(activeRed.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.top, 8)
                                ForEach(overdueTasks) { task in
                                    taskRow(task)
                                }
                            }

                            // ── MISSED section ─────────────────────────────
                            if selectedFilter == .active && !missedRepeatTasks.isEmpty {
                                HStack(spacing: 8) {
                                    Text("MISSED")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .tracking(3)
                                        .foregroundColor(missedAmber)
                                    Rectangle()
                                        .fill(missedAmber.opacity(0.3))
                                        .frame(height: 1)
                                }
                                .padding(.top, 8)
                                ForEach(missedRepeatTasks) { task in
                                    taskRow(task)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                    }
                    .scrollIndicators(.hidden)
                }

                // ── Quick add bar ──────────────────────────────────────────
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        TextField("", text: $quickAddText, prompt:
                            Text("QUICK ADD…  e.g. dentist tomorrow 3pm")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(st.opacity(0.6))
                        )
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(pt)
                        .tint(accent)
                        .autocorrectionDisabled()
                        .onSubmit { quickAddTask() }
                        .onChange(of: quickAddText) { _, val in
                            parsedPreview = val.trimmingCharacters(in: .whitespaces).isEmpty
                                ? "" : nlpPreview(val)
                        }
                        if !quickAddText.isEmpty {
                            Button(action: quickAddTask) {
                                Image(systemName: "return")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(accent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .padding(.bottom, parsedPreview.isEmpty ? 10 : 4)

                    if !parsedPreview.isEmpty {
                        Text(parsedPreview)
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(1)
                            .foregroundColor(accent.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                            .transition(.opacity)
                    }
                }
                .background(surf)
                .cornerRadius(4)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .animation(.easeInOut(duration: 0.15), value: parsedPreview.isEmpty)

                // ── Add task button ────────────────────────────────────────
                Button { isAddingTask = true } label: {
                    Text("+ ADD TASK")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(accent)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(accent, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .sheet(isPresented: $isAddingTask, onDismiss: { addTaskDetent = .height(540) }) {
                    AddTaskView(selectedDetent: $addTaskDetent)
                        .presentationDetents([.height(540), .height(640), .large], selection: $addTaskDetent)
                        .presentationDragIndicator(.visible)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear { }
    }

    // ── Quick add ──────────────────────────────────────────────────────────
    private func quickAddTask() {
        let raw = quickAddText.trimmingCharacters(in: .whitespaces)
        guard !raw.isEmpty else { return }
        let parsed = parseNL(raw)
        let t = Task(task: parsed.name)
        t.expirationDate = parsed.date
        t.updateRemainingTime()
        t.notificationID = notifications.sendNotification(taskName: parsed.name, at: parsed.date)
        context.insert(t)
        try? context.save()
        quickAddText = ""
        parsedPreview = ""
    }

    // ── Natural language parser ────────────────────────────────────────────

    /// Pre-process: normalise a.m./p.m. → am/pm, then merge "3 pm" → "3pm".
    private func normaliseWords(_ raw: [String]) -> [String] {
        // Step 1 — normalise a.m. / p.m. → am / pm
        let step1 = raw.map { w -> String in
            let l = w.lowercased()
            if l == "a.m." || l == "am." { return "am" }
            if l == "p.m." || l == "pm." { return "pm" }
            return w
        }
        // Step 2 — merge "10" "pm" → "10pm" and "10:30" "am" → "10:30am"
        let digitTime = try? NSRegularExpression(pattern: "^\\d{1,2}(?::\\d{2})?$")
        var result: [String] = []
        var i = 0
        while i < step1.count {
            let w = step1[i]
            if i + 1 < step1.count {
                let next = step1[i + 1].lowercased()
                if (next == "am" || next == "pm"),
                   let re = digitTime,
                   re.firstMatch(in: w, range: NSRange(w.startIndex..., in: w)) != nil {
                    result.append(w + next)   // "3pm", "10:30am"
                    i += 2; continue
                }
            }
            result.append(w)
            i += 1
        }
        return result
    }

    private func parseNL(_ raw: String) -> (name: String, date: Date) {
        let words = normaliseWords(raw.components(separatedBy: " ").filter { !$0.isEmpty })
        let cal = Calendar.current
        let now = Date()
        var targetDate = cal.date(byAdding: .day, value: 1, to: now)!
        var hour: Int? = nil
        var minute = 0
        var remove = IndexSet()
        let weekdays = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]

        var i = 0
        while i < words.count {
            let w = words[i].lowercased()
            switch w {
            case "today":
                targetDate = now; remove.insert(i)
            case "tomorrow":
                targetDate = cal.date(byAdding: .day, value: 1, to: now)!; remove.insert(i)
            case "noon":
                hour = 12; minute = 0; remove.insert(i)
            case "midnight":
                hour = 0; minute = 0; remove.insert(i)
            case "morning":
                hour = 9;  minute = 0; remove.insert(i)
            case "afternoon":
                hour = 14; minute = 0; remove.insert(i)
            case "evening":
                hour = 19; minute = 0; remove.insert(i)
            case "night":
                hour = 21; minute = 0; remove.insert(i)
            case "at":
                if i + 1 < words.count {
                    let next = words[i + 1].lowercased()
                    if next == "noon" {
                        hour = 12; minute = 0; remove.insert(i); remove.insert(i+1); i += 1
                    } else if next == "midnight" {
                        hour = 0; minute = 0; remove.insert(i); remove.insert(i+1); i += 1
                    } else if let t = nlTime(words[i + 1]) {
                        hour = t.0; minute = t.1; remove.insert(i); remove.insert(i+1); i += 1
                    }
                }
            case "next":
                if i + 1 < words.count, let di = weekdays.firstIndex(of: words[i+1].lowercased()) {
                    let today = cal.component(.weekday, from: now) - 1
                    var diff = (di - today + 7) % 7; if diff == 0 { diff = 7 }
                    targetDate = cal.date(byAdding: .day, value: diff, to: now)!
                    remove.insert(i); remove.insert(i+1); i += 1
                }
            case "in":
                if i + 2 < words.count, let n = Int(words[i+1]) {
                    let unit = words[i+2].lowercased()
                    if unit.hasPrefix("day") {
                        targetDate = cal.date(byAdding: .day, value: n, to: now)!
                        remove.insert(i); remove.insert(i+1); remove.insert(i+2); i += 2
                    } else if unit.hasPrefix("hour") || unit.hasPrefix("hr") {
                        // Use the actual future timestamp — preserves day crossing
                        let future = now.addingTimeInterval(Double(n) * 3600)
                        targetDate = future
                        hour = cal.component(.hour, from: future)
                        minute = cal.component(.minute, from: future)
                        remove.insert(i); remove.insert(i+1); remove.insert(i+2); i += 2
                    } else if unit.hasPrefix("min") {
                        let future = now.addingTimeInterval(Double(n) * 60)
                        targetDate = future
                        hour = cal.component(.hour, from: future)
                        minute = cal.component(.minute, from: future)
                        remove.insert(i); remove.insert(i+1); remove.insert(i+2); i += 2
                    }
                }
            default:
                if let t = nlTime(w) {
                    hour = t.0; minute = t.1; remove.insert(i)
                } else if let di = weekdays.firstIndex(of: w) {
                    let today = cal.component(.weekday, from: now) - 1
                    var diff = (di - today + 7) % 7; if diff == 0 { diff = 7 }
                    targetDate = cal.date(byAdding: .day, value: diff, to: now)!
                    remove.insert(i)
                }
            }
            i += 1
        }

        // Combine the resolved day with the resolved time
        var dc = cal.dateComponents([.year, .month, .day], from: targetDate)
        dc.hour = hour ?? 9; dc.minute = minute; dc.second = 0
        let finalDate = cal.date(from: dc) ?? targetDate

        let name = words.enumerated()
            .filter { !remove.contains($0.offset) }
            .map { $0.element }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        return (name.isEmpty ? raw : name, finalDate)
    }

    /// Parse a single token into (hour, minute). Handles:
    ///   attached am/pm  → "3pm" "10:30AM" "3PM"
    ///   24-hour         → "15:00" "09:30"
    private func nlTime(_ word: String) -> (Int, Int)? {
        let w = word.lowercased()
        // "3pm", "11am", "3:30pm", "10:00am" — case-insensitive via lowercased()
        if let m = try? NSRegularExpression(pattern: "^(\\d{1,2})(?::(\\d{2}))?(am|pm)$")
            .firstMatch(in: w, range: NSRange(w.startIndex..., in: w)) {
            let ns = w as NSString
            var h = Int(ns.substring(with: m.range(at: 1))) ?? 0
            let min = m.range(at: 2).length > 0 ? (Int(ns.substring(with: m.range(at: 2))) ?? 0) : 0
            let ap  = m.range(at: 3).length > 0 ? ns.substring(with: m.range(at: 3)) : ""
            if ap == "pm" && h < 12 { h += 12 }
            if ap == "am" && h == 12 { h = 0 }
            return (h, min)
        }
        // "15:00", "09:30" — 24-hour, no am/pm suffix
        if let m = try? NSRegularExpression(pattern: "^([01]?\\d|2[0-3]):(\\d{2})$")
            .firstMatch(in: w, range: NSRange(w.startIndex..., in: w)) {
            let ns = w as NSString
            let h   = Int(ns.substring(with: m.range(at: 1))) ?? 0
            let min = Int(ns.substring(with: m.range(at: 2))) ?? 0
            return (h, min)
        }
        return nil
    }

    /// Human-readable preview of the detected date, shown beneath the quick-add bar.
    private func nlpPreview(_ raw: String) -> String {
        let (_, date) = parseNL(raw)
        let cal = Calendar.current
        let df = DateFormatter()
        let dayStr: String
        if cal.isDateInToday(date)     { dayStr = "TODAY" }
        else if cal.isDateInTomorrow(date) { dayStr = "TOMORROW" }
        else { df.dateFormat = "EEE d MMM"; dayStr = df.string(from: date).uppercased() }
        df.dateFormat = "h:mm a"
        return "→  \(dayStr)  ·  \(df.string(from: date).uppercased())"
    }

    // ── Shared row builder ─────────────────────────────────────────────────
    @ViewBuilder
    private func taskRow(_ task: Task) -> some View {
        TaskView(task: task, isCompleted: task.isCompleted)
            .swipeActions(edge: .leading) {
                // Repeating tasks must use DONE TODAY inside the card — swipe bypasses rescheduling
                if !task.isCompleted && !task.isRepeating {
                    Button {
                        task.isCompleted = true
                        task.completedAt = Date()
                        if let id = task.notificationID { notifications.cancelNotification(with: id) }
                        try? context.save()
                    } label: { Label("Close", systemImage: "checkmark") }
                    .tint(closedGreen)
                }
            }
            .swipeActions(edge: .trailing) {
                if selectedFilter == .active || task.isRepeating {
                    Button(role: .destructive) {
                        context.delete(task)
                        try? context.save()
                    } label: { Label("Delete", systemImage: "trash") }

                    Button {
                        task.important.toggle()
                        try? context.save()
                    } label: {
                        Label("Important", systemImage: task.important ? "star.slash" : "star")
                    }
                } else {
                    Button {
                        task.isCompleted = false
                        task.completedAt = nil
                        try? context.save()
                    } label: { Label("Restore", systemImage: "arrow.uturn.left") }
                }
            }
    }
}
