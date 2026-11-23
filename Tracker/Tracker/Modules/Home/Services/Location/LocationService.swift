//
//  LocationService.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import CoreLocation
import Foundation

final class LocationService: NSObject, LocationServiceProtocol {
    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    private var continuation: AsyncStream<LocationEvent>.Continuation?

    private let manager: LocationManagerProtocol

    init(manager: LocationManagerProtocol = CLLocationManager()) {
        self.manager = manager

        super.init()

        setupManager()
    }
}

// MARK: - Methods

extension LocationService {
    func locationEvents() -> AsyncStream<LocationEvent> {
        continuation?.finish()

        let (stream, continuation) = AsyncStream.makeStream(of: LocationEvent.self)
        self.continuation = continuation

        startUpdatingLocation()

        return stream
    }

    func stopUpdates() {
        manager.stopUpdatingLocation()

        continuation?.finish()
        continuation = nil
    }
}

// MARK: - Helpers

private extension LocationService {
    func setupManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.activityType = .otherNavigation
    }

    func startUpdatingLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            continuation?.yield(.authorizationDenied)
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }

        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.manager.startUpdatingLocation()
        case .denied, .restricted:
            continuation?.yield(.authorizationDenied)
        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        locations.forEach { continuation?.yield(.location($0)) }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        debugPrint("LocationService failed to update location: \(error)")
    }
}
