//
//  Splash.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//
import SwiftUI

struct SplashView: View {
    
    let onFinished: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack {
                Image(systemName: "circle.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
                
                Text("Loop")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
        }
        
        .task {
            try? await Task.sleep(for: .seconds(2))
            onFinished()
        }
    }
}
