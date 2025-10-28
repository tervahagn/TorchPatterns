import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scene
    @StateObject private var vm = TorchViewModel()

    var body: some View {
        VStack(spacing: 16) {
            header

            PatternPreviewView(
                kind: $vm.kind,
                freqHz: $vm.freqHz,
                duty: $vm.duty,
                safetyCapEnabled: $vm.safetyCapEnabled
            )

            patternPicker
            freqDutyControls
            HStack {
                Text("Brightness")
                Slider(value: $vm.brightness, in: 0...1)
                Text(String(format: "%.2f", vm.brightness)).monospacedDigit()
            }
            Toggle("High-frequency override (>= 3 Hz)", isOn: Binding(get: { !vm.safetyCapEnabled }, set: { vm.safetyCapEnabled = !$0 }))
                .tint(.red)

            HStack {
                Button(vm.isRunning ? "Stop" : "Start") {
                    vm.isRunning ? vm.stop() : vm.start()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            logView
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear { print("[TorchPatterns] ContentView appeared") }
        .onChange(of: scene) { newPhase in
            if newPhase != .active { vm.stop() }
        }
    }

    var header: some View {
        HStack {
            Text("Torch Patterns").font(.headline)
            Spacer()
            Text(vm.isRunning ? "ON" : "OFF").foregroundStyle(vm.isRunning ? .green : .secondary)
        }
    }

    var patternPicker: some View {
        Picker("Pattern", selection: $vm.kind) {
            ForEach(PatternKind.allCases) { k in
                Text(k.rawValue.capitalized).tag(k)
            }
        }
        .pickerStyle(.segmented)
    }

    var freqDutyControls: some View {
        Group {
            if vm.kind == .strobe {
                VStack(spacing: 8) {
                    HStack {
                        Text("Frequency")
                        Slider(value: $vm.freqHz, in: 0.5...15, step: 0.1)
                        Text(String(format: "%.1f Hz", vm.safetyCapEnabled ? min(vm.freqHz, 3.0) : vm.freqHz)).monospacedDigit()
                    }
                    HStack {
                        Text("Duty")
                        Slider(value: $vm.duty, in: 0.05...0.95, step: 0.01)
                        Text("\(Int(vm.duty*100))%").monospacedDigit()
                    }
                }
            }
        }
    }

    var logView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(vm.log.enumerated()), id: \.offset) { _, line in
                    Text(line).font(.caption).foregroundStyle(.secondary)
                }
            }
        }.frame(maxHeight: 120)
    }
}
