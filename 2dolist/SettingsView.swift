//
//  SettingsView.swift
//  2dolist
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) var context
    @Environment(\.colorScheme) var colorScheme
    @Query(filter: #Predicate<Task> { $0.isCompleted == true }) private var completedTasks: [Task]
    @State private var settings = AppSettings.shared
    @State private var showingDeleteAlert = false

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

    private var accent: Color     { settings.getButtonColor(for: colorScheme) }
    private var accentText: Color { settings.getButtonTextColor(for: colorScheme) }

    // Short name: "Reds & Crimsons" → "REDS"
    private func shortName(_ g: ColorGroup) -> String {
        g.rawValue.components(separatedBy: " ").first?.uppercased() ?? g.rawValue.uppercased()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {

                        // ── IMPORTANT PALETTE ──────────────────────────────
                        section("IMPORTANT PALETTE") {
                            LazyVGrid(
                                columns: [GridItem(.flexible(), spacing: 6),
                                          GridItem(.flexible(), spacing: 6)],
                                spacing: 6
                            ) {
                                ForEach(ColorGroup.allCases) { group in
                                    let sel = settings.selectedImportantGroup == group
                                    Button(action: {
                                        settings.selectedImportantGroup = group
                                        if let first = group.colors.first {
                                            settings.importantTaskColor = first
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            HStack(spacing: 3) {
                                                ForEach(group.colors.prefix(4)) { c in
                                                    Circle().fill(c.color).frame(width: 10, height: 10)
                                                }
                                            }
                                            Text(shortName(group))
                                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                                .foregroundColor(sel ? pt : st)
                                                .lineLimit(1)
                                            Spacer(minLength: 0)
                                            if sel {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(accent)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 9)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(surf))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(sel ? accent : hl, lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.1), value: sel)
                                }
                            }
                        }

                        // ── ACCENT COLOR ───────────────────────────────────
                        section("ACCENT COLOR") {
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6),
                                spacing: 10
                            ) {
                                ForEach(ButtonColorScheme.allCases) { scheme in
                                    let sel = settings.buttonColorScheme == scheme
                                    Button(action: { settings.buttonColorScheme = scheme }) {
                                        ZStack {
                                            Circle()
                                                .fill(scheme == .default
                                                    ? (colorScheme == .dark ? Color.white : Color.black)
                                                    : scheme.previewColor)
                                                .frame(width: 28, height: 28)
                                            Circle()
                                                .stroke(sel ? accent : hl,
                                                        lineWidth: sel ? 2.5 : 1)
                                                .frame(width: 28, height: 28)
                                            if sel {
                                                Circle()
                                                    .stroke(bg, lineWidth: 2)
                                                    .frame(width: 22, height: 22)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.easeInOut(duration: 0.1), value: sel)
                                }
                            }
                            // Selected scheme name
                            HStack(spacing: 6) {
                                Text(settings.buttonColorScheme.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .tracking(2)
                                    .foregroundColor(accent)
                                Text("·")
                                    .foregroundColor(st)
                                Text(settings.buttonColorScheme.description)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(st)
                            }
                            .padding(.top, 4)
                        }

                        // ── DATA ───────────────────────────────────────────
                        section("DATA") {
                            Button(action: { showingDeleteAlert = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(completedTasks.isEmpty ? st : .red)
                                    Text("CLEAR COMPLETED TASKS")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .tracking(1)
                                        .foregroundColor(completedTasks.isEmpty ? st : .red)
                                    Spacer()
                                    if !completedTasks.isEmpty {
                                        Text("\(completedTasks.count)")
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(st)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(RoundedRectangle(cornerRadius: 3).fill(surf))
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 4).fill(surf))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(completedTasks.isEmpty ? hl : Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(completedTasks.isEmpty)
                        }

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundColor(pt)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(accent)
                }
            }
            .alert("Clear Completed Tasks?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete \(completedTasks.count) Tasks", role: .destructive) {
                    for task in completedTasks { context.delete(task) }
                    try? context.save()
                }
            } message: {
                Text("Permanently deletes all \(completedTasks.count) completed tasks.")
            }
        }
    }

    @ViewBuilder
    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(3)
                .foregroundColor(st)
            content()
        }
    }
}
