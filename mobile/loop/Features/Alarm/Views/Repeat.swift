//
//  AlarmRepeat.swift
//  loop
//
//  Created by Aleksander Ivanov on 15/09/2026.
//
import SwiftUI

struct AlarmRepeatView: View {
    @Binding var selectedDays: Set<AlarmWeekday>

    var body: some View {
        List {
            Section {
                ForEach(AlarmWeekday.allCases) { day in
                    Toggle(
                        day.title,
                        isOn: Binding(
                            get: {
                                selectedDays.contains(day)
                            },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        )
                    )
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
