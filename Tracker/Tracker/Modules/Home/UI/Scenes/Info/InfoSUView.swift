//
//  InfoSUView.swift
//  Tracker
//

import SwiftUI

struct InfoSUView: View {
  let onDismiss: VoidResult

  var body: some View {
    VStack(spacing: Spacing.md) {
      Image(systemName: "shippingbox.fill")
        .font(.system(size: 28))
        .foregroundStyle(Color.surfacesBrandDefault)
        .frame(width: 64, height: 64)
        .background(Color.semanticsInfoShade, in: Circle())
        .padding(.top, Spacing.xl)

      Text("Coming soon")
        .textStyle(.title2)
        .foregroundStyle(Color.textPrimary)

      Text("Features are added as modules under Modules/.")
        .textStyle(.subheadlineRegular)
        .foregroundStyle(Color.textSecondary)
        .multilineTextAlignment(.center)

      Spacer(minLength: Spacing.sm)

      PrimaryButtonView(title: "Done", action: onDismiss)
        .padding(.bottom, Spacing.sm)
    }
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfacesBackground2)
  }
}

#if DEBUG
#Preview {
  InfoSUView(onDismiss: {})
}
#endif
