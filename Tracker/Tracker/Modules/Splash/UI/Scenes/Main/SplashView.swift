//
//  SplashView.swift
//  Tracker
//

import SwiftUI

/// Shown briefly at launch. It matches the system launch screen (brand blue and the logo),
/// so the hand-over is seamless, then adds the app name.
struct SplashView: View {
    static let displayDuration: Duration = .seconds(1.2)

    let onFinish: VoidResult

    @State private var isShowingText = false

    var body: some View {
        ZStack {
            Color.surfacesBrandDefault
                .ignoresSafeArea()

            // The logo stays exactly where the launch screen put it; the text sits below it.
            Image(.logo)
                .overlay(alignment: .bottom) {
                    textView()
                        .fixedSize()
                        .alignmentGuide(.bottom) { $0[.top] - Spacing.xl }
                }
        }
        .task {
            withAnimation(.easeOut(duration: 0.4)) {
                isShowingText = true
            }

            try? await Task.sleep(for: Self.displayDuration)
            onFinish()
        }
    }
}

// MARK: - Sections

private extension SplashView {
    func textView() -> some View {
        VStack(spacing: Spacing.xs) {
            Text("Tracker")
                .textStyle(.title2)

            Text("Every delivery, every kilometre")
                .textStyle(.subheadlineRegular)
                .opacity(0.85)
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .opacity(isShowingText ? 1 : 0)
        .offset(y: isShowingText ? 0 : Spacing.sm)
    }
}

#if DEBUG
#Preview {
    SplashView(onFinish: {})
}
#endif
