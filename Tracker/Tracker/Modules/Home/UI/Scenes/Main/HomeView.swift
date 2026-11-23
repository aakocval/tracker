//
//  HomeView.swift
//  Tracker
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                mapCardView()
                locationCardView()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .background(Color.surfacesBackground)
        .safeAreaInset(edge: .bottom) {
            trackingButtonView()
        }
        .navigationTitle("Tracker")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                StatusPillView(text: viewModel.statusText, status: viewModel.status)
                    .fixedSize()
            }
        }
        .onAppear {
            viewModel.refreshAuthorizationStatus()
        }
    }
}

// MARK: - Sections

private extension HomeView {
    func mapCardView() -> some View {
        RouteMapView(route: viewModel.route, currentLocation: viewModel.currentLocation)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(alignment: .top) {
                if !viewModel.isTracking, viewModel.route.isEmpty {
                    Text("Your route will appear here once tracking starts.")
                        .textStyle(.footnoteRegular)
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
                        .padding(Spacing.md)
                }
            }
    }

    func locationCardView() -> some View {
        VStack(spacing: 0) {
            locationRowView("Latitude", value: viewModel.latitudeText)

            Divider()
                .overlay(Color.bordersDefault)

            locationRowView("Longitude", value: viewModel.longitudeText)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.xs)
        .background(Color.surfacesBackground2, in: RoundedRectangle(cornerRadius: Radius.lg))
    }

    func trackingButtonView() -> some View {
        Button(action: viewModel.trackingButtonTapped) {
            Label(
                viewModel.trackingButtonTitle,
                systemImage: viewModel.isTracking ? "stop.fill" : "location.fill"
            )
            .textStyle(.bodySemibold)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(viewModel.isTracking ? Color.semanticsErrorDefault : Color.surfacesBrandDefault)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.bar)
    }
}

// MARK: - Helpers

private extension HomeView {
    func locationRowView(
        _ title: String,
        value: String
    ) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.textSecondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        }
        .textStyle(.subheadlineRegular)
        .padding(.vertical, Spacing.md)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(locationService: LocationService())
        )
    }
}
#endif
