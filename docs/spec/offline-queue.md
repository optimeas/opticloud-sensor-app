# Offline queue

**Status: draft.** The queue of telemetry was tested on an iPhone against optiCLOUD. The queue of journal entries is not yet tested against an optiCLOUD server.

Telemetry must not be lost when the phone has no connection. Every sample goes through a persistent queue, also while the app is connected. The queue keeps the original time stamps, so optiCLOUD receives the time series as it was measured (see [messages.md](messages.md#telemetry)).

## What goes into the queue

- Telemetry samples, from the moment they are taken.
- Not client attributes: the app publishes them after every connect anyway (see [messages.md](messages.md#client-attributes)).
- Not answers to commands and not alarms from the test area: both exist only while the app is connected.

## Storing

- The queue is stored on the phone and survives a restart of the app and of the phone.
- A sample counts as sent in the sense of [sending on change](sensors.md#sending-on-change) as soon as it is stored in the queue.
- The queue holds at most 50 MB, counted as the size of the samples in JSON.
- When the queue is full, the app discards the oldest samples until the new one fits. It counts the discarded samples and keeps the time range they covered.

## Delivering

The app delivers the queue whenever it is connected, whether transmission is on or off.

1. It takes samples from the front of the queue, oldest first, and puts them into one telemetry message until the next sample would make the payload larger than 32 KiB (32768 bytes). The size is the length in UTF-8 of the payload written as JSON without white space. Within the message the samples are ordered by rising `ts` (see [messages.md](messages.md#telemetry)). A sample that is larger than 32 KiB on its own goes into a message of its own.
2. It publishes the message with QoS 1.
3. When the server acknowledges the message, the app removes its samples from the queue and continues with the next message.

- At most one telemetry message is unacknowledged at a time. This keeps the order and makes removal simple.
- New samples are appended at the end of the queue, also while older ones are still being delivered. While the queue is short, a new sample is therefore sent at once.
- If the connection is lost before the acknowledgment, the samples stay in the queue and are sent again after the next connect. optiCLOUD may then store them twice (see [messages.md](messages.md#general-rules)).
- If the same message is followed by a closed connection three times in a row without an acknowledgment, the app assumes that the server cannot read it. It discards the samples of that message and counts them as discarded.

## Changing the device

The samples in the queue belong to the device they were measured for. When the user picks another device while the queue is not empty, the app says how many samples have not been delivered yet. If the user goes on, the app discards them.

## Status

The app shows in the test area:

- the number of samples in the queue and its size,
- the time stamp of the oldest sample,
- the number of discarded samples and the time range they covered, since the user last reset this count.

## Journal entries

Journal entries (see [journal.md](journal.md)) have a queue of their own. They go to optiCLOUD through the REST interface with the user's session, not through MQTT, and do not depend on the connection of the device or on transmission.

### Storing

- The queue is stored on the phone and survives a restart of the app and of the phone. It is not part of the 50 MB of telemetry.
- Each entry keeps what it needs for its note: the entry itself (see [journal.md](journal.md#entry)), the device it was saved for, and the user who saved it (`userId` from the access token).
- The app never discards an entry by itself. Only the user deletes one.
- The queue holds at most 500 entries. When it is full, the app does not save a new entry and says so.

### Delivering

The app delivers the queue right after an entry was saved, when the app comes to the foreground, after a sign-in, and every 60 seconds while the app runs and the queue holds an entry that waits.

1. It takes the oldest entry that waits.
2. It creates the note with `POST /api/notes` (see [journal.md](journal.md#note)). `tenantId`, `projectId`, and `authorityDataId` come from the session at the moment of delivery; the device is the one the entry was saved for.
3. What happens next depends on the answer:

| Answer | The entry | The app |
| --- | --- | --- |
| Success (2xx) | is removed | continues with the next entry |
| No answer, a network error, 429, or 5xx | waits | stops and tries again later |
| No session, or the session cannot be renewed | waits | stops and asks the user to sign in |
| Any other error | is set aside as not delivered, with the message of the server | continues with the next entry |

- An entry is delivered only through a session of the user who saved it. While another user is signed in, the entries of the first user wait, and the app says so.
- At most one request is under way at a time, so that the notes arrive in the order they were saved.
- If the answer is lost after the server stored the note, the entry is sent again and optiCLOUD has the note twice. `additionalInfo.savedAt` shows that both are the same entry.
- An entry set aside stays until the user sends it again or deletes it.

### Status

The app shows how many entries wait and how many were set aside. The test area lists each of them with its title, the moment of saving, and, for an entry set aside, the message of the server. There the user sends an entry again or deletes it.

### Changing the device, signing out

- Entries keep their device. Picking another device does not change or discard them.
- Signing out keeps the queue. The entries are delivered after the same user signs in again.

## Open points

None.
