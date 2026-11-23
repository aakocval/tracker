//
//  TrackerApp.swift
//  Tracker
//

import SwiftUI

@main
struct TrackerApp: App {
  @State private var viewModel = HomeViewModel()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        HomeSUView(viewModel: viewModel)
      }
    }
  }
}
