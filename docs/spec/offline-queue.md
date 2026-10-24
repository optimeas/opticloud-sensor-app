# Offline queue

**Status: draft.** This version covers telemetry. Journal entries follow with stage 2.

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

## Open points

1. Journal entries in the queue: order, retries, and what happens when the user's session has expired. Comes with stage 2.
