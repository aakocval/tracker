//
//  RouteMapView.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import MapKit
import SwiftUI

struct RouteMapView: View {
    let route: [CLLocationCoordinate2D]
    let currentLocation: CLLocation?

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $position) {
            if route.count > 1 {
                MapPolyline(coordinates: route)
                    .stroke(Color.surfacesBrandDefault, lineWidth: 5)
            }

            if let currentLocation {
                Annotation("Current location", coordinate: currentLocation.coordinate) {
                    Circle()
                        .fill(Color.surfacesBrandDefault)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                }
                .annotationTitles(.hidden)
            }
        }
        .onChange(of: currentLocation) { _, newLocation in
            guard let newLocation else { return }

            withAnimation {
                position = .camera(MapCamera(centerCoordinate: newLocation.coordinate, distance: 1_000))
            }
        }
    }
}

#if DEBUG
#Preview {
    RouteMapView(route: [], currentLocation: nil)
        .frame(height: 260)
}
#endif
