//
//  MockLocationManager.swift
//  TrackerTests
//

import CoreLocation
@testable import Tracker

@MainActor
final class MockLocationManager: LocationManagerProtocol {
    weak var delegate: CLLocationManagerDelegate?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters
    var distanceFilter: CLLocationDistance = 100
    var activityType: CLActivityType = .other

    private(set) var requestWhenInUseAuthorizationCallCount = 0
    private(set) var startUpdatingLocationCallCount = 0
    private(set) var stopUpdatingLocationCallCount = 0

    func requestWhenInUseAuthorization() {
        requestWhenInUseAuthorizationCallCount += 1
    }

    func startUpdatingLocation() {
        startUpdatingLocationCallCount += 1
    }

    func stopUpdatingLocation() {
        stopUpdatingLocationCallCount += 1
    }
}
