//
//  LocationServiceProtocol.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import CoreLocation

protocol LocationServiceProtocol: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }

    func locationEvents() -> AsyncStream<LocationEvent>
    func stopUpdates()
}
