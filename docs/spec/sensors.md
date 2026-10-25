# Sensors

**Status: draft.** Keys, units, and the list are agreed. The iOS app implements the groups `device`, `location`, `motion`, `environment`, `activity`, and `sound`; on 2026-10-25 it sent all of them to an optiCLOUD server, also with the app in the background. The group `health` is planned for stage 4.

The app offers every sensor the phone has. This document defines how sensors are found, selected, and sampled, and which keys and units their values have. How the values are sent is in [messages.md](messages.md).

## Principles

- **Discovery at run time.** Phones differ. At start the app finds out which sensors exist and offers only those. A sensor that needs a permission is offered, and the permission is asked for when the user selects it.
- **Groups and items.** Sensors are organized in groups, and each group consists of items. The user selects whole groups and can deselect single items within a group. See [Selection](#selection).
- **Same meaning on both platforms.** A key has the same unit, the same sign, and the same axes on iOS and Android. Each app converts what its platform delivers.
- **Not every value on every platform.** Some items exist on one platform only. The catalog says so; discovery at run time leaves them out on the other platform.
- **No invented values.** If a value is not available at the moment, its key is left out of the sample. The app does not send a placeholder.
- **Units.** Values use SI units and the common units derived from them, and units that are usual in practice, such as km/h for speed. The unit is not part of the key. Each app converts what its platform delivers into the unit of the catalog.

## Axes

Values with three axes refer to the phone held upright in portrait orientation with the screen facing the user:

- x points to the right,
- y points up,
- z points out of the screen toward the user.

A phone that lies flat on a table with the screen up reports an acceleration of about +9.81 m/s² on z.

## Sampling

There are three kinds of values.

**Sampled values** exist at any moment, such as battery level or air pressure. While transmission is on, the app takes one sample of all selected sampled values at every tick of the send rate. Which of them it sends depends on the send mode (see [Sending on change](#sending-on-change)). All values of one tick share one time stamp and form one sample.

**Aggregated values** change faster than any send rate, such as acceleration. A single value at a tick would miss shocks and vibration between two ticks. While transmission is on, the app therefore measures them continuously at 50 Hz and, at every tick, sends the mean, the minimum, and the maximum of the measurements since the previous tick. The mean has the plain key, for example `accelX`; minimum and maximum add `Min` and `Max`, for example `accelXMin` and `accelXMax`. They belong to the sample of that tick. If the platform delivers fewer measurements than 50 Hz, the app uses those it has; if there was none, the keys are left out. `accelMagnitude` is computed for each measurement from its three axes; mean, minimum, and maximum are then taken over these magnitudes. Mean, minimum, and maximum are computed from the measured values and rounded only afterwards.

**Event values** appear when something is measured or changes, such as a heart rate reading from a watch. The app sends each one when it arrives, with the time stamp of the measurement. The send rate does not apply.

## Sending on change

The send mode is a setting (see [configuration.md](configuration.md)). There are two modes.

**On change** is the default. At every tick the app sends only the sampled and aggregated values that have changed since they were last sent:

1. The app rounds every number to the resolution of its key in the catalog: it divides the value by the resolution, rounds the quotient to a whole number, half away from zero, and multiplies by the resolution. For a resolution below 1 it multiplies by the inverse instead, a whole power of ten such as 100, rounds, and divides by it: that power of ten is exact in floating point and the resolution is not, so both apps get the same result for a value at a half. It writes the result in plain notation with no more decimals than the resolution has: without an exponent, a whole number without a decimal point (`63`, not `63.0`), and a negative zero as `0`.
2. A value has changed when its rounded value differs from the rounded value last sent for the same key. Booleans and strings have changed when they differ.
3. Each key is compared on its own, also the `Min` and `Max` keys of aggregated values and the single axes of an item.
4. A value that is not available at a tick is left out (see [Principles](#principles)). It does not count as a change, and the last sent value stays the reference.
5. If no value has changed, the app sends no sample at that tick.

Every 60 seconds the app sends a **full sample** with all selected values, changed or not. This gives optiCLOUD a regular reference point. The first full sample is taken at the first tick after transmission is switched on; then at the first tick that is at least 60 seconds after the previous full sample. A change of the selection also leads to a full sample at the next tick.

**Every tick** sends all selected values at every tick, rounded as above.

- "Last sent" means last handed to the offline queue, not last acknowledged by the server. Values buffered while offline follow the same rules.
- Event values are sent when they arrive, in both modes. They are rounded but not compared.
- The 60 seconds of the full sample are fixed. They are not a setting.

## Selection

The catalog below defines groups and items. An item is the smallest unit that can be selected. Most items have a single key; values that only make sense together form one item, such as the three axes of acceleration (`accel`) or latitude and longitude (`position`). Selecting an aggregated item includes its `Min` and `Max` keys.

- On the phone, the user switches whole groups on and off. A group can be opened to deselect single items in it.
- The selection is written as a list of group keys and item keys, separated by commas, for example `location,accelMagnitude`. A group key stands for all items of the group. The selected items are the union of all entries.
- Spaces around an entry are ignored, and so are empty entries. An empty selection selects nothing.
- Item keys and group keys never coincide, so an entry is always clear.
- An item the phone does not offer is not sent, also when its group is selected.
- When the app reports the selection, it covers only selected items that the phone offers. It writes a group key for each group that has at least one offered item and whose offered items are all selected, and item keys for the rest. The order of the entries carries no meaning.
- A selection that contains an unknown key is invalid as a whole.

## Catalog

The column "Kind" says whether a value is sampled (S), aggregated (A), or an event (E). The column "Resolution" is the step to which the app rounds the value (see [Sending on change](#sending-on-change)); "–" means the value is not a number and is sent as it is.

### `motion`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `accel` | `accelX`, `accelY`, `accelZ` | m/s² | 0.01 | A | Acceleration including gravity |
| `accelMagnitude` | `accelMagnitude` | m/s² | 0.01 | A | Magnitude of the acceleration vector, independent of how the phone is held. About 9.81 at rest. |
| `gyro` | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0.001 | A | Rotation rate |
| `mag` | `magX`, `magY`, `magZ` | µT | 0.1 | S | Magnetic field |
| `orientation` | `roll`, `pitch`, `yaw` | degree | 0.1 | S | Orientation of the phone, see [Orientation](#orientation) |

The rotation rate is positive for a counterclockwise rotation about the axis, seen from the tip of the axis (right-hand rule). The magnetic field is the calibrated field on the axes of the phone; while the system has not calibrated it, `mag` is left out.

Aggregation applies only to the `motion` group, and within it only to acceleration and rotation rate. The magnetic field changes slowly, and a mean of angles such as `yaw` is not meaningful where the angle wraps around, so these stay sampled values. All other groups stay at one value per tick.

#### Orientation

The orientation is computed from the part of the acceleration that is due to gravity, **g**, on the axes of the phone (pointing up, about (0, 0, +9.81) when the phone lies flat with the screen up), and from the calibrated magnetic field **m**:

- `pitch` = asin(g<sub>y</sub> / |**g**|), from −90 to 90. Positive when the top edge is raised; 90 when the phone stands upright in portrait.
- `roll` = atan2(−g<sub>x</sub>, g<sub>z</sub>), from −180 to 180. Positive when the right edge is lowered.
- `yaw`: with **e** = **m** × **g** (east) and **n** = **g** × **e** (north), `yaw` = atan2(e<sub>y</sub> / |**e**|, n<sub>y</sub> / |**n**|), brought into 0 to less than 360. It is the direction of the top edge, clockwise from magnetic north. Without a calibrated magnetic field `yaw` is left out. Near `pitch` ±90 it is not stable.

All three are in degrees. The test vectors are in [`orientation.json`](vectors/orientation.json).

### `environment`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `pressure` | `pressure` | hPa | 0.1 | S | Air pressure |
| `light` | `light` | lx | 1 | S | Ambient light |

### `location`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `position` | `latitude`, `longitude` | degree | 0.00001 | S | Position, WGS 84 |
| `altitude` | `altitude` | m | 0.1 | S | Height above sea level |
| `speed` | `speed` | km/h | 0.1 | S | Speed over ground |
| `course` | `course` | degree | 1 | S | Direction of travel, clockwise from north |
| `locationAccuracy` | `locationAccuracy` | m | 1 | S | Horizontal accuracy of the position |

### `activity`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `steps` | `steps` | count | 1 | S | Steps since midnight, local time |
| `activityType` | `activityType` | string | – | E | `stationary`, `walking`, `running`, `cycling`, `automotive`, or `unknown` |

`steps` counts again from 0 at midnight, local time. `activityType` is sent when the kind of activity changes, with the time at which the system detected the new activity. When the system reports more than one kind at once, the first of `automotive`, `cycling`, `running`, `walking`, `stationary` counts; a car that stands still is still `automotive`.

### `device`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `batteryLevel` | `batteryLevel` | 0 to 1 | 0.01 | S | Charge of the battery |
| `charging` | `charging` | boolean | – | S | The phone is being charged |
| `network` | `network` | string | – | S | `wifi`, `cellular`, `other`, or `none` |
| `thermalState` | `thermalState` | string | – | S | `nominal`, `fair`, `serious`, or `critical` |
| `powerSaving` | `powerSaving` | boolean | – | S | The power saving mode of the system is on |
| `cellularSignal` | `cellularSignal` | dBm | 1 | S | Signal strength of the mobile network. Android only: iOS offers no public interface for it. |
| `dataVolume` | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | byte | 1000 | S | Data volume of the app over the mobile network and over Wi-Fi, today and in the current month. See [connection.md](connection.md#data-volume). |

### `sound`

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `soundLevel` | `soundLevel` | dB | 1 | S | Loudness measured by the microphone. No audio is recorded or sent. |

The app measures the sound level only while it is in the foreground. In the background the key is left out, also when the item is selected. Both platforms restrict the microphone in the background and show the user that it is in use.

#### Sound level

A phone microphone is not calibrated. The app therefore sends an estimate: the level over all audio samples since the previous tick, relative to full scale, plus 100 dB:

`soundLevel` = 10 · log10(mean of the squared samples) + 100, with the samples scaled so that full scale is 1. A value below 0 is sent as 0.

A quiet room gives about 30 to 50, a conversation about 60 to 70. Values of different phones can differ by several decibels. The app turns off the audio processing of the platform for the measurement, as far as the platform allows. The test vectors are in [`sound-level.json`](vectors/sound-level.json).

### `health`

**Planned for stage 4.** This group is not part of the earlier stages. It comes in a release of its own after the app is in productive use (see the [project brief](../project-brief.md#stages)). Until then the apps do not offer it.

Values measured on the body. A phone does not measure them itself. They come from a watch or another device through the health store of the platform.

| Item | Key | Unit | Resolution | Kind | Meaning |
| --- | --- | --- | --- | --- | --- |
| `heartRate` | `heartRate` | 1/min | 1 | E | Heart rate |
| `bodyTemperature` | `bodyTemperature` | °C | 0.1 | E | Body temperature |
| `oxygenSaturation` | `oxygenSaturation` | % | 1 | E | Oxygen saturation of the blood |
| `respiratoryRate` | `respiratoryRate` | 1/min | 1 | E | Breaths per minute |

Health values are personal data of a special kind. The group is never selected by default. Selecting it needs the user's explicit consent on the phone, with a text that says the values are sent to optiCLOUD. Selecting it through a shared attribute does not replace this consent: without it the app does not send health values.

## Open points

1. Which permission texts and which consent text does the app show? These are needed before a store release.
2. Which values are really available on which platform has to be established when the apps are built. The catalog will then get a column for it. Found so far:
   - iOS offers no `cellularSignal`: the system has no public interface for it.
   - iOS does not count `dataVolume` yet.
   - iOS offers all items of `location`. `speed` and `course` are left out while the phone does not move, because the system then reports them as invalid.
   - iOS offers no `light`: the system has no public interface for the ambient light.
   - iOS offers all items of `motion`, `activity`, and `sound`, and `pressure`, on phones that have the sensors.
