# Specification: optiCLOUD Sensor

This directory is the master for the behavior of optiCLOUD Sensor. The iOS app and the Android app both implement it. Neither app is the reference for the other.

**Status: draft.** The specification is being worked out. No app implements it yet. Protocol facts were read from the optiCLOUD source and are not yet tested against a server.

## Documents

| Document | Content | Status |
| --- | --- | --- |
| [connection.md](connection.md) | Endpoint, sign-on of the device, the two states "connected" and "transmitting", reconnecting | Draft |
| [messages.md](messages.md) | MQTT topics and payloads: telemetry, attributes, RPC, alarms | Draft |
| [sensors.md](sensors.md) | How sensors are found, selected, and sampled; the catalog of keys and units | Draft, catalog is a first proposal |
| [vectors/](vectors/) | Test vectors shared by both apps | First proposal |

Planned, not yet written:

- configuration: the settings and their allowed ranges
- offline queue: buffering and delivery order
- provisioning: sign-in and device registration through the REST interface
- journal entries and photos

## Conventions

- "Must", "must not", "should", and "may" are used in the sense of [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).
- Time stamps are whole milliseconds since 1970-01-01T00:00:00Z.
- Payloads are JSON encoded as UTF-8 without a byte order mark.
- Each document ends with its open points. An open point is not yet part of the specification.

## Test vectors

A vector file is a JSON document with a `description` and a list of `cases`. Each case has a `name`, an input, and the expected result. Both apps load the same files and run every case in their protocol tests.

Payloads are compared as JSON values, not as text: the order of object members and white space do not matter.

## Changing the specification

Change the specification and the test vectors in the same pull request as the app that needs the change. One app leads at a time (see the [project brief](../project-brief.md#decisions)); the other app follows from the specification. A change to the behavior of one app without a change here is a defect.
