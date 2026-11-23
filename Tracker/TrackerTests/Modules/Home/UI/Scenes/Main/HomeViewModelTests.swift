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
        #expect(sut.currentLocation == nil)
    }

    @Test("a cached location from the previous trip doesn't set location, speed or activity", arguments: [
        CLLocationAccuracy(5),
        65
    ])
    func cachedLocationFromPreviousTripIsIgnored(accuracy: CLLocationAccuracy) async {
        // The end of an earlier drive at about 100 km/h, sent again when updates start.
        // Real cached fixes often have poor accuracy, so both cases must be ignored.
        locationService.events = [.location(.test(north: 5_000, accuracy: accuracy, speed: 28, at: -60))]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.currentLocation == nil)
        #expect(sut.latitudeText == "—")
        #expect(sut.speedText == "—")
        #expect(sut.speedThresholdText == nil)
        #expect(sut.activity == .none)
        #expect(sut.activityText == "—")
        #expect(sut.distanceText == "0 m")
        #expect(sut.route.isEmpty)
    }

    @Test("restarting after a drive starts fresh even if the old location is sent again")
    func restartingAfterADriveStartsFresh() async {
        let lastDrivePoint = CLLocation.test(north: 1_000, speed: 28, at: 40)
        locationService.events = [
            .location(.test(north: 0, speed: 28, at: 1)),
            .location(lastDrivePoint)
        ]
        var clock = CLLocation.testStartDate
        let sut = HomeViewModel(locationService: locationService, now: { clock })
        await startTracking(sut)
        #expect(sut.activity == .driving)
        sut.trackingButtonTapped()

        // Restart later with the location set to None; Core Location only sends the cached end of the drive.
        clock = CLLocation.testStartDate.addingTimeInterval(120)
        locationService.events = [.location(lastDrivePoint)]
        await startTracking(sut)

        #expect(sut.currentLocation == nil)
        #expect(sut.speedText == "—")
        #expect(sut.speedThresholdText == nil)
        #expect(sut.activityText == "—")
        #expect(sut.distanceText == "0 m")
        #expect(sut.route.isEmpty)
    }

    @Test("draws the route and counts distance when the first point of a session was a stale fix")
    func recoversWhenTheFirstPointWasStale() async {
        let secondReal = CLLocation.test(north: 30, at: 9)
        locationService.events = [
            .location(.test(north: 6_000, at: 1)),
            .location(.test(north: 0, at: 8)),
            .location(secondReal),
            .location(.test(north: 60, at: 10)),
            .location(.test(north: 90, at: 11))
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.route.count == 3)
        #expect(sut.route.first?.latitude == secondReal.coordinate.latitude)
        #expect(sut.distance > 50)
        #expect(sut.distance < 70)
    }

    @Test("doesn't work out a speed across a jump")
    func doesNotWorkOutSpeedAcrossAJump() async {
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(.test(north: 14, at: 11)),
            .location(.test(north: 5_000, at: 12))
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.activity == .walking)
        #expect(sut.speedThresholdText == nil)
    }

    // MARK: Speed

    @Test("shows a dash for speed until there's one")
    func showsDashForSpeedUntilThereIsOne() async {
        let sut = makeSUT()
        #expect(sut.speedText == "—")

        locationService.events = [.location(.test(at: 1))]
        await startTracking(sut)

        #expect(sut.speedText == "—")
    }

    @Test("shows the reported speed in km/h")
    func showsReportedSpeedInKilometresPerHour() async {
        // 12.5 m/s is 45 km/h.
        locationService.events = [.location(.test(speed: 12.5, at: 1))]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.speedText == "45.0 km/h")
    }

    @Test("stopping clears the speed")
    func stoppingClearsTheSpeed() async {
        locationService.events = [.location(.test(speed: 12.5, at: 1))]
        let sut = makeSUT()
        await startTracking(sut)

        sut.trackingButtonTapped()

        #expect(sut.speedText == "—")
        #expect(sut.speedThresholdText == nil)
    }

    @Test("shows Over 10 km/h only when moving faster than 10 km/h", arguments: [
        (speed: 1.4, text: String?.none),
        (speed: 10 / 3.6, text: String?.none),
        (speed: 2.8, text: "Over 10 km/h"),
        (speed: 15.0, text: "Over 10 km/h")
    ])
    func showsOverThresholdText(
        speed: CLLocationSpeed,
        text: String?
    ) async {
        locationService.events = [.location(.test(speed: speed, at: 1))]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.speedThresholdText == text)
    }

    @Test("shows no threshold text before there's a speed")
    func showsNoThresholdTextWithoutSpeed() {
        let sut = makeSUT()

        #expect(sut.speedThresholdText == nil)
    }

    // MARK: Activity

    @Test("shows Not tracking with no symbol before tracking starts")
    func showsNotTrackingWhenIdle() {
        let sut = makeSUT()

        #expect(sut.activity == .none)
        #expect(sut.activityText == "Not tracking")
        #expect(sut.activitySymbolName == nil)
    }

    @Test("shows a dash while tracking until there's a speed")
    func showsDashUntilThereIsASpeed() async {
        // One reading with no reported speed, so there's nothing to work it out from yet.
        locationService.events = [.location(.test(at: 1))]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.activity == .none)
        #expect(sut.activityText == "—")
        #expect(sut.activitySymbolName == nil)
    }

    @Test("shows Walking at or below 10 km/h and Driving above it", arguments: [
        (speed: 1.4, activity: TrackingActivity.walking, text: "Walking", symbol: "figure.walk"),
        (speed: 10 / 3.6, activity: .walking, text: "Walking", symbol: "figure.walk"),
        (speed: 2.8, activity: .driving, text: "Driving", symbol: "car.fill"),
        (speed: 15.0, activity: .driving, text: "Driving", symbol: "car.fill")
    ])
    func showsWalkingOrDriving(
        speed: CLLocationSpeed,
        activity: TrackingActivity,
        text: String,
        symbol: String
    ) async {
        locationService.events = [.location(.test(speed: speed, at: 1))]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.activity == activity)
        #expect(sut.activityText == text)
        #expect(sut.activitySymbolName == symbol)
    }

    @Test("works out speed from the last two updates when the device reports none", arguments: [
        (metres: 14.0, activity: TrackingActivity.walking),
        (metres: 150.0, activity: .driving)
    ])
    func worksOutSpeedWhenDeviceReportsNone(
        metres: CLLocationDistance,
        activity: TrackingActivity
    ) async {
        // 10 seconds apart: 14 m is about 5 km/h, 150 m is about 54 km/h.
        locationService.events = [
            .location(.test(north: 0, at: 1)),
            .location(.test(north: metres, at: 11))
        ]
        let sut = makeSUT()

        await startTracking(sut)

        #expect(sut.activity == activity)
    }

    @Test("stopping clears the activity")
    func stoppingClearsTheActivity() async {
        locationService.events = [.location(.test(speed: 15, at: 1))]
        let sut = makeSUT()
        await startTracking(sut)

        sut.trackingButtonTapped()

        #expect(sut.speed == nil)
        #expect(sut.activity == .none)
        #expect(sut.activityText == "Not tracking")
    }
}
