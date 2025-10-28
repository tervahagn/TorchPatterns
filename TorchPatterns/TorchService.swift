import AVFoundation

enum TorchError: Error { case unsupported, lockFailed, opFailed }

final class TorchService {
    private let device = AVCaptureDevice.default(for: .video)
    private var isLocked = false

    var supported: Bool { device?.hasTorch ?? false }
    var thermalState: ProcessInfo.ThermalState { ProcessInfo.processInfo.thermalState }

    func lock() throws {
        guard let d = device, d.hasTorch else { throw TorchError.unsupported }
        do { try d.lockForConfiguration(); isLocked = true } catch { throw TorchError.lockFailed }
    }
    func unlock() {
        guard isLocked, let d = device else { return }
        d.unlockForConfiguration()
        isLocked = false
    }
    func set(on: Bool, level: Float) throws {
        guard let d = device, d.hasTorch else { throw TorchError.unsupported }
        var tempLocked = false
        if !isLocked {
            do { try d.lockForConfiguration(); isLocked = true; tempLocked = true } catch { throw TorchError.lockFailed }
        }
        defer { if tempLocked { d.unlockForConfiguration(); isLocked = false } }
        if on {
            let clamped = max(0.01, min(level, 1.0))
            do {
                try d.setTorchModeOn(level: clamped == 1.0 ? AVCaptureDevice.maxAvailableTorchLevel : clamped)
            } catch { throw TorchError.opFailed }
        } else {
            d.torchMode = .off
        }
    }
}
