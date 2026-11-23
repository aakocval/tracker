//
//  View+TextStyle.swift
//  Tracker
//

import SwiftUI

struct ProjectTextStyle {
    fileprivate let font: Font
    fileprivate let textCase: Text.Case?

    private init(
        font: Font,
        textCase: Text.Case? = nil
    ) {
        self.font = font
        self.textCase = textCase
    }

    static let display = ProjectTextStyle(font: .displayHeavy)
    static let title2 = ProjectTextStyle(font: .title2Bold)
    static let title3 = ProjectTextStyle(font: .title3Bold)
    static let bodySemibold = ProjectTextStyle(font: .bodySemibold)
    static let bodyBold = ProjectTextStyle(font: .bodyBold)
    static let subheadlineRegular = ProjectTextStyle(font: .subheadlineRegular)
    static let subheadlineSemibold = ProjectTextStyle(font: .subheadlineSemibold)
    static let subheadlineBold = ProjectTextStyle(font: .subheadlineBold)
    static let footnoteRegular = ProjectTextStyle(font: .footnoteRegular)
    static let footnoteSemiboldUpper = ProjectTextStyle(font: .footnoteSemibold, textCase: .uppercase)
    static let captionRegular = ProjectTextStyle(font: .captionRegular)
    static let captionSemibold = ProjectTextStyle(font: .captionSemibold)
}

extension View {
    func textStyle(_ style: ProjectTextStyle) -> some View {
        font(style.font)
            .textCase(style.textCase)
    }
}
