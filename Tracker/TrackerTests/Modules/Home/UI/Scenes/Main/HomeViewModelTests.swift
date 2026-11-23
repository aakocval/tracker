//
//  HomeViewModelTests.swift
//  TrackerTests
//

import Testing
@testable import Tracker

@MainActor
struct HomeViewModelTests {
    @Test
    func startsWithInfoHidden() {
        let viewModel = HomeViewModel()

        #expect(viewModel.isShowingInfo == false)
    }

    @Test
    func primaryButtonShowsInfo() {
        let viewModel = HomeViewModel()

        viewModel.primaryButtonTapped()

        #expect(viewModel.isShowingInfo)
    }

    @Test
    func infoDismissedHidesInfo() {
        let viewModel = HomeViewModel()
        viewModel.primaryButtonTapped()

        viewModel.infoDismissed()

        #expect(viewModel.isShowingInfo == false)
    }
}
