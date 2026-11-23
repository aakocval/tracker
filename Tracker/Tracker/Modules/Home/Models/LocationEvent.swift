//
//  LocationEvent.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import CoreLocation

enum LocationEvent: Equatable {
    case location(CLLocation)
    case authorizationDenied
}
