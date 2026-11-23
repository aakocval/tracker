//
//  HomeView.swift
//  Tracker
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                bannerView()
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
        .sheet(isPresented: $viewModel.isShowingLocationDenied) {
            LocationDeniedView(
                onOpenSettings: openAppSettings,
                onDismiss: { viewModel.isShowingLocationDenied = false }
            )
            .presentationDetents([.fraction(0.75), .medium])
        }
        .onAppear {
            viewModel.refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            viewModel.refreshAuthorizationStatus()
        }
    }
}

// MARK: - Sections

private extension HomeView {
    @ViewBuilder
    func bannerView() -> some View {
        if viewModel.isLocationDenied {
            TrackingBannerView(
                systemImage: "location.slash.fill",
                title: "Location access is off",
                message: "Tracker can’t measure your delivery distance without it.",
                tint: .semanticsErrorDark,
                background: .semanticsErrorShade,
                actionTitle: "How to turn it on",
                actionColor: .semanticsErrorText,
                action: viewModel.turnOnLocationTapped
            )
        }
    }

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
    func openAppSettings() {
        viewModel.isShowingLocationDenied = false
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

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
