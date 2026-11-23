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

    private var authorizationStatus: CLAuthorizationStatus
    private var trackingTask: Task<Void, Never>?
    private var distanceTracker: DistanceTracker?

    private let locationService: LocationServiceProtocol

    init(locationService: LocationServiceProtocol) {
        self.locationService = locationService
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
        route = []
        isTracking = true
        distanceTracker = DistanceTracker()

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
        currentLocation = location

        // Only locations that count towards the distance are drawn on the map.
        switch distanceTracker?.add(location) {
        case .started, .added:
          route.append(location.coordinate)

        case .ignored, nil:
          break
        }
    }
}

// MARK: - Computed Properties

extension HomeViewModel {
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
