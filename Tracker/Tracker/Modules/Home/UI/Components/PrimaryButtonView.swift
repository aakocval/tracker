//
//  PrimaryButtonView.swift
//  Tracker
//

import SwiftUI

struct PrimaryButtonView: View {
    let title: String
    var tint: Color = .surfacesBrandDefault
    let action: VoidResult

    var body: some View {
        Button(action: action) {
            Text(title)
                .textStyle(.bodySemibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(tint)
    }
}

#if DEBUG
#Preview {
    VStack {
        PrimaryButtonView(title: "Get Started", action: {})
        PrimaryButtonView(title: "Stop", tint: .semanticsErrorDefault, action: {})
    }
    .padding()
}
#endif
