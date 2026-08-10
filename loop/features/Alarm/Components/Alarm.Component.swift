//
//  Alarm.Component.swift
//  loop
//
//  Created by Aleksander Ivanov on 12/08/2026.
//
import SwiftUI

struct AlarmComponent: View {
    var isLeft: Bool
    
    @Binding var edit: Bool
    @Binding var selectedValue: String
    
    let values: [String]
    let title: String
    
    @State private var scrollID: String? = nil
    
    var body: some View {
        HStack(spacing: edit ? 5 : 0){
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: -30){
                            ForEach(values, id: \.self) { value in
                                Text(value)
                                    .font(.system(size: 25, weight: .bold))
                                    .frame(height: 63)
                                    .foregroundStyle(
                                        selectedValue == value ? Color.primary : Color.gray
                                    )
                                    .id(value)
                                    .opacity(
                                        selectedValue == value || edit ? 1 : 0.01
                                    )
                                    .scrollTransition(.interactive, axis: .vertical) { content, phase in
                                        content.scaleEffect(
                                            phase.isIdentity ? 1 : 0.1
                                        )
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollIndicators(.hidden)
                    .safeAreaPadding(.vertical, 18)
                    .scrollPosition(id: $scrollID , anchor: .center)
                    .scrollTargetBehavior(.viewAligned)
                    .allowsHitTesting(edit)
                    .onAppear {
                        scrollID = selectedValue
                        DispatchQueue.main.async {
                            proxy.scrollTo(selectedValue, anchor: .center)
                        }
                    }
                    .onChange(of: scrollID){_, newID in
                        if let newID { selectedValue = newID }
                    }
                }
            }
            .frame(width: 40, height: 100)
            Text(title) .font(.system(size: 25)).bold().foregroundStyle(.gray)
        }
        .padding(.trailing, 3)
        .padding(edit ? .horizontal : .leading,10)
        .frame(height: edit ? 105 : 60).clipped()
        .background(
            Color(uiColor: .tertiarySystemBackground),
            in:shape(edit: edit, isLeft: isLeft)
        )
    }
}


func shape(edit: Bool, isLeft: Bool) -> UnevenRoundedRectangle {
    if edit {
        return UnevenRoundedRectangle(
            topLeadingRadius: 12,
            bottomLeadingRadius: 12,
            bottomTrailingRadius: 12,
            topTrailingRadius: 12,
        )
    }  else {
        if isLeft {
            return UnevenRoundedRectangle(
                topLeadingRadius: 12,
                bottomLeadingRadius: 12,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
            )
        } else {
            return UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
            )
        }
    }
}

//#Preview {
//    @Previewable @State var isEditing = true
//    @Previewable @State var selectedValue: String = "1"
//    
//    AlarmComponent(
//        isLeft: true,
//        edit: $isEditing,
//        selectedValue:$selectedValue,
//        values: (1...59).map(String.init),
//        title: "Cicki"
//    )
//}
