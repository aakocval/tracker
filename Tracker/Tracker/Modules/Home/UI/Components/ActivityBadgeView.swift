//
//  ActivityBadgeView.swift
//  Tracker
//

import SwiftUI

struct ActivityBadgeView: View {
    let text: String
    let symbolName: String?
    let activity: TrackingActivity

    var body: some View {
        HStack(spacing: 6) {
            if let symbolName {
                Image(systemName: symbolName)
            }

            Text(text)
        }
        .textStyle(.subheadlineBold)
        .foregroundStyle(tintColor)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 7)
        .background(backgroundColor, in: Capsule())
    }
}

// MARK: - Colors

private extension ActivityBadgeView {
    var tintColor: Color {
        switch activity {
        case .none: .textTertiary
        case .walking: .semanticsInfoDefault
        case .driving: .semanticsWarningDefault
        }
    }

    var backgroundColor: Color {
        switch activity {
        case .none: .surfacesDisabled
        case .walking: .semanticsInfoShade
        case .driving: .semanticsWarningShade
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        ActivityBadgeView(text: "Not tracking", symbolName: nil, activity: .none)
        ActivityBadgeView(text: "Walking", symbolName: "figure.walk", activity: .walking)
        ActivityBadgeView(text: "Driving", symbolName: "car.fill", activity: .driving)
    }
}
#endif
