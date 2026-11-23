//
//  HomeViewModel.swift
//  Tracker
//

import CoreLocation
import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
    var isTracking = false
    var isShowingLocationDenied = false
    var currentLocation: CLLocation?
    var route: [CLLocationCoordinate2D] = []

    /// Kept so tests can wait for the updates they sent to be handled.
    private(set) var trackingTask: Task<Void, Never>?
    private(set) var speed: CLLocationSpeed?

    private var authorizationStatus: CLAuthorizationStatus
    private var distanceTracker: DistanceTracker?
    private var previousLocation: CLLocation?

    private let locationService: LocationServiceProtocol
    private let now: EmptyResult<Date>

    init(
        locationService: LocationServiceProtocol,
        now: @escaping EmptyResult<Date> = Date.init
    ) {
        self.locationService = locationService
        self.now = now
        self.authorizationStatus = locationService.authorizationStatus
    }
}

// MARK: - Methods

extension HomeViewModel {
    func refreshAuthorizationStatus() {
        authorizationStatus = locationService.authorizationStatus
    }

    func trackingButtonTapped() {
        if isTracking {
            stopTracking()
        } else {
            startTracking()
        }
    }

    func turnOnLocationTapped() {
        isShowingLocationDenied = true
    }

    func startTracking() {
        guard !isTracking else { return }

        guard !isLocationDenied else {
            isShowingLocationDenied = true
            return
        }

        currentLocation = nil
        previousLocation = nil
        speed = nil
        route = []
        isTracking = true
        distanceTracker = DistanceTracker(startDate: now())

        let events = locationService.locationEvents()
        trackingTask = Task { [weak self] in
            for await event in events {
                guard let self else { return }

                self.handle(event)
            }
        }
    }

    func stopTracking() {
        guard isTracking else { return }

        trackingTask?.cancel()
        trackingTask = nil
        locationService.stopUpdates()
        isTracking = false
        speed = nil
    }
}

// MARK: - Event Handling

private extension HomeViewModel {
    func handle(_ event: LocationEvent) {
        switch event {
            case let .location(location):
                handleLocation(location)

            case .authorizationDenied:
                authorizationStatus = .denied
                stopTracking()
                isShowingLocationDenied = true
        }
    }

    func handleLocation(_ location: CLLocation) {
        let outcome = distanceTracker?.add(location)

        // Core Location sends its last cached location when updates start, e.g. the end of
        // the previous trip. It isn't where the user is now, so it mustn't set location, speed or activity.
        guard outcome != .ignored(.beforeSessionStart) else { return }

        currentLocation = location

        let isJump = outcome == .ignored(.tooFast) || outcome == .restarted
        speed = isJump ? reportedSpeed(of: location) ?? speed : speed(of: location)
        previousLocation = location

        // Only locations that count towards the distance are drawn on the map.
        switch outcome {
        case .started, .added:
            route.append(location.coordinate)

        case .restarted:
            if !route.isEmpty {
                route.removeLast()
            }
            route.append(location.coordinate)

        case .ignored, nil:
            break
        }
    }
}

// MARK: - Helpers

private extension HomeViewModel {
    func reportedSpeed(of location: CLLocation) -> CLLocationSpeed? {
        location.speed >= 0 ? location.speed : nil
    }

    /// Works out speed from the previous update when the device reports none, e.g. in GPX simulation.
    func speed(of location: CLLocation) -> CLLocationSpeed? {
        // Core Location reports -1 when the speed is invalid.
        guard location.speed < 0 else { return location.speed }
        guard let previousLocation else { return nil }

        let seconds = location.timestamp.timeIntervalSince(previousLocation.timestamp)
        guard seconds > 0 else { return speed }

        return location.distance(from: previousLocation) / seconds
    }
}

// MARK: - Computed Properties

extension HomeViewModel {
    /// 10 km/h in metres per second.
    static let drivingSpeedThreshold: CLLocationSpeed = 10 / 3.6

    var isDriving: Bool {
        guard let speed else { return false }
        return speed > Self.drivingSpeedThreshold
    }

    var speedText: String {
        guard let speed else { return "—" }
        return String(format: "%.1f km/h", speed * 3.6)
    }

    /// Only shown while moving faster than the driving threshold.
    var speedThresholdText: String? {
        isDriving ? "Over 10 km/h" : nil
    }

    var activity: TrackingActivity {
        guard isTracking, speed != nil else { return .none }
        return isDriving ? .driving : .walking
    }

    var activityText: String {
        switch activity {
        case .none: isTracking ? "—" : "Not tracking"
        case .walking: "Walking"
        case .driving: "Driving"
        }
    }

    var activitySymbolName: String? {
        switch activity {
        case .none: nil
        case .walking: "figure.walk"
        case .driving: "car.fill"
        }
    }

    var isLocationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var status: TrackingStatus {
        if isLocationDenied { return .locationOff }
        return isTracking ? .tracking : .idle
    }

    var statusText: String {
        switch status {
            case .idle: "Idle"
            case .tracking: "Tracking"
            case .locationOff: "Location off"
        }
    }

    var latitudeText: String {
        guard let currentLocation else { return "—" }
        return String(format: "%.6f°", currentLocation.coordinate.latitude)
    }

    var longitudeText: String {
        guard let currentLocation else { return "—" }
        return String(format: "%.6f°", currentLocation.coordinate.longitude)
    }

    var trackingButtonTitle: String {
        isTracking ? "Stop Tracking" : "Start Tracking"
    }

    var distance: CLLocationDistance {
        distanceTracker?.totalDistance ?? 0
    }

    var distanceText: String {
        distance.rounded() < 1_000
          ? String(format: "%.0f m", distance)
          : String(format: "%.2f km", distance / 1_000)
    }
}
