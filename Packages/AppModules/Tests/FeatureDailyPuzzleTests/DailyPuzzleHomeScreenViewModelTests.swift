import XCTest
import Core
@testable import FeatureDailyPuzzle

@MainActor
final class DailyPuzzleHomeScreenViewModelTests: XCTestCase {
    func testLockedChallengeUnlocksOnTenthTapAndOpensOnNextTap() {
        let core = CoreContainer(store: InMemoryKeyValueStore())
        let viewModel = DailyPuzzleHomeScreenViewModel(core: core, preferredGridSize: 7)
        let lockedOffset = viewModel.todayOffset + 1

        for _ in 0..<9 {
            XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .noAction)
        }

        XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .unlocked)
        XCTAssertFalse(viewModel.isLocked(offset: lockedOffset))
        XCTAssertEqual(viewModel.handleChallengeCardTap(offset: lockedOffset), .openGame)
    }

    func testInitialProgressRecordForTodayUsesSharedStateProgress() {
        let now = Date(timeIntervalSince1970: 10_000)
        let core = CoreContainer(store: InMemoryKeyValueStore())

        var shared = core.getSharedPuzzleStateUseCase.execute(now: now, preferredGridSize: 7)
        shared.foundWords = ["CAT"]
        shared.solvedPositions = [GridPosition(row: 0, col: 0), GridPosition(row: 0, col: 1)]
        core.saveSharedPuzzleStateUseCase.execute(shared)

        let viewModel = DailyPuzzleHomeScreenViewModel(core: core, preferredGridSize: 7, now: now)
        let record = viewModel.initialProgressRecord(
            for: viewModel.todayOffset,
            preferredGridSize: 7
        )

        XCTAssertEqual(Set(record?.foundWords ?? []), ["CAT"])
        XCTAssertEqual(Set(record?.solvedPositions ?? []), Set(shared.solvedPositions))
    }
}
