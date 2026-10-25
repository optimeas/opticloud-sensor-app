import Foundation

/// The sound level between two ticks, estimated from the microphone signal
/// (see `docs/spec/sensors.md`, Sound level).
public struct SoundLevel: Hashable, Sendable {
    /// Added to the level relative to full scale to estimate the sound pressure level.
    public static let offset = 100.0

    private var sumOfSquares = 0.0
    private var count = 0

    public init() {}

    /// Adds audio samples, scaled so that full scale is 1.
    public mutating func add(_ samples: some Sequence<Float>) {
        for sample in samples where sample.isFinite {
            sumOfSquares += Double(sample) * Double(sample)
            count += 1
        }
    }

    /// Adds the samples of another period, for example one buffer measured on its own.
    public mutating func add(_ other: SoundLevel) {
        sumOfSquares += other.sumOfSquares
        count += other.count
    }

    /// The estimated level in dB, never below 0. Nil if there were no samples.
    public var level: Double? {
        guard count > 0 else { return nil }
        let meanSquare = sumOfSquares / Double(count)
        guard meanSquare > 0 else { return 0 }
        return max(0, 10 * log10(meanSquare) + Self.offset)
    }
}
