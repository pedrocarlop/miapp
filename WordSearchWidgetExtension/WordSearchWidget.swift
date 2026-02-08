//
//  WordSearchWidget.swift
//  WordSearchWidgetExtension
//

import WidgetKit
import SwiftUI
import AppIntents

@available(iOS 17.0, *)
struct WordSearchProvider: AppIntentTimelineProvider {
    typealias Intent = WordSearchWidgetConfigurationIntent
    typealias Entry = WordSearchEntry

    func placeholder(in context: Context) -> WordSearchEntry {
        WordSearchEntry(
            date: Date(),
            slot: .a,
            state: WordSearchPersistence.loadState(for: .a)
        )
    }

    func snapshot(for configuration: WordSearchWidgetConfigurationIntent, in context: Context) async -> WordSearchEntry {
        let slot = configuration.slot
        return WordSearchEntry(
            date: Date(),
            slot: slot,
            state: WordSearchPersistence.loadState(for: slot)
        )
    }

    func timeline(for configuration: WordSearchWidgetConfigurationIntent, in context: Context) async -> Timeline<WordSearchEntry> {
        let slot = configuration.slot
        let entry = WordSearchEntry(
            date: Date(),
            slot: slot,
            state: WordSearchPersistence.loadState(for: slot)
        )
        return Timeline(entries: [entry], policy: .never)
    }
}

@available(iOS 17.0, *)
struct WordSearchEntry: TimelineEntry {
    let date: Date
    let slot: WordSearchSlot
    let state: WordSearchState
}

@available(iOS 17.0, *)
struct WordSearchWidgetEntryView: View {
    let entry: WordSearchEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sopa \(entry.slot.title)")
                    .font(.headline)
                Spacer()
                Text(entry.state.progressText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            WordSearchGridWidget(slot: entry.slot, state: entry.state)
            WordsProgressWidget(state: entry.state)

            if entry.state.isCompleted {
                VStack(spacing: 6) {
                    Text("Completada")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                    AppIntentButton(ResetPuzzleIntent(slot: entry.slot)) {
                        Label("Nueva sopa", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ControlsWidget(slot: entry.slot)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@available(iOS 17.0, *)
private struct WordSearchGridWidget: View {
    let slot: WordSearchSlot
    let state: WordSearchState

    var body: some View {
        let rows = state.grid.count
        let cols = state.grid.first?.count ?? 0
        VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<cols, id: \.self) { col in
                        let ch = state.grid[row][col]
                        let selected = state.selected.contains(WordSearchPosition(r: row, c: col))
                        AppIntentButton(ToggleCellIntent(slot: slot, row: row, col: col)) {
                            Text(String(ch))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selected ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(selected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: selected ? 2 : 1)
                        )
                        .disabled(state.isCompleted)
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
private struct WordsProgressWidget: View {
    let state: WordSearchState

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(state.words.map { $0.uppercased() }, id: \.self) { word in
                HStack(spacing: 3) {
                    Image(systemName: state.foundWords.contains(word) ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 8))
                        .foregroundStyle(state.foundWords.contains(word) ? .green : .secondary)
                    Text(word)
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

@available(iOS 17.0, *)
private struct ControlsWidget: View {
    let slot: WordSearchSlot

    var body: some View {
        HStack(spacing: 10) {
            AppIntentButton(ConfirmSelectionIntent(slot: slot)) {
                Label("Comprobar", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            AppIntentButton(ResetPuzzleIntent(slot: slot)) {
                Label("Reiniciar", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .font(.caption2)
    }
}

@available(iOS 17.0, *)
struct WordSearchWidget: Widget {
    let kind: String = WordSearchConstants.widgetKind

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WordSearchWidgetConfigurationIntent.self,
            provider: WordSearchProvider()
        ) { entry in
            WordSearchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sopa de letras")
        .description("Resuelve tu sopa directamente desde la pantalla de inicio.")
        .supportedFamilies([.systemLarge])
    }
}
