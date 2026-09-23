import SwiftUI

extension DesignSystem {
    enum Palette {
        private static func asset(_ name: String) -> Color {
            Color(name, bundle: .main)
        }

        static var brand100: Color { asset("LoopPalette-Brand-100") }
        static var brand200: Color { asset("LoopPalette-Brand-200") }
        static var brand300: Color { asset("LoopPalette-Brand-300") }
        static var brand400: Color { asset("LoopPalette-Brand-400") }
        static var brand500: Color { asset("LoopPalette-Brand-500") }
        static var brand600: Color { asset("LoopPalette-Brand-600") }
        static var brand700: Color { asset("LoopPalette-Brand-700") }
        static var brand800: Color { asset("LoopPalette-Brand-800") }
        static var brand900: Color { asset("LoopPalette-Brand-900") }

        static var success100: Color { asset("LoopPalette-Success-100") }
        static var success200: Color { asset("LoopPalette-Success-200") }
        static var success300: Color { asset("LoopPalette-Success-300") }
        static var success400: Color { asset("LoopPalette-Success-400") }
        static var success500: Color { asset("LoopPalette-Success-500") }
        static var success600: Color { asset("LoopPalette-Success-600") }
        static var success700: Color { asset("LoopPalette-Success-700") }
        static var success800: Color { asset("LoopPalette-Success-800") }
        static var success900: Color { asset("LoopPalette-Success-900") }

        static var warning100: Color { asset("LoopPalette-Warning-100") }
        static var warning200: Color { asset("LoopPalette-Warning-200") }
        static var warning300: Color { asset("LoopPalette-Warning-300") }
        static var warning400: Color { asset("LoopPalette-Warning-400") }
        static var warning500: Color { asset("LoopPalette-Warning-500") }
        static var warning600: Color { asset("LoopPalette-Warning-600") }
        static var warning700: Color { asset("LoopPalette-Warning-700") }
        static var warning800: Color { asset("LoopPalette-Warning-800") }
        static var warning900: Color { asset("LoopPalette-Warning-900") }

        static var danger100: Color { asset("LoopPalette-Danger-100") }
        static var danger200: Color { asset("LoopPalette-Danger-200") }
        static var danger300: Color { asset("LoopPalette-Danger-300") }
        static var danger400: Color { asset("LoopPalette-Danger-400") }
        static var danger500: Color { asset("LoopPalette-Danger-500") }
        static var danger600: Color { asset("LoopPalette-Danger-600") }
        static var danger700: Color { asset("LoopPalette-Danger-700") }
        static var danger800: Color { asset("LoopPalette-Danger-800") }
        static var danger900: Color { asset("LoopPalette-Danger-900") }

        static var info100: Color { asset("LoopPalette-Info-100") }
        static var info200: Color { asset("LoopPalette-Info-200") }
        static var info300: Color { asset("LoopPalette-Info-300") }
        static var info400: Color { asset("LoopPalette-Info-400") }
        static var info500: Color { asset("LoopPalette-Info-500") }
        static var info600: Color { asset("LoopPalette-Info-600") }
        static var info700: Color { asset("LoopPalette-Info-700") }
        static var info800: Color { asset("LoopPalette-Info-800") }
        static var info900: Color { asset("LoopPalette-Info-900") }

        static var neutral100: Color { asset("LoopPalette-Neutral-100") }
        static var neutral200: Color { asset("LoopPalette-Neutral-200") }
        static var neutral300: Color { asset("LoopPalette-Neutral-300") }
        static var neutral400: Color { asset("LoopPalette-Neutral-400") }
        static var neutral500: Color { asset("LoopPalette-Neutral-500") }
        static var neutral600: Color { asset("LoopPalette-Neutral-600") }
        static var neutral700: Color { asset("LoopPalette-Neutral-700") }
        static var neutral800: Color { asset("LoopPalette-Neutral-800") }
        static var neutral900: Color { asset("LoopPalette-Neutral-900") }

        static var white: Color { asset("LoopPalette-White") }
        static var black: Color { asset("LoopPalette-Black") }
    }

    enum Semantic {
        private static func asset(_ name: String) -> Color {
            Color(name, bundle: .main)
        }

        static var backgroundPrimary: Color { asset("LoopSemantic-Background-Primary") }
        static var backgroundSecondary: Color { asset("LoopSemantic-Background-Secondary") }
        static var surfacePrimary: Color { asset("LoopSemantic-Surface-Primary") }
        static var surfaceSecondary: Color { asset("LoopSemantic-Surface-Secondary") }
        static var textPrimary: Color { asset("LoopSemantic-Text-Primary") }
        static var textSecondary: Color { asset("LoopSemantic-Text-Secondary") }
        static var borderDefault: Color { asset("LoopSemantic-Border-Default") }
        static var buttonPrimaryTint: Color { asset("LoopSemantic-Button-Primary-Tint") }
        static var buttonPrimaryForeground: Color { asset("LoopSemantic-Button-Primary-Foreground") }
        static var buttonSecondaryTint: Color { asset("LoopSemantic-Button-Secondary-Tint") }
        static var buttonSecondaryForeground: Color { asset("LoopSemantic-Button-Secondary-Foreground") }
        static var buttonMutedTint: Color { asset("LoopSemantic-Button-Muted-Tint") }
        static var buttonMutedForeground: Color { asset("LoopSemantic-Button-Muted-Foreground") }
        static var buttonGhostTint: Color { asset("LoopSemantic-Button-Ghost-Tint") }
        static var buttonGhostForeground: Color { asset("LoopSemantic-Button-Ghost-Foreground") }
        static var buttonDangerTint: Color { asset("LoopSemantic-Button-Danger-Tint") }
        static var buttonDangerForeground: Color { asset("LoopSemantic-Button-Danger-Foreground") }
        static var buttonDisabledTint: Color { asset("LoopSemantic-Button-Disabled-Tint") }
        static var buttonDisabledForeground: Color { asset("LoopSemantic-Button-Disabled-Foreground") }
        static var foregroundPrimary: Color { asset("LoopSemantic-Foreground-Primary") }
        static var foregroundInverse: Color { asset("LoopSemantic-Foreground-Inverse") }
    }
}
