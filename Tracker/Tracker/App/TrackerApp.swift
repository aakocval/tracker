//
//  TrackerApp.swift
//  Tracker
//

import SwiftUI

@main
struct TrackerApp: App {
    @State private var viewModel = HomeViewModel(locationService: LocationService())
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack {
                    HomeView(viewModel: viewModel)
                }

                if isShowingSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            isShowingSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
