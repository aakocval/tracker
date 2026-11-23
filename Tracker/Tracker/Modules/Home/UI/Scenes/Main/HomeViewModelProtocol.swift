//
//  HomeViewModelProtocol.swift
//  Tracker
//

import CoreLocation
import Observation

/// `AnyObject` + `Observable` so `HomeSUView` can use `@Bindable`.
protocol HomeViewModelProtocol: AnyObject, Observable {
    var isTracking: Bool { get }
    var isLocationDenied: Bool { get }
    var status: TrackingStatus { get }
    var statusText: String { get }
    var latitudeText: String { get }
    var longitudeText: String { get }
    var trackingButtonTitle: String { get }
    var route: [CLLocationCoordinate2D] { get }
    var currentLocation: CLLocation? { get }

    func refreshAuthorizationStatus()
    func trackingButtonTapped()
}
