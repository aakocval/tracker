//
//  HomeSUView.swift
//  Tracker
//

import SwiftUI

struct HomeSUView<ViewModel: HomeViewModelProtocol>: View {
  @Bindable var viewModel: ViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: Spacing.md) {
        headerCardView()
      }
      .padding(.horizontal, Spacing.lg)
      .padding(.vertical, Spacing.xs)
    }
    .background(Color.surfacesBackground)
    .safeAreaInset(edge: .bottom) {
      PrimaryButtonView(
        title: viewModel.primaryButtonTitle,
        action: viewModel.primaryButtonTapped
      )
      .padding(.horizontal, Spacing.lg)
      .padding(.vertical, Spacing.sm)
      .background(.bar)
    }
    .navigationTitle(viewModel.title)
    .sheet(isPresented: $viewModel.isShowingInfo) {
      InfoSUView(onDismiss: viewModel.infoDismissed)
        .presentationDetents([.medium])
    }
  }
}

// MARK: - Sections

private extension HomeSUView {
  func headerCardView() -> some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      Text("Welcome")
        .textStyle(.footnoteSemiboldUpper)
        .foregroundStyle(Color.textTertiary)

      Text(viewModel.message)
        .textStyle(.title3)
        .foregroundStyle(Color.textPrimary)
    }
    .padding(Spacing.lg)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.surfacesBackground2, in: RoundedRectangle(cornerRadius: Radius.lg))
  }
}

#if DEBUG
#Preview {
  NavigationStack {
    HomeSUView(viewModel: HomeViewModel())
  }
}
#endif
