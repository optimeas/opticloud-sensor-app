import AVFoundation
import Foundation
import os
import SensorCore

/// The value of the group `sound` (see `docs/spec/sensors.md`, Sound level).
///
/// Only the level is computed; no audio is kept. The microphone runs only while the app is in the foreground.
final class SoundSampler {
    /// The items of the group this phone offers.
    static let offered: Set<String> = ["soundLevel"]

    private let engine = AVAudioEngine()
    private let level = OSAllocatedUnfairLock(initialState: SoundLevel())
    private var running = false

    /// Starts the microphone. Asks for the permission first if it has not been asked for.
    func start() async {
        guard !running else { return }
        guard await AVAudioApplication.requestRecordPermission() else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            // The measurement mode turns off the processing that would change the level.
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .defaultToSpeaker])
            try session.setActive(true)
            let input = engine.inputNode
            input.installTap(onBus: 0, bufferSize: 4096, format: input.outputFormat(forBus: 0), block: Self.tap(into: level))
            try engine.start()
            running = true
        } catch {
            engine.inputNode.removeTap(onBus: 0)
        }
    }

    func stop() {
        guard running else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        running = false
        level.withLock { $0 = SoundLevel() }
    }

    /// The tap runs on an audio thread, not on the main actor.
    private nonisolated static func tap(into level: OSAllocatedUnfairLock<SoundLevel>) -> AVAudioNodeTapBlock {
        { buffer, _ in
            guard let channel = buffer.floatChannelData?[0] else { return }
            var chunk = SoundLevel()
            chunk.add(UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength)))
            level.withLock { [chunk] in $0.add(chunk) }
        }
    }

    /// The level since the previous call. Starts the next period.
    func measure() -> [String: TelemetryValue] {
        let current = level.withLock { value in
            defer { value = SoundLevel() }
            return value.level
        }
        return current.map { ["soundLevel": .number($0)] } ?? [:]
    }
}
