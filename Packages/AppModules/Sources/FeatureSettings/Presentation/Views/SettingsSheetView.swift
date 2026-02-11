/*
 BEGINNER NOTES (AUTO):
 - Archivo: Packages/AppModules/Sources/FeatureSettings/Presentation/Views/SettingsSheetView.swift
 - Rol principal: Define interfaz SwiftUI: estructura visual, estados observados y eventos del usuario.
 - Flujo simplificado: Entrada: estado observable + eventos de usuario. | Proceso: SwiftUI recalcula body y compone vistas. | Salida: interfaz actualizada en pantalla.
 - Tipos clave en este archivo: SettingsSheetValues,SettingsSheetView DifficultySection,AppearanceSection
 - Funciones clave en este archivo: minutesFromMidnight,openAppSettings
 - Como leerlo sin experiencia:
   1) Busca primero los tipos clave para entender 'quien vive aqui'.
   2) Revisa propiedades (let/var): indican que datos mantiene cada tipo.
   3) Sigue funciones publicas: son la puerta de entrada para otras capas.
   4) Luego mira funciones privadas: implementan detalles internos paso a paso.
   5) Si ves guard/if/switch, son decisiones que controlan el flujo.
 - Recordatorio rapido de sintaxis:
   - let = valor fijo; var = valor que puede cambiar.
   - guard = valida pronto; si falla, sale de la funcion.
   - return = devuelve un resultado y cierra esa funcion.
*/

import SwiftUI
import Core
import DesignSystem
#if canImport(UIKit)
import UIKit
#endif

public struct SettingsSheetValues: Equatable {
    public var gridSize: Int
    public var appearanceMode: AppearanceMode
    public var wordHintMode: WordHintMode
    public var appLanguage: AppLanguage
    public var dailyRefreshMinutes: Int
    public var enableCelebrations: Bool
    public var enableHaptics: Bool
    public var enableSound: Bool
    public var celebrationIntensity: CelebrationIntensity

    public init(
        gridSize: Int,
        appearanceMode: AppearanceMode,
        wordHintMode: WordHintMode,
        appLanguage: AppLanguage,
        dailyRefreshMinutes: Int,
        enableCelebrations: Bool,
        enableHaptics: Bool,
        enableSound: Bool,
        celebrationIntensity: CelebrationIntensity
    ) {
        self.gridSize = gridSize
        self.appearanceMode = appearanceMode
        self.wordHintMode = wordHintMode
        self.appLanguage = appLanguage
        self.dailyRefreshMinutes = dailyRefreshMinutes
        self.enableCelebrations = enableCelebrations
        self.enableHaptics = enableHaptics
        self.enableSound = enableSound
        self.celebrationIntensity = celebrationIntensity
    }
}

public struct SettingsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
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
                DifficultySection(gridSize: $gridSize)
                AppearanceSection(appearanceMode: $appearanceMode)
                LanguageSection(
                    appLanguage: AppLanguage.resolved(),
                    onOpenSettings: openAppSettings
                )
                HintsSection(wordHintMode: $wordHintMode)
                ScheduleSection(dailyRefreshTime: $dailyRefreshTime)
                CelebrationsSection(
                    enableCelebrations: $enableCelebrations,
                    enableHaptics: $enableHaptics,
                    enableSound: $enableSound,
                    celebrationIntensity: $celebrationIntensity
                )
            }
            .navigationTitle(SettingsStrings.title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(SettingsStrings.cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SettingsStrings.save) {
                        onSave(
                            SettingsSheetValues(
                                gridSize: gridSize,
                                appearanceMode: appearanceMode,
                                wordHintMode: wordHintMode,
                                appLanguage: AppLanguage.resolved(),
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

    private func openAppSettings() {
#if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
#endif
    }
}

private struct DifficultySection: View {
    @Binding var gridSize: Int

    var body: some View {
        Section(SettingsStrings.difficultySection) {
            Stepper(value: $gridSize, in: WordSearchConfig.minGridSize...WordSearchConfig.maxGridSize) {
                Text(SettingsStrings.gridSize(gridSize))
            }
            SettingsSectionFootnote(SettingsStrings.difficultyHintPrimary)
            SettingsSectionFootnote(SettingsStrings.difficultyHintSecondary)
        }
    }
}

private struct AppearanceSection: View {
    @Binding var appearanceMode: AppearanceMode

    var body: some View {
        Section(SettingsStrings.appearanceSection) {
            Picker(SettingsStrings.themePickerTitle, selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    Text(SettingsStrings.appearanceTitle(for: mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct LanguageSection: View {
    let appLanguage: AppLanguage
    let onOpenSettings: () -> Void

    @State private var showsManagedLanguageAlert = false

    var body: some View {
        Section(SettingsStrings.languageSection) {
            Button {
                showsManagedLanguageAlert = true
            } label: {
                HStack(spacing: SpacingTokens.xs) {
                    Text(SettingsStrings.languagePickerTitle)
                    Spacer(minLength: SpacingTokens.sm)
                    Text(SettingsStrings.languageTitle(for: appLanguage))
                        .foregroundStyle(ColorTokens.textSecondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(TypographyTokens.caption.weight(.semibold))
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .alert(SettingsStrings.languageDeviceManagedTitle, isPresented: $showsManagedLanguageAlert) {
            Button(SettingsStrings.languageOpenSettings) {
                onOpenSettings()
            }
            Button(SettingsStrings.cancel, role: .cancel) {}
        } message: {
            Text(SettingsStrings.languageDeviceManagedMessage)
        }
    }
}

private struct HintsSection: View {
    @Binding var wordHintMode: WordHintMode

    var body: some View {
        Section(SettingsStrings.hintsSection) {
            Picker(SettingsStrings.hintModePickerTitle, selection: $wordHintMode) {
                ForEach(WordHintMode.allCases, id: \.self) { mode in
                    Text(SettingsStrings.wordHintTitle(for: mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            SettingsSectionFootnote(SettingsStrings.definitionHint)
        }
    }
}

private struct ScheduleSection: View {
    @Binding var dailyRefreshTime: Date

    var body: some View {
        Section(SettingsStrings.scheduleSection) {
            DatePicker(
                SettingsStrings.refreshPickerTitle,
                selection: $dailyRefreshTime,
                displayedComponents: .hourAndMinute
            )

            SettingsSectionFootnote(SettingsStrings.refreshHint)
        }
    }
}

private struct CelebrationsSection: View {
    @Binding var enableCelebrations: Bool
    @Binding var enableHaptics: Bool
    @Binding var enableSound: Bool
    @Binding var celebrationIntensity: CelebrationIntensity

    var body: some View {
        Section(SettingsStrings.celebrationsSection) {
            Toggle(SettingsStrings.celebrationsToggle, isOn: $enableCelebrations)
            Toggle(SettingsStrings.hapticsToggle, isOn: $enableHaptics)
            Toggle(SettingsStrings.soundToggle, isOn: $enableSound)

            Picker(SettingsStrings.intensityPickerTitle, selection: $celebrationIntensity) {
                ForEach(CelebrationIntensity.allCases, id: \.self) { intensity in
                    Text(SettingsStrings.celebrationTitle(for: intensity)).tag(intensity)
                }
            }

            SettingsSectionFootnote(SettingsStrings.reduceMotionHint)
        }
    }
}

private struct SettingsSectionFootnote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(TypographyTokens.footnote)
            .foregroundStyle(ColorTokens.textSecondary)
    }
}

#Preview("Settings Sheet") {
    SettingsSheetView(
        values: SettingsSheetValues(
            gridSize: 10,
            appearanceMode: .system,
            wordHintMode: .definition,
            appLanguage: .english,
            dailyRefreshMinutes: 9 * 60,
            enableCelebrations: true,
            enableHaptics: true,
            enableSound: false,
            celebrationIntensity: .medium
        )
    ) { _ in }
}
