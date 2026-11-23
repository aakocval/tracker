//
//  DistanceTrackerTests.swift
//  TrackerTests
//

import CoreLocation
import Testing
@testable import Tracker

@MainActor
@Suite("DistanceTracker")
struct DistanceTrackerTests {
    private func makeSUT() -> DistanceTracker {
        DistanceTracker(startDate: CLLocation.testStartDate)
    }

    // MARK: Counting distance

    @Test("first accurate location starts the session without adding distance")
    func firstAccurateLocationStartsTheSession() {
        var sut = makeSUT()

        let outcome = sut.add(.test(at: 1))

        #expect(outcome == .started)
        #expect(sut.totalDistance == 0)
        #expect(sut.lastLocation != nil)
    }

    @Test("adds the distance between two accurate locations")
    func addsDistanceBetweenTwoAccurateLocations() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 1))

        let outcome = sut.add(.test(north: 100, at: 21))

        #expect(outcome == .added)
        #expect(abs(sut.totalDistance - 100) < 1)
    }

    @Test("sums distance across several updates")
    func sumsDistanceAcrossSeveralUpdates() {
        var sut = makeSUT()

        sut.add(.test(north: 0, at: 1))
        sut.add(.test(north: 50, at: 11))
        sut.add(.test(north: 100, at: 21))
        sut.add(.test(north: 150, at: 31))

        #expect(abs(sut.totalDistance - 150) < 1)
    }

    // MARK: GPS noise

    @Test("ignores GPS drift while standing still")
    func ignoresGPSDriftWhileStandingStill() {
        var sut = makeSUT()

        // Readings jump 3 m either side of the same spot, like a phone lying on a table.
        for second in 1...30 {
            let east: CLLocationDistance = second.isMultiple(of: 2) ? 3 : -3
            sut.add(.test(east: east, at: TimeInterval(second)))
        }

        #expect(sut.totalDistance == 0)
    }

    @Test("ignores movement within the two readings' combined accuracy")
    func ignoresMovementWithinCombinedAccuracy() {
        var sut = makeSUT()
        sut.add(.test(north: 0, accuracy: 15, at: 1))

        // 25 m apart, but each reading could be off by 15 m.
        let outcome = sut.add(.test(north: 25, accuracy: 15, at: 21))

        #expect(outcome == .ignored(.tooSmall))
        #expect(sut.totalDistance == 0)
    }

    @Test("still counts slow movement once it passes the drift threshold")
    func stillCountsSlowMovement() {
        var sut = makeSUT()

        // Walking slowly: 2 m per update, which is below the drift threshold on its own.
        for second in 0...30 {
            sut.add(.test(north: Double(second) * 2, at: TimeInterval(second + 1)))
        }

        #expect(abs(sut.totalDistance - 60) < 1)
    }

    @Test("ignores impossible jumps and keeps measuring from the last good location")
    func ignoresImpossibleJumps() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 1))

        let jump = sut.add(.test(north: 1_000, at: 2))
        sut.add(.test(north: 20, at: 11))

        #expect(jump == .ignored(.tooFast))
        #expect(abs(sut.totalDistance - 20) < 0.5)
    }

    @Test("starts again from the new position when the first point was a stale fix")
    func restartsWhenTheFirstPointWasStale() {
        var sut = makeSUT()
        sut.add(.test(north: 5_000, at: 1))

        let firstReal = sut.add(.test(north: 0, at: 8))
        let secondReal = sut.add(.test(north: 30, at: 9))
        let thirdReal = sut.add(.test(north: 60, at: 10))

        #expect(firstReal == .ignored(.tooFast))
        #expect(secondReal == .restarted)
        #expect(thirdReal == .added)
        #expect(abs(sut.totalDistance - 30) < 0.5)
    }

    @Test("keeps ignoring jumps that don't agree with each other")
    func keepsIgnoringJumpsThatDisagree() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 1))

        let first = sut.add(.test(north: 1_000, at: 2))
        let second = sut.add(.test(north: -1_000, at: 3))

        #expect(first == .ignored(.tooFast))
        #expect(second == .ignored(.tooFast))
        #expect(sut.totalDistance == 0)
    }

    @Test("a reading back near the last point cancels a pending jump")
    func readingNearLastPointCancelsPendingJump() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 1))
        sut.add(.test(north: 1_000, at: 2))

        sut.add(.test(north: 2, at: 3))
        let outcome = sut.add(.test(north: 1_010, at: 4))

        #expect(outcome == .ignored(.tooFast))
        #expect(sut.totalDistance == 0)
    }

    // MARK: Rejected readings

    @Test("ignores locations with invalid accuracy")
    func ignoresLocationsWithInvalidAccuracy() {
        var sut = makeSUT()

        let outcome = sut.add(.test(accuracy: -1, at: 1))

        #expect(outcome == .ignored(.invalidAccuracy))
        #expect(sut.lastLocation == nil)
    }

    @Test("ignores locations with low accuracy")
    func ignoresLocationsWithLowAccuracy() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 1))

        let outcome = sut.add(.test(north: 100, accuracy: 50, at: 21))

        #expect(outcome == .ignored(.lowAccuracy))
        #expect(sut.totalDistance == 0)
    }

    @Test("ignores locations from before the session started")
    func ignoresLocationsFromBeforeTheSessionStarted() {
        var sut = makeSUT()

        let outcome = sut.add(.test(at: -5))

        #expect(outcome == .ignored(.beforeSessionStart))
        #expect(sut.lastLocation == nil)
    }

    @Test("reports an old cached location as before the session, even when its accuracy is low", arguments: [
        CLLocationAccuracy(65),
        -1
    ])
    func reportsCachedLocationAsBeforeSessionWhateverItsAccuracy(accuracy: CLLocationAccuracy) {
        var sut = makeSUT()

        let outcome = sut.add(.test(accuracy: accuracy, at: -60))

        #expect(outcome == .ignored(.beforeSessionStart))
    }

    @Test("ignores locations that arrive out of order")
    func ignoresLocationsThatArriveOutOfOrder() {
        var sut = makeSUT()
        sut.add(.test(north: 0, at: 10))

        let outcome = sut.add(.test(north: 100, at: 5))

        #expect(outcome == .ignored(.outOfOrder))
        #expect(sut.totalDistance == 0)
    }
}
