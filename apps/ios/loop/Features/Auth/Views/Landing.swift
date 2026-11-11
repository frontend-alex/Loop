//
//  Landing.swift
//  loop
//
//  Created by Aleksander Ivanov on 22/09/2026.
//
import SwiftUI
import ComposableArchitecture

struct LandingView: View {
    let store: StoreOf<AuthProvider>
    
    @State private var showProviders = false;
    @State private var sheetHeight: CFloat = 0;
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize;
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            GeometricBackground()
                .aspectRatio(2.67 / 4.0, contentMode: .fit)
            
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.lg){
                AppButton(
                    "Get Started",
                    fullWidth: true,
                    backgroundColor: DesignSystem.Semantic.foregroundPrimary,
                    foregroundColor: DesignSystem.Semantic.foregroundInverse,
                    action: {
                        showProviders = true
                    }
                )
                .sheet(isPresented: $showProviders) {
                    NavigationStack {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            AppButton(
                                backgroundColor: DesignSystem.Semantic.foregroundPrimary,
                                foregroundColor: DesignSystem.Semantic.foregroundInverse,
                                action: {
                                    showProviders = false
                                    store.send(.loginTapped(.apple))
                                }
                            ) {
                                Label("Continue with Apple", systemImage: "apple.logo")
                            }
                            
                            AppButton(
                                variant: .secondary,
                                action: {
                                    showProviders = false
                                    store.send(.loginTapped(.google))
                                }
                            ) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image("GoogleIcon")
                                    Text("Continue with Google")
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .navigationTitle("Get started")
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .tint(DesignSystem.Semantic.textPrimary)
                    .presentationDetents(
                        dynamicTypeSize.isAccessibilitySize
                        ? [.large]
                        : [.height(200)]
                    )
                    .presentationDragIndicator(.visible)
                }
                
                Text(
                    "By proceeding, you agree to our \(Text("Terms").bold().underline()) and \(Text("Privacy Policy").bold().underline())"
                )
                .font(.caption2)
                .lineLimit(1)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        
        
    }
}

#Preview {
    LandingView(store: Store(
        initialState: AuthProvider.State()
    ) {
        AuthProvider()
    }
    )
}
