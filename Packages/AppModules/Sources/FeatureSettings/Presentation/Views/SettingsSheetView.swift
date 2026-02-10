import SwiftUI
import Core
import DesignSystem

public struct SettingsSheetValues: Equatable {
    public var gridSize: Int
    public var appearanceMode: AppearanceMode
    public var wordHintMode: WordHintMode
    public var dailyRefreshMinutes: Int
    public var enableCelebrations: Bool
    public var enableHaptics: Bool
    public var enableSound: Bool
    public var celebrationIntensity: CelebrationIntensity

    public init(
        gridSize: Int,
        appearanceMode: AppearanceMode,
        wordHintMode: WordHintMode,
        dailyRefreshMinutes: Int,
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        celebrationIntensity: CelebrationIntensity
    ) {
        self.gridSize = gridSize
        self.appearanceMode = appearanceMode
        self.wordHintMode = wordHintMode
        self.dailyRefreshMinutes = dailyRefreshMinutes
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.celebrationIntensity = celebrationIntensity
    }
}

public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gridSize: Int
    @State private var appearanceMode: AppearanceMode
    @State private var wordHintMode: WordHintMode
    @State private var dailyRefreshTime: Date
    @State private var enableCelebrations: Bool
    @State private var enableHaptics: Bool
    @State private var enableSound: Bool
    @State private var celebrationIntensity: CelebrationIntensity

    private let onSave: (SettingsSheetValues) -> Void

    public init(
        values: SettingsSheetValues,
        onSave: @escaping (SettingsSheetValues) -> Void
    ) {
        _gridSize = State(initialValue: min(max(values.gridSize, WordSearchConfig.minGridSize), WordSearchConfig.maxGridSize))
        _appearanceMode = State(initialValue: values.appearanceMode)
        _wordHintMode = State(initialValue: values.wordHintMode)
        _dailyRefreshTime = State(
            initialValue: DailyRefreshClock.date(
                for: DailyRefreshClock.clampMinutes(values.dailyRefreshMinutes),
                reference: Date()
            )
        )
        _enableCelebrations = State(initialValue: values.enableCelebrations)
        _enableHaptics = State(initialValue: values.enableHaptics)
        _enableSound = State(initialValue: values.enableSound)
        _celebrationIntensity = State(initialValue: values.celebrationIntensity)
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Dificultad") {
                    Stepper(value: $gridSize, in: WordSearchConfig.minGridSize...WordSearchConfig.maxGridSize) {
                        Text("Tamano de sopa: \(gridSize)x\(gridSize)")
                    }
                    Text("A mayor tamano, mas dificultad. En el widget las letras y el area tactil se reducen para que entre la cuadricula.")
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                    Text("El nuevo tamano solo se aplica a retos futuros. Los retos ya creados mantienen su tamano para no perder progreso.")
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                Section("Apariencia") {
                    Picker("Tema", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(appearanceTitle(for: mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Pistas") {
                    Picker("Modo", selection: $wordHintMode) {
                        ForEach(WordHintMode.allCases, id: \.self) { mode in
                            Text(wordHintTitle(for: mode)).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("En definicion, veras la descripcion sin mostrar la palabra.")
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                Section("Horario") {
                    DatePicker(
                        "Nueva sopa del dia",
                        selection: $dailyRefreshTime,
                        displayedComponents: .hourAndMinute
                    )
                    Text("Por defecto se renueva a las 09:00.")
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }

                Section("Celebraciones") {
                    Toggle("Animaciones de celebracion", isOn: $enableCelebrations)
                    Toggle("Haptics", isOn: $enableHaptics)
                    Toggle("Sonido", isOn: $enableSound)
                    Picker("Intensidad", selection: $celebrationIntensity) {
                        ForEach(CelebrationIntensity.allCases, id: \.self) { intensity in
                            Text(celebrationTitle(for: intensity)).tag(intensity)
                        }
                    }
                    Text("Si Reduce Motion esta activo, se desactivan las particulas.")
                        .font(TypographyTokens.footnote)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(
                            SettingsSheetValues(
                                gridSize: gridSize,
                                appearanceMode: appearanceMode,
                                wordHintMode: wordHintMode,
                                dailyRefreshMinutes: minutesFromMidnight(dailyRefreshTime),
                                enableCelebrations: enableCelebrations,
                                enableHaptics: enableHaptics,
                                enableSound: enableSound,
                                celebrationIntensity: celebrationIntensity
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }

    private func minutesFromMidnight(_ date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = min(max(components.hour ?? 0, 0), 23)
        let minute = min(max(components.minute ?? 0, 0), 59)
        return hour * 60 + minute
    }

    private func appearanceTitle(for mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            return "Sistema"
        case .light:
            return "Claro"
        case .dark:
            return "Oscuro"
        }
    }

    private func wordHintTitle(for mode: WordHintMode) -> String {
        switch mode {
        case .word:
            return "Palabra"
        case .definition:
            return "Definicion"
        }
    }

    private func celebrationTitle(for intensity: CelebrationIntensity) -> String {
        switch intensity {
        case .low:
            return "Baja"
        case .medium:
            return "Media"
        case .high:
            return "Alta"
        }
    }
}
