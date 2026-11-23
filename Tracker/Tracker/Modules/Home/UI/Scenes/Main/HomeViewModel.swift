//
//  HomeViewModel.swift
//  Tracker
//

import Foundation

@Observable
final class HomeViewModel: HomeViewModelProtocol {
  var isShowingInfo = false
}

// MARK: - Methods

extension HomeViewModel {
  func primaryButtonTapped() {
    isShowingInfo = true
  }

  func infoDismissed() {
    isShowingInfo = false
  }
}

// MARK: - Computed Properties

extension HomeViewModel {
  var title: String {
    "Tracker"
  }

  var message: String {
    "Your delivery tracker starts here."
  }

  var primaryButtonTitle: String {
    "Get Started"
  }
}
