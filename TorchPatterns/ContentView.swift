import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scene
    @StateObject private var vm = TorchViewModel()
    @State private var showFullScreenPreview = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 12) {
                header

                Toggle(isOn: $vm.isPreviewEnabled) {
                    Label("Live Preview", systemImage: "eye")
                }
                .padding(.horizontal, 20)

                if vm.isPreviewEnabled {
                    PatternPreviewView(kind: $vm.kind,
                                       freqHz: $vm.freqHz,
                                       duty: $vm.duty,
                                       safetyCapEnabled: $vm.safetyCapEnabled,
                                       brightness: $vm.brightness)
                        .padding(.horizontal, 20)
                        .onTapGesture { showFullScreenPreview = true }
                }

                controls
                    .padding(.horizontal, 20)

                Spacer(minLength: 0)

                footer
            }
            .frame(maxWidth: 393) // baseline width for modern 6.1" screens
        }
        .onChange(of: scene) { phase in
            if phase != .active { vm.stop() }
        }
        .fullScreenCover(isPresented: $showFullScreenPreview) {
            FullScreenPreviewView(kind: $vm.kind,
                                  freqHz: $vm.freqHz,
                                  duty: $vm.duty,
                                  safetyCapEnabled: $vm.safetyCapEnabled,
                                  brightness: $vm.brightness)
        }
    }

    var header: some View {
        HStack {
            Label("Torch Patterns", systemImage: "flashlight.on.fill")
                .font(.headline)
            Spacer()
            Text(vm.isRunning ? "ON" : "OFF")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(vm.isRunning ? .green : .secondary)
        }
        .padding(.top, 12)
        .padding(.horizontal, 20)
    }

    var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                PatternChip(title: "Cont.", systemName: "sun.max.fill", active: vm.kind == .continuous) { vm.kind = .continuous }
                PatternChip(title: "Strobe", systemName: "bolt.fill", active: vm.kind == .strobe) { vm.kind = .strobe }
                PatternChip(title: "Beacon", systemName: "metronome", active: vm.kind == .beacon) { vm.kind = .beacon }
                PatternChip(title: "SOS", systemName: "exclamationmark.triangle.fill", active: vm.kind == .sos) { vm.kind = .sos }
            }

            if vm.kind == .strobe {
                GroupBox {
                    VStack(spacing: 10) {
                        sliderRow(title: "Frequency",
                                  valueText: String(format: "%.1f Hz", vm.safetyCapEnabled ? min(vm.freqHz, 3.0) : vm.freqHz),
                                  value: $vm.freqHz, range: 0.5...15, step: 0.1)
                        sliderRow(title: "Duty",
                                  valueText: String(format: "%d%%", Int(vm.duty * 100)),
                                  value: $vm.duty, range: 0.05...0.95, step: 0.01)
                        Toggle(isOn: $vm.safetyCapEnabled) {
                            Label("Safety cap 3 Hz", systemImage: "shield.fill")
                        }
                        .tint(.red)
                        .font(.footnote)
                    }
                }
            }

            GroupBox {
                sliderRow(title: "Brightness",
                          valueText: String(format: "%.2f", vm.brightness),
                          value: Binding(get: { Double(vm.brightness) }, set: { vm.brightness = Float($0) }),
                          range: 0...1, step: 0.01)
            }
        }
    }

    var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    vm.isRunning ? vm.stop() : vm.start()
                } label: {
                    Label(vm.isRunning ? "Stop" : "Start", systemImage: "power.circle.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.isRunning ? .red : .accentColor)
            }
            .padding(.horizontal, 20)

            Text("Preview shows pattern without torch. Start will activate torch on device.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.bottom, 10)
        }
        .background(.thinMaterial)
    }

    func sliderRow(title: String, valueText: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(title).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Text(valueText).font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }
}

struct PatternChip: View {
    let title: String
    let systemName: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .labelStyle(.titleAndIcon)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(active ? Color.primary : .clear)
                .foregroundStyle(active ? Color.white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(active ? Color.clear : Color.secondary.opacity(0.25), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
