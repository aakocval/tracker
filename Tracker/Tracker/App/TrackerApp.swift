//
//  TrackerApp.swift
//  Tracker
//

import SwiftUI

@main
struct TrackerApp: App {
    @State private var viewModel = HomeViewModel(locationService: LocationService())

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView(viewModel: viewModel)
            }
        }
    }
}
