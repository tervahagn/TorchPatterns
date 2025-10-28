import SwiftUI

struct PatternPreviewView: View {
    @Binding var kind: PatternKind
    @Binding var freqHz: Double
    @Binding var duty: Double
    @Binding var safetyCapEnabled: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let on = isOn(t)
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.gray, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(on ? Color.yellow.opacity(0.85) : Color.yellow.opacity(0.15))
                            .blur(radius: 6)
                    )
                Text("Live Preview (no torch)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 240)
        }
    }

    private func isOn(_ t: TimeInterval) -> Bool {
        switch kind {
        case .continuous:
            return true
        case .strobe:
            let f = safetyCapEnabled ? min(freqHz, 3.0) : freqHz
            let fClamped = max(0.1, min(f, 15.0))
            let dClamped = max(0.05, min(duty, 0.95))
            let period = 1.0 / fClamped
            let phase = t.truncatingRemainder(dividingBy: period)
            return phase < period * dClamped
        case .beacon:
            let period = 2.0, onWin = 0.12
            let phase = t.truncatingRemainder(dividingBy: period)
            return phase < onWin
        case .sos:
            let u = 0.2
            let seq: [Double] = [
                1,1, 1,1, 1,3,
                3,1, 3,1, 3,3,
                1,1, 1,1, 1,7
            ]
            let total = seq.reduce(0,+) * u
            var phase = t.truncatingRemainder(dividingBy: total)
            for (i, units) in seq.enumerated() {
                let dur = units * u
                if phase < dur { return i % 2 == 0 }
                phase -= dur
            }
            return false
        }
    }
}
