//
//  LocationDeniedView.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import SwiftUI

struct LocationDeniedView: View {
    let onOpenSettings: VoidResult
    let onDismiss: VoidResult

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 28))
                .foregroundStyle(Color.semanticsErrorDefault)
                .frame(width: 64, height: 64)
                .background(Color.semanticsErrorShade, in: Circle())
                .padding(.top, Spacing.xl)

            Text("Turn on location access")
                .textStyle(.title2)
                .foregroundStyle(Color.textPrimary)

            Text("Distance is part of how you’re paid, so Tracker needs your location while the app is open.")
                .textStyle(.subheadlineRegular)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                stepView(1, "Open **Settings**")
                stepView(2, "Tap **Location**")
                stepView(3, "Choose **While Using the App**")
                stepView(4, "Turn on **Precise Location**")
            }
            .textStyle(.subheadlineRegular)
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(Color.surfacesBackground, in: RoundedRectangle(cornerRadius: Radius.md))

            Spacer(minLength: Spacing.sm)

            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .textStyle(.bodySemibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.surfacesBrandDefault)

            Button("Not Now", action: onDismiss)
                .textStyle(.bodySemibold)
                .foregroundStyle(Color.textBrandDefault)
                .padding(.bottom, Spacing.sm)
        }
        .padding(.horizontal, Spacing.xl)
        .background(Color.surfacesBackground2)
    }
}

// MARK: - Helpers

private extension LocationDeniedView {
    func stepView(
        _ number: Int,
        _ text: LocalizedStringKey
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number).")
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()

            Text(text)
        }
    }
}

#if DEBUG
#Preview {
    LocationDeniedView(onOpenSettings: {}, onDismiss: {})
}
#endif
