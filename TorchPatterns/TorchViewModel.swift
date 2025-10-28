import Combine

enum PatternKind: String, CaseIterable, Identifiable {
    case continuous, strobe, beacon, sos
    var id: String { rawValue }
}

final class TorchViewModel: ObservableObject {
    @Published var kind: PatternKind = .continuous
    @Published var brightness: Float = 0.75
    @Published var freqHz: Double = 2.0
    @Published var duty: Double = 0.5
    @Published var safetyCapEnabled = true
    @Published var isRunning = false
    @Published var log = [String]()

    private let service = TorchService()
    private lazy var engine = PatternEngine(service: service)

    func start() {
        guard service.supported else { log.append("Device has no torch"); return }
        let f = safetyCapEnabled ? min(freqHz, 3.0) : freqHz
        let p: TorchPattern = {
            switch kind {
            case .continuous: return .continuous
            case .strobe:     return .strobe(freqHz: f, duty: duty)
            case .beacon:     return .beacon(period: 2.0, on: 0.12)
            case .sos:        return .sos
            }
        }()

        do {
            try engine.start(p, level: brightness)
            isRunning = true
            log.append("Started \(kind.rawValue)")
        } catch {
            log.append("Start failed: \(error)")
        }
    }

    func stop() {
        engine.stop()
        isRunning = false
        log.append("Stopped")
    }
}
