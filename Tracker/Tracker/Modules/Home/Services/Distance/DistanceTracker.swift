//
//  DistanceTracker.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import CoreLocation

/// Sums the distance between location updates. GPS drifts even when the phone is still,
/// so each update has to pass a few checks before it counts.
struct DistanceTracker {
    /// Readings less accurate than this (in metres) are ignored.
    static let maximumHorizontalAccuracy: CLLocationAccuracy = 20

    /// Movement shorter than this (in metres) is treated as drift.
    static let minimumDistance: CLLocationDistance = 5

    /// Movement faster than this (in m/s) is treated as a GPS jump. 55 m/s is about 200 km/h.
    static let maximumSpeed: CLLocationSpeed = 55

    enum Outcome: Equatable {
        case started
        case added
        case ignored(Reason)
    }

    enum Reason: Equatable {
        case invalidAccuracy
        case lowAccuracy
        case beforeSessionStart
        case outOfOrder
        case tooSmall
        case tooFast
    }

    let startDate: Date

    private(set) var totalDistance: CLLocationDistance = 0

    /// Only moves when distance is added, so slow walking still adds up over a few updates.
    private(set) var lastLocation: CLLocation?

    init(startDate: Date = Date()) {
        self.startDate = startDate
    }
}

// MARK: - Methods

extension DistanceTracker {
    @discardableResult
    mutating func add(_ location: CLLocation) -> Outcome {
        // Core Location reports a negative accuracy when the reading is invalid.
        guard location.horizontalAccuracy >= 0 else { return .ignored(.invalidAccuracy) }

        guard location.horizontalAccuracy <= Self.maximumHorizontalAccuracy else {
            return .ignored(.lowAccuracy)
        }

        // The first update after starting is often a cached location from earlier.
        guard location.timestamp >= startDate else { return .ignored(.beforeSessionStart) }

        guard let lastLocation else {
            self.lastLocation = location
            return .started
        }

        guard location.timestamp > lastLocation.timestamp else { return .ignored(.outOfOrder) }

        let distance = location.distance(from: lastLocation)

        // Two readings that are each off by up to their accuracy can be that far apart
        // while the phone is standing still.
        let driftThreshold = max(
            Self.minimumDistance,
            location.horizontalAccuracy + lastLocation.horizontalAccuracy
        )
        guard distance > driftThreshold else { return .ignored(.tooSmall) }

        let seconds = location.timestamp.timeIntervalSince(lastLocation.timestamp)
        guard distance / seconds <= Self.maximumSpeed else { return .ignored(.tooFast) }

        totalDistance += distance
        self.lastLocation = location
        return .added
    }
}
