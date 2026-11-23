//
//  MockLocationService.swift
//  TrackerTests
//

import CoreLocation
@testable import Tracker

@MainActor
final class MockLocationService: LocationServiceProtocol {
    var authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse

    /// Sent, in order, to whoever reads `locationEvents()`. The stream finishes after the last one.
    var events: [LocationEvent] = []

    private(set) var locationEventsCallCount = 0
    private(set) var stopUpdatesCallCount = 0

    func locationEvents() -> AsyncStream<LocationEvent> {
        locationEventsCallCount += 1

        let (stream, continuation) = AsyncStream.makeStream(of: LocationEvent.self)
        events.forEach { continuation.yield($0) }
        continuation.finish()

        return stream
    }

    func stopUpdates() {
        stopUpdatesCallCount += 1
    }
}
