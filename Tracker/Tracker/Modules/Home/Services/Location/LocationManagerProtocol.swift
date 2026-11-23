//
//  LocationManagerProtocol.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import CoreLocation

/// The parts of `CLLocationManager` that `LocationService` uses, so tests can pass a mock.
protocol LocationManagerProtocol: AnyObject {
    var delegate: CLLocationManagerDelegate? { get set }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var activityType: CLActivityType { get set }

    var authorizationStatus: CLAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManagerProtocol {}
