//
//  StatusPillView.swift
//  Tracker
//
//  Created by Val on 11/23/26.
//

import SwiftUI

struct StatusPillView: View {
    let text: String
    let status: TrackingStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)

            Text(text)
        }
        .textStyle(.footnoteRegular)
        .fontWeight(.semibold)
        .foregroundStyle(textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor, in: Capsule())
    }
}

// MARK: - Colors

private extension StatusPillView {
    var textColor: Color {
        switch status {
            case .idle: .textSecondary
            case .tracking: .semanticsSuccessText
            case .locationOff: .semanticsErrorText
        }
    }

    var dotColor: Color {
        switch status {
            case .idle: .iconsSecondary
            case .tracking: .semanticsSuccessDefault
            case .locationOff: .semanticsErrorDefault
        }
    }

    var backgroundColor: Color {
        switch status {
            case .idle: .surfacesBackground3
            case .tracking: .semanticsSuccessShade
            case .locationOff: .semanticsErrorShade
        }
    }
}

#if DEBUG
#Preview {
    VStack {
        StatusPillView(text: "Idle", status: .idle)
        StatusPillView(text: "Tracking", status: .tracking)
        StatusPillView(text: "Location off", status: .locationOff)
    }
}
#endif
