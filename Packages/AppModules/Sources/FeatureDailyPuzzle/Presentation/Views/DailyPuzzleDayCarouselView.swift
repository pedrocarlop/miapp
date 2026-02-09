import SwiftUI
import DesignSystem

public struct DailyPuzzleDayCarouselView: View {
    public let offsets: [Int]
    @Binding public var selectedOffset: Int?
    public let todayOffset: Int
    public let unlockedOffsets: Set<Int>
    public let dateForOffset: (Int) -> Date
    public let progressForOffset: (Int) -> Double
    public let hoursUntilAvailable: (Int) -> Int?

    public init(
        offsets: [Int],
        selectedOffset: Binding<Int?>,
        todayOffset: Int,
        unlockedOffsets: Set<Int>,
        dateForOffset: @escaping (Int) -> Date,
        progressForOffset: @escaping (Int) -> Double,
        hoursUntilAvailable: @escaping (Int) -> Int?
    ) {
        self.offsets = offsets
        _selectedOffset = selectedOffset
        self.todayOffset = todayOffset
        self.unlockedOffsets = unlockedOffsets
        self.dateForOffset = dateForOffset
        self.progressForOffset = progressForOffset
        self.hoursUntilAvailable = hoursUntilAvailable
    }

    public var body: some View {
        GeometryReader { geo in
            let itemWidth: CGFloat = 84
            let itemHeight: CGFloat = 92
            let sidePadding = max((geo.size.width - itemWidth) / 2, SpacingTokens.xs)
            let activeOffset = selectedOffset ?? todayOffset
            let scrollSelection = Binding<Int?>(
                get: {
                    let current = selectedOffset ?? todayOffset
                    return offsets.contains(current) ? current : nil
                },
                set: { selectedOffset = $0 }
            )

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SpacingTokens.md) {
                    ForEach(offsets, id: \.self) { offset in
                        let date = dateForOffset(offset)
                        let isLocked = offset > todayOffset && !unlockedOffsets.contains(offset)
                        let progress = progressForOffset(offset)
                        DailyPuzzleDayCarouselItem(
                            date: date,
                            isSelected: offset == activeOffset,
                            isLocked: isLocked,
                            isCompleted: progress >= 0.999,
                            progress: progress,
                            hoursUntilAvailable: hoursUntilAvailable(offset)
                        )
                        .frame(width: itemWidth, height: itemHeight)
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.28, extraBounce: 0.02)) {
                                selectedOffset = offset
                            }
                        }
                        .id(offset)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, sidePadding)
            }
            .padding(.vertical, SpacingTokens.xxs + 2)
            .scrollClipDisabled(true)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: scrollSelection, anchor: .center)
        }
    }
}

private struct DailyPuzzleDayCarouselItem: View {
    let date: Date
    let isSelected: Bool
    let isLocked: Bool
    let isCompleted: Bool
    let progress: Double
    let hoursUntilAvailable: Int?

    var body: some View {
        VStack(spacing: SpacingTokens.xxs + 2) {
            Text(weekdayText)
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)

            Text("\(Calendar.current.component(.day, from: date))")
                .font(TypographyTokens.titleSmall)
                .foregroundStyle(ColorTokens.textPrimary)

            statusView
                .frame(height: 14, alignment: .center)
        }
        .padding(EdgeInsets(top: SpacingTokens.sm, leading: SpacingTokens.xs + 2, bottom: SpacingTokens.sm, trailing: SpacingTokens.xs + 2))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .fill(ColorTokens.surfaceTertiary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .stroke(ColorTokens.surfacePrimary, lineWidth: 1.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                .stroke(ColorTokens.borderDefault, lineWidth: 1)
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: RadiusTokens.lg, style: .continuous)
                    .stroke(ColorTokens.textPrimary.opacity(0.92), lineWidth: 2.2)
            }
        }
        .scaleEffect(isSelected ? 1.04 : 0.98)
        .opacity(isSelected ? 1 : 0.92)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var weekdayText: String {
        let weekdays = ["dom", "lun", "mar", "mie", "jue", "vie", "sab"]
        let index = max(0, min(weekdays.count - 1, Calendar.current.component(.weekday, from: date) - 1))
        return weekdays[index].uppercased()
    }

    @ViewBuilder
    private var statusView: some View {
        if isLocked, let hoursUntilAvailable {
            Text("\(hoursUntilAvailable)h")
                .font(TypographyTokens.caption)
                .foregroundStyle(ColorTokens.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        } else if isCompleted {
            Image(systemName: "checkmark.seal.fill")
                .font(TypographyTokens.footnote)
                .foregroundStyle(ColorTokens.accentPrimary)
        } else {
            DailyPuzzleDayProgressIndicator(progress: progress)
        }
    }
}

private struct DailyPuzzleDayProgressIndicator: View {
    let progress: Double

    var body: some View {
        let clamped = min(max(progress, 0), 1)

        ZStack {
            Circle()
                .stroke(ColorTokens.textSecondary.opacity(0.26), lineWidth: 2)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    ColorTokens.accentPrimary,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 14, height: 14)
        .animation(.easeInOut(duration: 0.2), value: clamped)
    }
}
