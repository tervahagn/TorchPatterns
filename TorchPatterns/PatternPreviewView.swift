import SwiftUI

struct PatternPreviewView: View {
    @Binding var kind: PatternKind
    @Binding var freqHz: Double
    @Binding var duty: Double
    @Binding var safetyCapEnabled: Bool
    @Binding var brightness: Float

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let on = computeOn(kind: kind,
                               t: t,
                               fHz: safetyCapEnabled ? min(freqHz, 3.0) : freqHz,
                               duty: duty)
            let intensity = (on ? 1.0 : 0.15) * Double(brightness)
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(.quaternary, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(colors: [.yellow.opacity(0.08), .orange.opacity(0.08)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                RoundedRectangle(cornerRadius: 14)
                    .fill(RadialGradient(gradient: Gradient(colors: [
                        .yellow.opacity(0.30 * intensity),
                        .yellow.opacity(0.14 * intensity),
                        .clear
                    ]), center: .topLeading, startRadius: 8, endRadius: 320))
                    .padding(8)
                    .overlay(
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Live Preview (no torch)", systemImage: "eye")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(8)
                            Spacer()
                        }
                    )
            }
            .frame(height: 120)
            .animation(.linear(duration: 0.08), value: intensity)
        }
    }
}

func computeOn(kind: PatternKind, t: TimeInterval, fHz: Double, duty: Double) -> Bool {
    switch kind {
    case .continuous: return true
    case .strobe:
        let f = max(0.1, min(fHz, 15.0))
        let d = max(0.05, min(duty, 0.95))
        let period = 1.0 / f
        let phase = t.truncatingRemainder(dividingBy: period)
        return phase < period * d
    case .beacon:
        let period = 2.0, on = 0.12
        let phase = t.truncatingRemainder(dividingBy: period)
        return phase < on
    case .sos:
        let u = 0.2
        let seq: [Double] = [1,1, 1,1, 1,3, 3,1, 3,1, 3,3, 1,1, 1,1, 1,7]
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
