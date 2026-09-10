//
//  Onboarding.View.swift
//  loop
//
//  Created by Aleksander Ivanov on 10/08/2026.
//

import SwiftUI
import ComposableArchitecture

struct OnboardingView: View {
    let store: StoreOf<OnboardingProvider>
    
    private var topBar: some View {
        HStack {
            Button("Back"){
                store.send(.backTapped)
            }
            .disabled(
                store.step == .questions && store.questionIndex == 0
            )
            
            Spacer()
        }
        .padding()
    }
    
    private var bottomBar: some View {
        Button {
            switch store.step {
                   case .alarm:
                       store.send(.alarmSetTapped)

                   case .summary:
                       store.send(.finishTapped)

                   default:
                       store.send(.nextTapped)
                   }

        } label: {
            Text(
                store.step == .alarm
                ? "Set Alarm"
                :store.step == .summary
                    ? "Finish"
                    : "Continue"
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 16)
        {
            topBar
            
            Spacer()
            
            switch store.step {
            case .questions:
                QuestionsView(store: store);
            
            case .alarm:
                AlarmView(
                    onAlarmChanged: { alarm in
                        store.send(.alarmSelected(alarm))
                    }
                )
            case .apps:
                AppBlockingView(store:store);
                
            case .tasks:
                Text("Tasks")
                
            case .summary:
                Text("Summary")
            }
            
            Spacer()
            
            bottomBar
        }
    }
}


//#Preview {
//    OnboardingView(
//        store: Store(
//            initialState: OnboardingProvider.State(step: .alarm)
//        ) {
//            OnboardingProvider()
//        }
//    )
//}
