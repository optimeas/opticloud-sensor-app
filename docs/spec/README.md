# Specification: optiCLOUD Sensor

This directory is the master for the behavior of optiCLOUD Sensor. The iOS app and the Android app both implement it. Neither app is the reference for the other.

**Status: draft.** The specification is being worked out. The iOS app passes the shared test vectors and implements sign-in, device selection, the connection, the offline queue, commands, and transmission of the `device` group; the other sensors and the test area are not implemented yet. Protocol facts were read from the optiCLOUD source; each document says which parts were tested against an optiCLOUD test server.

## Documents

| Document | Content | Status |
| --- | --- | --- |
| [sign-in.md](sign-in.md) | Sign-in of the user, tenant, project, device selection, binding of the device to the phone | Draft |
| [connection.md](connection.md) | Endpoint, sign-on of the device, the two states "connected" and "transmitting", reconnecting | Draft |
| [messages.md](messages.md) | MQTT topics and payloads: telemetry, attributes, RPC, alarms | Draft |
| [configuration.md](configuration.md) | The settings, their defaults and allowed values, and what the app stores | Draft |
| [sensors.md](sensors.md) | How sensors are found, selected, and sampled; the catalog of keys and units | Draft |
| [offline-queue.md](offline-queue.md) | Buffering and delivery of telemetry | Draft, journal entries follow with stage 2 |
| [journal.md](journal.md) | Journal entries as notes | Draft |
| [vectors/](vectors/) | Test vectors shared by both apps | Draft |

Planned, not yet written:

- photos

## Conventions

- "Must", "must not", "should", and "may" are used in the sense of [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119).
- Time stamps are whole milliseconds since 1970-01-01T00:00:00Z.
- Payloads are JSON encoded as UTF-8 without a byte order mark.
- Each document ends with its open points. An open point is not yet part of the specification.

## Test vectors

A vector file is a JSON document with a `description` and a list of `cases`. Each case has a `name`, an input, and the expected result. Both apps load the same files and run every case in their protocol tests.

Payloads are compared as JSON values, not as text: the order of object members and white space do not matter.

Numbers are compared as numbers: `0`, `0.0`, and `-0.0` are equal. A description can say that a list is compared as a set.

| File | Content |
| --- | --- |
| [telemetry.json](vectors/telemetry.json) | Encoding of samples into a telemetry message |
| [selection.json](vectors/selection.json) | Sensor selection: valid or not, the selected items, and what the app reports |
| [rounding.json](vectors/rounding.json) | Rounding of a number to the resolution of its key |
| [on-change.json](vectors/on-change.json) | Which values are sent at each tick, in both send modes |
| [aggregation.json](vectors/aggregation.json) | Mean, minimum, and maximum of aggregated values |
| [queue-batching.json](vectors/queue-batching.json) | Division of the offline queue into telemetry messages |
| [journal-note.json](vectors/journal-note.json) | Request body of a note created from a journal entry |

## Changing the specification

Change the specification and the test vectors in the same pull request as the app that needs the change. One app leads at a time (see the [project brief](../project-brief.md#decisions)); the other app follows from the specification. A change to the behavior of one app without a change here is a defect.
