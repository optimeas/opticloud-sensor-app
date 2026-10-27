# Specification: optiCLOUD Sensor

This directory is the master for the behavior of optiCLOUD Sensor. The iOS app and the Android app both implement it. Neither app is the reference for the other.

**Status: draft.** The specification is being worked out. Both apps pass the shared test vectors. The iOS app implements sign-in, device selection, the connection, the offline queue, commands, the sensor selection, the data volume, transmission of all sensor groups of stage 1, also in the background, the test area without alarms, and the favorites. The Android app implements sign-in and device selection. Protocol facts were read from the optiCLOUD source; each document says which parts were tested against an optiCLOUD test server.

## Documents

| Document | Content | Status |
| --- | --- | --- |
| [sign-in.md](sign-in.md) | Sign-in of the user, tenant, project, device selection, binding of the device to the phone | Draft |
| [connection.md](connection.md) | Endpoint, sign-on of the device, the two states "connected" and "transmitting", reconnecting | Draft |
| [messages.md](messages.md) | MQTT topics and payloads: telemetry, attributes, RPC, alarms | Draft |
| [configuration.md](configuration.md) | The settings, their defaults and allowed values, and what the app stores | Draft |
| [sensors.md](sensors.md) | How sensors are found, selected, and sampled; the catalog of keys and units | Draft |
| [favorites.md](favorites.md) | Pages of the web application in the tab Favorites | Draft |
| [offline-queue.md](offline-queue.md) | Buffering and delivery of telemetry | Draft, journal entries follow with stage 2 |
| [journal.md](journal.md) | Journal entries as notes | Draft |
| [vectors/](vectors/) | Test vectors shared by both apps | Draft |
| [tools/](tools/) | Scripts that check data exported from optiCLOUD | Draft |

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
| [orientation.json](vectors/orientation.json) | Roll, pitch, and yaw from gravity and the magnetic field |
| [sound-level.json](vectors/sound-level.json) | Estimated sound level from the microphone samples |
| [test-signal.json](vectors/test-signal.json) | The sine of the test group from the time stamp |
| [favorite-url.json](vectors/favorite-url.json) | Address of a favorite page |
| [mqtt-packet-size.json](vectors/mqtt-packet-size.json) | Size of the MQTT packets counted for the data volume |
| [data-volume.json](vectors/data-volume.json) | Data volume per day and per period |
| [queue-batching.json](vectors/queue-batching.json) | Division of the offline queue into telemetry messages |
| [journal-note.json](vectors/journal-note.json) | Request body of a note created from a journal entry |

## Changing the specification

Change the specification and the test vectors in the same pull request as the app that needs the change. One app leads at a time (see the [project brief](../project-brief.md#decisions)); the other app follows from the specification. A change to the behavior of one app without a change here is a defect.
