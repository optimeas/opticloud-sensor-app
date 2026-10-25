/// Platform-neutral logic of optiCLOUD Sensor: payloads, rounding, sending on change,
/// aggregation, the offline queue, and the protocol of sign-in and messages.
///
/// The behavior is defined in `docs/spec/`. This package holds no user interface
/// and no platform sensor code, so its tests run with `swift test`.
public enum SensorCore {
    /// The device type of devices used by the app (see `docs/spec/sign-in.md`).
    public static let deviceType = "optiCLOUD Sensor App"
}
