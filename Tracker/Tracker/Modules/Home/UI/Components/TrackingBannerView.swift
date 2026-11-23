//
//  TrackingBannerView.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import SwiftUI

struct TrackingBannerView: View {
    let systemImage: String
    let title: String
    let message: String
    let tint: Color
    let background: Color
    let actionTitle: String
    let actionColor: Color
    let action: VoidResult

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.title3)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .textStyle(.bodyBold)

                Text(message)
                    .textStyle(.subheadlineRegular)

                Button(actionTitle, action: action)
                    .textStyle(.subheadlineSemibold)
                    .underline()
                    .foregroundStyle(actionColor)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .foregroundStyle(tint)
        .padding(Spacing.lg)
        .background(background, in: RoundedRectangle(cornerRadius: Radius.lg))
    }
}

#if DEBUG
#Preview {
    TrackingBannerView(
        systemImage: "location.slash.fill",
        title: "Location access is off",
        message: "Tracker message",
        tint: .semanticsErrorDark,
        background: .semanticsErrorShade,
        actionTitle: "How to turn it on",
        actionColor: .semanticsErrorText,
        action: {}
    )
    .padding()
}
#endif
