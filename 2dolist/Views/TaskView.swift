//
//  TaskView.swift
//  2dolist
//

import SwiftUI
import Combine
import SwiftData
import UIKit

struct TaskView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = false
    @Bindable var task: Task
    let isCompleted: Bool
    @Environment(AppSettings.self) private var settings

    // Preserved animation state
    @State private var ImportantbackgroundColor: Color = .clear
    @State private var LatebackgroundColor: Color = Color(red: 204/255, green: 34/255, blue: 0/255)
    @State private var backgroundSize: CGFloat = 56
    @State private var cancellable: AnyCancellable?
    @State private var hideContent = false
    @State private var collapseWorkItem: DispatchWorkItem?
    @State private var isCompletionAnimation = false
    @State private var completionGreenOpacity: Double = 0
    @State private var isEditing = false
    @State private var editDetent: PresentationDetent = .height(540)
    @State private var isFocused = false

    // ── Adaptive theme ─────────────────────────────────────────────────────
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
    private var darkRedSurf: Color {
        colorScheme == .dark
            ? Color(red: 60/255, green: 16/255, blue: 16/255)
            : Color(red: 200/255, green: 155/255, blue: 155/255)
    }
    private let lateRed    = Color(red: 204/255, green: 34/255,  blue: 0/255)
    private let missedAmber = Color(red: 200/255, green: 130/255, blue: 0/255)

    private var accent: Color     { settings.getButtonColor(for: colorScheme) }
    private var accentText: Color { settings.getButtonTextColor(for: colorScheme) }

    // ── Recurrence helper ──────────────────────────────────────────────────
    private func nextOccurrence(after from: Date, days: [Int]) -> Date? {
        guard !days.isEmpty else { return nil }
        let cal = Calendar.current
        let tc  = cal.dateComponents([.hour, .minute], from: from)
        for offset in 1...7 {
            guard let candidate = cal.date(byAdding: .day, value: offset, to: from) else { continue }
            let weekday = cal.component(.weekday, from: candidate) - 1
            if days.contains(weekday) {
                var dc = cal.dateComponents([.year, .month, .day], from: candidate)
                dc.hour = tc.hour; dc.minute = tc.minute; dc.second = 0
                return cal.date(from: dc)
            }
        }
        return nil
    }

    private func colorForImportantIndex(_ index: Int) -> Color {
        ImportantColorPalette.color(for: index, in: settings.selectedImportantGroup)
    }

    // ── Missed / day-label helpers ─────────────────────────────────────────
    private var isMissed: Bool {
        task.isRepeating && !isCompleted && task.timeRemaining < 0
    }

    private var repeatDayLabel: String {
        if task.repeatDays.count == 7 { return "DAILY" }
        let letters = ["S","M","T","W","T","F","S"]
        return task.repeatDays.sorted().map { letters[$0] }.joined(separator: "·")
    }

    // ── Left accent bar ────────────────────────────────────────────────────
    private var leftBarColor: Color {
        if isCompletionAnimation                     { return .green }
        if isCompleted                               { return Color(red: 60/255, green: 160/255, blue: 80/255) }
        if isMissed                                  { return missedAmber }
        if task.isRepeating                          { return Color.white.opacity(0.15) }
        if task.timeRemaining < 3600                 { return lateRed }
        if task.important                            { return ImportantbackgroundColor }
        return colorScheme == .dark ? Color.white.opacity(0.15) : Color.black.opacity(0.15)
    }

    var body: some View {
        HStack(spacing: 0) {

            // 3pt left bar
            Rectangle()
                .fill(leftBarColor)
                .frame(width: 3)

            VStack(spacing: 0) {

                // ── Collapsed row ──────────────────────────────────────────
                HStack(spacing: 8) {
                    if task.important && !isCompleted {
                        Text("★")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(colorForImportantIndex(task.importantColorIndex))
                    } else if isCompleted {
                        Text("✓")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(st)
                    }

                    Text(task.task)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(isCompleted ? pt.opacity(0.4) : pt)
                        .strikethrough(isCompleted, color: pt.opacity(0.3))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !isCompleted {
                        if task.isRepeating {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9))
                                    .foregroundColor(isMissed ? missedAmber : st.opacity(0.6))
                                Text(isMissed ? "MISSED" : repeatDayLabel)
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(isMissed ? missedAmber : st)
                                    .lineLimit(1)
                            }
                        } else {
                            let isOverdue = task.timeRemaining < 0
                            Text(task.formattedTime())
                                .font(.system(size: 11, weight: isOverdue ? .semibold : .regular, design: .monospaced))
                                .foregroundColor(isOverdue ? lateRed : st)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 56)

                // ── Expanded: active ───────────────────────────────────────
                if isExpanded && !isCompleted {
                    // Notes
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(st)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                    }

                    HStack(spacing: 8) {
                        if task.important || task.isRepeating {
                            Button(action: { markAsComplete() }) {
                                Text(task.isRepeating ? "DONE TODAY" : "COMPLETE")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .tracking(3)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .foregroundColor(accentText)
                                    .background(accent)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: { markAsComplete() }) {
                                Text("COMPLETE")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .tracking(3)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .foregroundColor(accentText)
                                    .background(accent)
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)

                            Text(task.formattedTime())
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .frame(width: 84)
                                .frame(height: 48)
                                .foregroundColor(pt)
                                .background(darkRedSurf)
                                .cornerRadius(4)
                        }

                        // Edit button
                        Button { collapseWorkItem?.cancel(); isEditing = true } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(st)
                                .frame(width: 48, height: 48)
                                .background(surf)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)

                    // CLOSE (repeating only) — permanently marks done, stops repeat
                    if task.isRepeating {
                        Button(action: closeTask) {
                            Text("CLOSE PERMANENTLY")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(st)
                                .frame(maxWidth: .infinity)
                                .frame(height: 32)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }

                    // FOCUS button
                    Button { collapseWorkItem?.cancel(); isFocused = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .font(.system(size: 10))
                            Text("ENTER FOCUS MODE")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .tracking(3)
                        }
                        .foregroundColor(st)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }

                // ── Expanded: completed ────────────────────────────────────
                if isExpanded && isCompleted {
                    if !task.notes.isEmpty {
                        Text(task.notes)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(st)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                    }
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("✓ COMPLETED")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .tracking(3)
                                .foregroundColor(st)
                            if let completedAt = task.completedAt {
                                Text(completedAt, style: .date)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(st.opacity(0.6))
                            }
                        }
                        Spacer()
                        Button { collapseWorkItem?.cancel(); isEditing = true } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(st)
                                .frame(width: 48, height: 48)
                                .background(surf)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(height: isExpanded ? nil : backgroundSize)
        .fixedSize(horizontal: false, vertical: isExpanded)
        .background(surf)
        .cornerRadius(4)
        .overlay(RoundedRectangle(cornerRadius: 4).fill(Color.green.opacity(completionGreenOpacity)))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(hl, lineWidth: 1))
        .clipped()
        .opacity(hideContent ? 0 : 1)
        .onTapGesture {
            collapseWorkItem?.cancel()
            withAnimation(.easeInOut(duration: 0.5)) { isExpanded.toggle() }
            if isExpanded {
                let item = DispatchWorkItem {
                    withAnimation(.easeInOut(duration: 0.5)) { isExpanded = false }
                }
                collapseWorkItem = item
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: item)
            }
        }
        .highPriorityGesture(isCompleted ? nil : longPressToToggleImportant())
        .sheet(isPresented: $isEditing, onDismiss: { editDetent = .height(540) }) {
            EditTaskView(task: task, selectedDetent: $editDetent)
                .presentationDetents([.height(540), .height(640), .large], selection: $editDetent)
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isFocused) {
            FocusView(task: task, onComplete: markAsComplete)
                .environment(settings)
        }
        .onAppear {
            ImportantbackgroundColor = task.important
                ? colorForImportantIndex(task.importantColorIndex)
                : settings.importantTaskColor.color
            if !isCompleted { startTimer() }
        }
        .onDisappear { stopTimer() }
    }

    // MARK: - Gestures
    private func longPressToToggleImportant() -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    if task.important {
                        task.importantColorIndex = (task.importantColorIndex + 1) %
                            ImportantColorPalette.count(for: settings.selectedImportantGroup)
                        ImportantbackgroundColor = colorForImportantIndex(task.importantColorIndex)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } else {
                        task.important = true
                        task.importantColorIndex = 0
                        ImportantbackgroundColor = colorForImportantIndex(task.importantColorIndex)
                        if let id = task.notificationID { notifications.cancelNotification(with: id) }
                    }
                }
                try? context.save()
            }
    }

    // MARK: - Timer
    private func startTimer() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                task.updateRemainingTime()
                if task.timeRemaining <= 0 {
                    if !task.important && !task.isRepeating { markAsComplete() }
                    stopTimer()
                }
            }
    }
    private func stopTimer() { cancellable?.cancel() }

    // MARK: - Close (permanent — stops repeating)
    private func closeTask() {
        if let id = task.notificationID { notifications.cancelNotification(with: id) }
        collapseWorkItem?.cancel()
        stopTimer()
        withAnimation(.easeInOut(duration: 0.6)) {
            completionGreenOpacity = 0.85
        }
        withAnimation(.easeInOut(duration: 1).delay(0.2)) {
            LatebackgroundColor = .green
            ImportantbackgroundColor = .green
            isCompletionAnimation = true
            hideContent = true
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.2)) {
            isExpanded = false
            backgroundSize = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            task.isCompleted = true
            task.completedAt = Date()
            try? context.save()
        }
    }

    // MARK: - Completion (timing preserved)
    internal func markAsComplete() {
        if let id = task.notificationID { notifications.cancelNotification(with: id) }
        collapseWorkItem?.cancel()

        withAnimation(.easeInOut(duration: 0.6)) {
            completionGreenOpacity = 0.85
        }
        withAnimation(.easeInOut(duration: 1).delay(0.2)) {
            LatebackgroundColor = .green
            ImportantbackgroundColor = .green
            isCompletionAnimation = true
            hideContent = true
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.2)) {
            isExpanded = false
            backgroundSize = 0
        }

        if task.isRepeating,
           let nextDate = nextOccurrence(after: task.expirationDate, days: task.repeatDays) {
            let capturedGroup = settings.selectedImportantGroup
            let capturedIndex = task.importantColorIndex
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                task.expirationDate = nextDate
                task.updateRemainingTime()
                task.notificationID = task.important
                    ? nil
                    : notifications.sendNotification(taskName: task.task, at: nextDate)
                try? context.save()
                withAnimation(.easeInOut(duration: 0.3)) {
                    completionGreenOpacity = 0
                    hideContent = false
                    backgroundSize = 56
                    isCompletionAnimation = false
                    LatebackgroundColor = lateRed
                    ImportantbackgroundColor = ImportantColorPalette.color(for: capturedIndex, in: capturedGroup)
                }
                startTimer()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                task.isCompleted = true
                task.completedAt = Date()
                try? context.save()
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - FocusView
// ─────────────────────────────────────────────────────────────────────────────
struct FocusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(AppSettings.self) private var settings
    @Bindable var task: Task
    let onComplete: () -> Void

    @State private var tick = Date()
    @State private var cancellable: AnyCancellable?
    @State private var pulse = false
    @State private var didComplete = false

    // ── Adaptive theme ──────────────────────────────────────────────────────
    private var bg: Color {
        colorScheme == .dark
            ? Color(red: 6/255, green: 6/255, blue: 6/255)
            : Color(red: 245/255, green: 244/255, blue: 242/255)
    }
    private var pt: Color {
        colorScheme == .dark
            ? Color(red: 240/255, green: 240/255, blue: 238/255)
            : Color(red: 14/255, green: 14/255, blue: 14/255)
    }
    private var st: Color { pt.opacity(0.38) }
    private var hl: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
    private var accent: Color     { settings.getButtonColor(for: colorScheme) }
    private var accentText: Color { settings.getButtonTextColor(for: colorScheme) }

    // ── Live countdown ──────────────────────────────────────────────────────
    private var timeRemaining: TimeInterval { task.expirationDate.timeIntervalSince(tick) }
    private var isOverdue: Bool  { timeRemaining < 0 }
    private var isUrgent: Bool   { timeRemaining < 3600 && !isOverdue }

    private var countdownText: String {
        if isOverdue { return "OVERDUE" }
        let t = Int(timeRemaining)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private var countdownColor: Color {
        if isOverdue { return Color(red: 204/255, green: 34/255, blue: 0/255) }
        if isUrgent  { return accent }
        return pt
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            // Glow — pulses when urgent, red when overdue
            if isUrgent || isOverdue {
                let glowColor = isOverdue
                    ? Color(red: 204/255, green: 34/255, blue: 0/255).opacity(0.07)
                    : accent.opacity(0.07)
                Circle()
                    .fill(glowColor)
                    .frame(width: 500, height: 500)
                    .scaleEffect(pulse ? 1.3 : 0.7)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                    }
            }

            VStack(spacing: 0) {

                // ── Top bar ─────────────────────────────────────────────────
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(st)
                            .frame(width: 40, height: 40)
                            .background(hl)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text("FOCUS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(5)
                        .foregroundColor(st)
                    Spacer()
                    // Balance the X button
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // ── Objective label ─────────────────────────────────────────
                Text("OBJECTIVE")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .tracking(5)
                    .foregroundColor(st)
                    .padding(.bottom, 10)

                Rectangle()
                    .fill(accent)
                    .frame(height: 1)
                    .padding(.horizontal, 48)

                // ── Task name ───────────────────────────────────────────────
                Text(task.task)
                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                    .foregroundColor(pt)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                    .padding(.top, 20)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(st)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                        .padding(.top, 8)
                }

                Spacer()

                // ── Big countdown ───────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(countdownText)
                        .font(.system(size: 52, weight: .thin, design: .monospaced))
                        .monospacedDigit()
                        .foregroundColor(countdownColor)
                        .contentTransition(.numericText())

                    if !isOverdue {
                        Text("HRS  ·  MIN  ·  SEC")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .tracking(3)
                            .foregroundColor(st)
                    }
                }

                Spacer()

                // ── Complete button ─────────────────────────────────────────
                Button {
                    guard !didComplete else { return }
                    didComplete = true
                    onComplete()
                    dismiss()
                } label: {
                    Text("COMPLETE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(accentText)
                        .background(accent)
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            cancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in tick = Date() }
        }
        .onDisappear { cancellable?.cancel() }
    }
}
