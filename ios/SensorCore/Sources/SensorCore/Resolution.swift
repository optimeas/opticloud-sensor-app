import Foundation

/// The step to which a number is rounded before it is sent: a power of ten
/// (see `docs/spec/sensors.md`, Sending on change).
public struct Resolution: Hashable, Sendable {
    /// The step is 10 to the power of this exponent: -2 for 0.01, 3 for 1000.
    public let exponent: Int

    public init(exponent: Int) {
        self.exponent = exponent
    }

    /// Creates the resolution for a step such as 0.01 or 1000. Returns nil if the step is not a power of ten.
    public init?(step: Double) {
        guard step > 0 else { return nil }
        let exponent = Int(log10(step).rounded())
        guard abs(pow(10, Double(exponent)) - step) <= step * 1e-9 else { return nil }
        self.exponent = exponent
    }

    public var step: Double { pow(10, Double(exponent)) }

    /// Divides by the step, rounds half away from zero, and multiplies by the step.
    ///
    /// For steps below 1 the result is computed as a whole number divided by a power of ten,
    /// so that it has no more decimals than the step and is written as such in JSON.
    public func round(_ value: Double) -> Double {
        let result: Double
        if exponent < 0 {
            let scale = pow(10, Double(-exponent))
            result = (value * scale).rounded(.toNearestOrAwayFromZero) / scale
        } else {
            result = (value / step).rounded(.toNearestOrAwayFromZero) * step
        }
        return result + 0 // no negative zero
    }
}
