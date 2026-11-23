//
//  CLLocation+Utils.swift
//  TrackerTests
//

import CoreLocation

extension CLLocation {
    static let testStartDate = Date(timeIntervalSince1970: 1_800_000_000)
    static let testOrigin = CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093)

    /// A location offset from `testOrigin` by roughly the given metres, `seconds` after `testStartDate`.
    static func test(
        north: CLLocationDistance = 0,
        east: CLLocationDistance = 0,
        accuracy: CLLocationAccuracy = 5,
        at seconds: TimeInterval
    ) -> CLLocation {
        let metresPerDegree = 111_320.0
        let latitude = testOrigin.latitude + north / metresPerDegree
        let longitude = testOrigin.longitude + east / (metresPerDegree * cos(testOrigin.latitude * .pi / 180))

        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: -1,
            course: -1,
            speed: -1,
            timestamp: testStartDate.addingTimeInterval(seconds)
        )
    }
}
