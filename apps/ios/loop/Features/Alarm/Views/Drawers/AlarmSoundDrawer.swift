import SwiftUI

struct AlarmSoundDrawer: View {
    @Binding var selection: AlarmSound

    var body: some View {
        List(AlarmSound.allCases) { sound in
            Button {
                selection = sound
            } label: {
                HStack {
                    Text(sound.title)
                    Spacer()
                    if selection == sound {
                        Image(systemName: "checkmark")
                            .accessibilityHidden(true)
                    }
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityAddTraits(selection == sound ? [.isSelected] : [])
        }
    }
}
