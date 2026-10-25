import Foundation

/// The orientation of the phone, computed from gravity and the magnetic field
/// (see `docs/spec/sensors.md`, Orientation).
public enum Orientation {
    /// `roll`, `pitch`, and `yaw` in degrees.
    ///
    /// - Parameters:
    ///   - gravity: The part of the acceleration that is due to gravity, on the axes of the catalog: it points up,
    ///     so a phone lying flat with the screen up gives about (0, 0, +9.81).
    ///   - magneticField: The calibrated magnetic field on the same axes, in µT. Without it `yaw` is left out.
    public static func angles(gravity: (x: Double, y: Double, z: Double),
                              magneticField: (x: Double, y: Double, z: Double)?) -> [String: TelemetryValue] {
        let g = Vector(gravity.x, gravity.y, gravity.z)
        guard g.length > 0 else { return [:] }
        var values: [String: TelemetryValue] = [
            "pitch": .number(degrees(asin(max(-1, min(1, g.y / g.length))))),
            "roll": .number(degrees(atan2(-g.x, g.z))),
        ]
        if let magneticField {
            let east = Vector(magneticField.x, magneticField.y, magneticField.z).cross(g)
            let north = g.cross(east)
            if east.length > 0, north.length > 0 {
                var yaw = degrees(atan2(east.y / east.length, north.y / north.length))
                if yaw < 0 { yaw += 360 }
                values["yaw"] = .number(yaw)
            }
        }
        return values
    }

    private static func degrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }

    private struct Vector {
        let x, y, z: Double
        init(_ x: Double, _ y: Double, _ z: Double) { (self.x, self.y, self.z) = (x, y, z) }
        var length: Double { (x * x + y * y + z * z).squareRoot() }
        func cross(_ o: Vector) -> Vector {
            Vector(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x)
        }
    }
}
