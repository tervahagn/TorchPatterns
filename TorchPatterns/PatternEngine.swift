import Foundation

enum TorchPattern: Equatable {
    case continuous
    case strobe(freqHz: Double, duty: Double)
    case beacon(period: Double, on: Double)
    case sos
}

final class PatternEngine {
    private let service: TorchService
    private let q = DispatchQueue(label: "torch.pattern.queue", qos: .userInteractive)
    private var running = false

    init(service: TorchService) { self.service = service }

    func start(_ pattern: TorchPattern, level: Float) throws {
        guard service.supported else { throw TorchError.unsupported }
        if running { stop() }
        running = true
        try service.lock()
        q.async { [weak self] in self?.runLoop(pattern, level: level) }
    }

    func stop() {
        running = false
        q.sync {
            try? service.set(on: false, level: 0)
            service.unlock()
        }
    }

    private func sleepNs(_ ns: UInt64) {
        let sec = ns / 1_000_000_000
        let nsec = ns % 1_000_000_000
        var ts = timespec(tv_sec: Int(sec), tv_nsec: Int(nsec))
        nanosleep(&ts, nil)
    }

    private func runLoop(_ pattern: TorchPattern, level: Float) {
        let baseLevel = service.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue ? min(level, 0.5) : level

        switch pattern {
        case .continuous:
            try? service.set(on: true, level: baseLevel)
            while running { sleepNs(100_000_000) }

        case let .strobe(freqHz, duty):
            let f = max(0.1, min(freqHz, 15))
            let clampedDuty = max(0.05, min(duty, 0.95))
            let periodNs = UInt64((1.0 / f) * 1_000_000_000.0)
            let onNs = UInt64(Double(periodNs) * clampedDuty)
            let offNs = periodNs - onNs
            while running {
                try? service.set(on: true, level: baseLevel)
                sleepNs(onNs)
                try? service.set(on: false, level: 0)
                sleepNs(offNs)
            }

        case let .beacon(period, on):
            let pNs = UInt64(max(0.5, period) * 1_000_000_000.0)
            let onNs = UInt64(max(0.05, min(on, period)) * 1_000_000_000.0)
            while running {
                try? service.set(on: true, level: baseLevel)
                sleepNs(onNs)
                try? service.set(on: false, level: 0)
                sleepNs(pNs - onNs)
            }

        case .sos:
            let u: UInt64 = 200_000_000
            let dot = u, dash = 3*u, gap = u, letterGap = 3*u, wordGap = 7*u
            let seq: [UInt64] = [
                dot, gap, dot, gap, dot, letterGap,
                dash, gap, dash, gap, dash, letterGap,
                dot, gap, dot, gap, dot, wordGap
            ]
            while running {
                for (i, dur) in seq.enumerated() where running {
                    if i % 2 == 0 { try? service.set(on: true, level: baseLevel) }
                    else { try? service.set(on: false, level: 0) }
                    sleepNs(dur)
                }
            }
        }
    }
}
