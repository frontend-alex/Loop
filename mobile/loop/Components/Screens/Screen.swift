//
//  Container.swift
//  loop
//
//  Created by Aleksander Ivanov on 15/09/2026.
//
import SwiftUI


struct ScreenContent<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .safeAreaPadding(.horizontal, DesignSystem.Spacing.md)
    }
}
