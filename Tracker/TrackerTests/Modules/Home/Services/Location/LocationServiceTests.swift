//
//  LocationServiceTests.swift
//  TrackerTests
//

import CoreLocation
import Testing
@testable import Tracker

@MainActor
@Suite("LocationService")
struct LocationServiceTests {
    private let manager = MockLocationManager()

    /// Passed to the delegate methods, which read the injected mock instead.
    private let delegateManager = CLLocationManager()

    private func makeSUT(status: CLAuthorizationStatus) -> LocationService {
        manager.authorizationStatus = status
        return LocationService(manager: manager)
    }

    /// Reads the stream until it finishes.
    private func events(of stream: AsyncStream<LocationEvent>) async -> [LocationEvent] {
        var events: [LocationEvent] = []
        for await event in stream {
            events.append(event)
        }
        return events
    }

    // MARK: Setup

    @Test("sets up the manager for accurate navigation updates")
    func setsUpTheManager() {
        let sut = makeSUT(status: .authorizedWhenInUse)

        #expect(manager.delegate === sut)
        #expect(manager.desiredAccuracy == kCLLocationAccuracyBest)
        #expect(manager.distanceFilter == kCLDistanceFilterNone)
        #expect(manager.activityType == .otherNavigation)
    }

    // MARK: Starting

    @Test("starts updates straight away when access is already allowed")
    func startsUpdatesWhenAllowed() {
        let sut = makeSUT(status: .authorizedWhenInUse)

        _ = sut.locationEvents()

        #expect(manager.startUpdatingLocationCallCount == 1)
        #expect(manager.requestWhenInUseAuthorizationCallCount == 0)
    }

    @Test("asks for permission first when the user hasn't decided")
    func asksForPermissionWhenNotDetermined() {
        let sut = makeSUT(status: .notDetermined)

        _ = sut.locationEvents()

        #expect(manager.requestWhenInUseAuthorizationCallCount == 1)
        #expect(manager.startUpdatingLocationCallCount == 0)
    }

    @Test("starts updates once the user allows access")
    func startsUpdatesOnceAllowed() {
        let sut = makeSUT(status: .notDetermined)
        _ = sut.locationEvents()

        manager.authorizationStatus = .authorizedWhenInUse
        sut.locationManagerDidChangeAuthorization(delegateManager)

        #expect(manager.startUpdatingLocationCallCount == 1)
    }

    @Test("ignores permission changes when not tracking")
    func ignoresPermissionChangesWhenNotTracking() {
        let sut = makeSUT(status: .authorizedWhenInUse)

        sut.locationManagerDidChangeAuthorization(delegateManager)

        #expect(manager.startUpdatingLocationCallCount == 0)
    }

    // MARK: Events

    @Test("passes on every location in order")
    func passesOnEveryLocationInOrder() async {
        let sut = makeSUT(status: .authorizedWhenInUse)
        let stream = sut.locationEvents()
        let first = CLLocation.test(north: 0, at: 1)
        let second = CLLocation.test(north: 10, at: 2)

        sut.locationManager(delegateManager, didUpdateLocations: [first, second])
        sut.stopUpdates()

        #expect(await events(of: stream) == [.location(first), .location(second)])
    }

    @Test("reports denied straight away when access is already off")
    func reportsDeniedWhenAlreadyOff() async {
        let sut = makeSUT(status: .denied)

        let stream = sut.locationEvents()
        sut.stopUpdates()

        #expect(await events(of: stream) == [.authorizationDenied])
        #expect(manager.startUpdatingLocationCallCount == 0)
    }

    @Test("reports denied when access is turned off while tracking")
    func reportsDeniedWhileTracking() async {
        let sut = makeSUT(status: .authorizedWhenInUse)
        let stream = sut.locationEvents()

        manager.authorizationStatus = .denied
        sut.locationManagerDidChangeAuthorization(delegateManager)
        sut.stopUpdates()

        #expect(await events(of: stream) == [.authorizationDenied])
    }

    // MARK: Stopping

    @Test("stop stops the manager and ends the stream")
    func stopEndsTheStream() async {
        let sut = makeSUT(status: .authorizedWhenInUse)
        let stream = sut.locationEvents()

        sut.stopUpdates()

        #expect(await events(of: stream).isEmpty)
        #expect(manager.stopUpdatingLocationCallCount == 1)
    }

    @Test("a new session ends the previous stream")
    func newSessionEndsThePreviousStream() async {
        let sut = makeSUT(status: .authorizedWhenInUse)
        let previous = sut.locationEvents()

        _ = sut.locationEvents()

        #expect(await events(of: previous).isEmpty)
    }
}
