import SwiftUI

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

extension ShapeStyle where Self == Color {
    static var brand: Color { Color("LoopPalette-Brand-500") }
    static var danger: Color { Color("LoopPalette-Danger-600") }

    static var backgroundPrimary: Color { Color("LoopSemantic-Background-Primary") }
    static var backgroundSecondary: Color { Color("LoopSemantic-Background-Secondary") }
    static var surfacePrimary: Color { Color("LoopSemantic-Surface-Primary") }
    static var textPrimary: Color { Color("LoopSemantic-Text-Primary") }
    static var textSecondary: Color { Color("LoopSemantic-Text-Secondary") }
    static var border: Color { Color("LoopSemantic-Border-Default") }
    static var foregroundPrimary: Color { Color("LoopSemantic-Foreground-Primary") }
    static var foregroundInverse: Color { Color("LoopSemantic-Foreground-Inverse") }
}
