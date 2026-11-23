//
//  HomeViewModelTests.swift
//  TrackerTests
//

import CoreLocation
import Testing
@testable import Tracker

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {
    private let locationService = MockLocationService()

    private func makeSUT() -> HomeViewModel {
        HomeViewModel(
            locationService: locationService,
            now: { CLLocation.testStartDate }
        )
    }

    /// Starts tracking and waits until every scripted event has been handled.
    private func startTracking(_ sut: HomeViewModel) async {
        sut.trackingButtonTapped()
        await sut.trackingTask?.value
    }

    // MARK: Tracking

    @Test("starts idle with no location or distance")
    func startsIdle() {
        let sut = makeSUT()

        #expect(!sut.isTracking)
        #expect(sut.status == .idle)
        #expect(sut.statusText == "Idle")
        #expect(sut.distanceText == "0 m")
        #expect(sut.latitudeText == "—")
        #expect(sut.longitudeText == "—")
        #expect(sut.trackingButtonTitle == "Start Tracking")
    }

    @Test("tracking shows the current location and the distance travelled")
    func trackingShowsCurrentLocationAndDistance() async {
        let last = CLLocation.test(north: 100, at: 21)
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(last)
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.isTracking)
        #expect(sut.status == .tracking)
        #expect(sut.statusText == "Tracking")
        #expect(sut.trackingButtonTitle == "Stop Tracking")
        #expect(sut.distanceText == "100 m")
        #expect(sut.currentLocation == last)
        #expect(sut.latitudeText == String(format: "%.6f°", last.coordinate.latitude))
        #expect(sut.longitudeText == String(format: "%.6f°", last.coordinate.longitude))
        #expect(sut.route.count == 2)
    }

    @Test("stop tracking stops location updates and keeps the distance")
    func stopTrackingStopsUpdatesAndKeepsDistance() async {
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(.test(north: 100, at: 21))
        ]
        let sut = makeSUT()
        await startTracking(sut)

        sut.trackingButtonTapped()

        #expect(!sut.isTracking)
        #expect(sut.trackingTask == nil)
        #expect(locationService.stopUpdatesCallCount == 1)
        #expect(sut.distanceText == "100 m")
        #expect(sut.trackingButtonTitle == "Start Tracking")
    }

    @Test("starting a new session resets the distance, location and route")
    func startingANewSessionResets() async {
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(.test(north: 100, at: 21))
        ]
        let sut = makeSUT()
        await startTracking(sut)
        sut.trackingButtonTapped()

        locationService.events = []
        await startTracking(sut)

        #expect(sut.distanceText == "0 m")
        #expect(sut.currentLocation == nil)
        #expect(sut.route.isEmpty)
        #expect(locationService.locationEventsCallCount == 2)
    }

    // MARK: Permission

    @Test("denied permission while tracking stops tracking and shows the denied sheet")
    func deniedPermissionStopsTracking() async {
        locationService.events = [.authorizationDenied]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(!sut.isTracking)
        #expect(sut.isLocationDenied)
        #expect(sut.status == .locationOff)
        #expect(sut.statusText == "Location off")
        #expect(sut.isShowingLocationDenied)
        #expect(locationService.stopUpdatesCallCount == 1)
    }

    @Test("start when location is already off shows the denied sheet without starting updates", arguments: [
        CLAuthorizationStatus.denied,
        .restricted
    ])
    func startWhenAlreadyOffShowsDeniedSheet(status: CLAuthorizationStatus) {
        locationService.authorizationStatus = status
        let sut = makeSUT()

        sut.trackingButtonTapped()

        #expect(!sut.isTracking)
        #expect(locationService.locationEventsCallCount == 0)
        #expect(sut.isShowingLocationDenied)
    }

    @Test("tapping the banner shows the denied sheet")
    func turnOnLocationShowsDeniedSheet() {
        let sut = makeSUT()

        sut.turnOnLocationTapped()

        #expect(sut.isShowingLocationDenied)
    }

    @Test("refreshing picks up access turned back on in Settings")
    func refreshPicksUpAccessTurnedBackOn() {
        locationService.authorizationStatus = .denied
        let sut = makeSUT()

        locationService.authorizationStatus = .authorizedWhenInUse
        sut.refreshAuthorizationStatus()

        #expect(!sut.isLocationDenied)
        #expect(sut.statusText == "Idle")
    }

    // MARK: Distance

    @Test("shows kilometres from 1 km")
    func showsKilometres() async {
        let start = CLLocation.test(north: 0, at: 1)
        let end = CLLocation.test(north: 1_500, at: 61)
        locationService.events = [.location(start), .location(end)]
        let sut = makeSUT()

        await startTracking(sut)

        // The test helper's metres are approximate, so compare with the real distance between the two points.
        let expected = String(format: "%.2f km", end.distance(from: start) / 1_000)
        #expect(sut.distanceText == expected)
        #expect(sut.distanceText.hasPrefix("1."))
    }

    @Test("ignored readings update the location but not the distance or route")
    func ignoredReadingsDontAddDistanceOrRoute() async {
        let inaccurate = CLLocation.test(north: 100, accuracy: 50, at: 21)
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(inaccurate)
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.distanceText == "0 m")
        #expect(sut.route.count == 1)
        #expect(sut.currentLocation == inaccurate)
    }

    @Test("locations from before the session started are not counted")
    func locationsBeforeSessionStartAreNotCounted() async {
        locationService.events = [
            .location(.test(north: 0, at: -30)),
            .location(.test(north: 100, at: -10))
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.distanceText == "0 m")
        #expect(sut.route.isEmpty)
    }
}
