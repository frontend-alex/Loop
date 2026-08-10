//
//  OnboardinbView.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

//import SwiftUI
//
//struct OnBoardingPage: Identifiable {
//    let id = UUID();
//    let title: String;
//    let substitle: String;
//    let systemImage: String;
//}
//
//struct OnboardingView: View {
//    
//    @EnvironmentObject private var router: AppRouter;
//    @State private var index = 0;
//    
//    let pages : [OnBoardingPage] = [
//        .init(title: "", substitle: "", systemImage: ""),
//        .init(title: "", substitle: "", systemImage: ""),
//        .init(title: "", substitle: "", systemImage: ""),
//        .init(title: "", substitle: "", systemImage: ""),
//    ]
//        
//    private var topBar: some View {
//        HStack {
//            if index > 0 {
//                Button("Back") {
//                    withAnimation(.spring()) {
//                        index -= 1;
//                    }
//                }
//                
//            }
//            
//            Spacer()
//
//            if index < pages.count - 1 {
//                Button("Skip") {
//                    withAnimation(.spring()) {
//                        index = pages.count - 1;
//                    }
//                }
//            }
//        }
//        .font(.headline)
//        .padding()
//    }
//    
//    @ViewBuilder
//    private func pageView(_ page: OnBoardingPage) -> some View {
//        VStack(spacing: 18) {
//            Spacer();
//            Image(systemName: page.systemImage)
//                .font(.system(size: 6, weight: .semibold))
//                .symbolRenderingMode(.hierarchical)
//            Text(page .title)
//                .font(.system(size: 34, weight: .bold))
//            Text(page .substitle)
//                .font(.system(size: 17, weight: .medium))
//                .foregroundStyle(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 12)
//        }
//    }
//    
//    private var progressPills: some View {
//        HStack(spacing: 8){
//            ForEach(pages.indices, id: \.self){ i in
//                Capsule()
//                    .frame(width: i == index ? 22 : 8, height: 8)
//                    .animation(.spring(), value: index)
//                    .foregroundStyle(.secondary.opacity(i == index ? 1 : 0.35))
//                    
//            }
//        }.padding(.top, 4)
//    }
//    
//    private var bottomBar: some View {
//        VStack(spacing: 14) {
//            progressPills
//            
//            Button {
//                withAnimation(.spring()) {
//                    if index < pages.count - 1 {
//                        index += 1;
//                    } else {
//                        router.finishOnboarding();
//                    }
//                }
//            } label: {
//                Text(index < pages.count - 1 ? "Get Started" : "Continue")
//                    .font(.headline)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 14)
//            }
//            .buttonStyle(.borderedProminent)
//            .buttonBorderShape(.roundedRectangle(radius: 16))
//        }
//        .padding()
//    }
//    
//    var body: some View {
//        VStack {
//            topBar
//            
//            TabView(selection: $index) {
//                ForEach(pages.indices, id: \.self) { i in
//                    pageView(pages[i])
//                        .tag(i)
//                }
//            }
//            .tabViewStyle(.page(indexDisplayMode: .never))
//            
//            bottomBar
//        }
//    }
//}
import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack {
            Text("Onboarding step")

            Button(
                store.step == .summary
                    ? "Finish"
                    : "Continue"
            ) {
                store.send(
                    store.step == .summary
                        ? .finishTapped
                        : .nextTapped
                )
            }
        }
        .padding()
    }
}

