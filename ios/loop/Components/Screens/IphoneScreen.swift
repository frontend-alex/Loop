//
//  IphoneScreen.swift
//  loop
//
//  Created by Aleksander Ivanov on 16/09/2026.
//

import SwiftUI

struct IphoneScreen<Content: View>: View {
    let tint: Color
    let showsNotch: Bool
    let content: () -> Content

    init(
        tint: Color = .gray,
        showsNotch: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.tint = tint
        self.showsNotch = showsNotch
        self.content = content
    }

    var body: some View {
        Rectangle()
            .foregroundStyle(.clear)
            .overlay(alignment: .top) {
                let cornerRadius: CGFloat = 55
                let fill = Color.primary.opacity(0.15)

                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .overlay(alignment: .top) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Text("9:41")
                                    .padding(.leading, 24)

                                Spacer(minLength: 0)

                                Image(systemName: "wifi")
                                Image(systemName: "battery.50percent")
                            }
                            .font(.system(size: 18))
                            .fontWeight(.medium)
                            .frame(height: 37)
                            .padding(.horizontal, 35)
                            .offset(y: 18)
                        }
                        .overlay(alignment: .top) {
                            if showsNotch {
                                Capsule()
                                    .fill(.black)
                                    .frame(width: 120, height: 37)
                                    .offset(y: 15)
                            }
                        }

                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius + 7)
                            .stroke(tint, lineWidth: 12)
                        RoundedRectangle(cornerRadius: cornerRadius + 7)
                            .stroke(.black, lineWidth: 4)
                        RoundedRectangle(cornerRadius: cornerRadius + 3)
                            .stroke(.black, lineWidth: 6)
                            .padding(4)
                    }
                    .padding(-7)

                    content()
                }
                .frame(width: 402, height: 874)
            }
            .visualEffect { content, proxy in
                let designSize = CGSize(width: 402, height: 874)
                let ratio = min(
                    proxy.size.width / designSize.width,
                    proxy.size.height / designSize.height
                )

                return content.scaleEffect(ratio, anchor: .top)
            }
            .aspectRatio(402 / 874, contentMode: .fit)
    }
}
