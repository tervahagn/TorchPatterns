import SwiftUI

struct FullScreenPreviewView: View {
    @Binding var kind: PatternKind
    @Binding var freqHz: Double
    @Binding var duty: Double
    @Binding var safetyCapEnabled: Bool
    @Binding var brightness: Float
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let on = computeOn(kind: kind,
                               t: t,
                               fHz: safetyCapEnabled ? min(freqHz, 3.0) : freqHz,
                               duty: duty)
            let intensity = (on ? 1.0 : 0.1) * Double(brightness)

            ZStack {
                Color.black.ignoresSafeArea()
                Color.white.opacity(intensity)
                    .ignoresSafeArea()
                    .blendMode(.screen)

                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Label("Close", systemImage: "xmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.gray.opacity(0.3))
                        .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding()
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true)
        .contentTransition(.opacity)
        .onTapGesture { dismiss() }
    }
}

