//
//  HomeViewModelProtocol.swift
//  Tracker
//

import Observation

/// `AnyObject` + `Observable` so `HomeSUView` can use `@Bindable`.
protocol HomeViewModelProtocol: AnyObject, Observable {
  var isShowingInfo: Bool { get set }

  var title: String { get }
  var message: String { get }
  var primaryButtonTitle: String { get }

  func primaryButtonTapped()
  func infoDismissed()
}
