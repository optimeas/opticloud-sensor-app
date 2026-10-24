# Sensors

**Status: draft.** Keys, units, and the list are agreed but not yet implemented.

The app offers every sensor the phone has. This document defines how sensors are found, selected, and sampled, and which keys and units their values have. How the values are sent is in [messages.md](messages.md).

## Principles

- **Discovery at run time.** Phones differ. At start the app finds out which sensors exist and offers only those. A sensor that needs a permission is offered, and the permission is asked for when the user selects it.
- **Groups and items.** Sensors are organized in groups, and each group consists of items. The user selects whole groups and can deselect single items within a group. See [Selection](#selection).
- **Same meaning on both platforms.** A key has the same unit, the same sign, and the same axes on iOS and Android. Each app converts what its platform delivers.
- **Not every value on every platform.** Some items exist on one platform only. The catalog says so; discovery at run time leaves them out on the other platform.
- **No invented values.** If a value is not available at the moment, its key is left out of the sample. The app does not send a placeholder.
- **Units.** Values use SI units and the common units derived from them. The unit is not part of the key.

## Axes

Values with three axes refer to the phone held upright in portrait orientation with the screen facing the user:

- x points to the right,
- y points up,
- z points out of the screen toward the user.

A phone that lies flat on a table with the screen up reports an acceleration of about +9.81 m/s² on z.

## Sampling

There are three kinds of values.

**Sampled values** exist at any moment, such as acceleration or battery level. While transmission is on, the app takes one sample of all selected sampled values at every tick of the send rate. All values of one tick share one time stamp and form one sample.

**Aggregated values** change faster than any send rate, such as acceleration. A single value at a tick would miss shocks and vibration between two ticks. While transmission is on, the app therefore measures them continuously at 50 Hz and, at every tick, sends the mean, the minimum, and the maximum of the measurements since the previous tick. The mean has the plain key, for example `accelX`; minimum and maximum add `Min` and `Max`, for example `accelXMin` and `accelXMax`. They belong to the sample of that tick. If the platform delivers fewer measurements than 50 Hz, the app uses those it has; if there was none, the keys are left out.

**Event values** appear when something is measured or changes, such as a heart rate reading from a watch. The app sends each one when it arrives, with the time stamp of the measurement. The send rate does not apply.

## Selection

The catalog below defines groups and items. An item is the smallest unit that can be selected. Most items have a single key; values that only make sense together form one item, such as the three axes of acceleration (`accel`) or latitude and longitude (`position`). Selecting an aggregated item includes its `Min` and `Max` keys.

- On the phone, the user switches whole groups on and off. A group can be opened to deselect single items in it.
- The selection is written as a list of group keys and item keys, separated by commas, for example `location,accelMagnitude`. A group key stands for all items of the group. The selected items are the union of all entries.
- Item keys and group keys never coincide, so an entry is always clear.
- An item the phone does not offer is not sent, also when its group is selected.
- When the app reports the selection, it writes a group key for each group whose offered items are all selected, and item keys for the rest. The order of the entries carries no meaning.
- A selection that contains an unknown key is invalid as a whole.

## Catalog

The column "Kind" says whether a value is sampled (S), aggregated (A), or an event (E).

### `motion`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `accel` | `accelX`, `accelY`, `accelZ` | m/s² | A | Acceleration including gravity |
| `accelMagnitude` | `accelMagnitude` | m/s² | A | Magnitude of the acceleration vector, independent of how the phone is held. About 9.81 at rest. |
| `gyro` | `gyroX`, `gyroY`, `gyroZ` | rad/s | A | Rotation rate |
| `mag` | `magX`, `magY`, `magZ` | µT | S | Magnetic field |
| `orientation` | `roll`, `pitch`, `yaw` | degree | S | Orientation of the phone |

Aggregation applies only to the `motion` group, and within it only to acceleration and rotation rate. The magnetic field changes slowly, and a mean of angles such as `yaw` is not meaningful where the angle wraps around, so these stay sampled values. All other groups stay at one value per tick.

### `environment`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `pressure` | `pressure` | hPa | S | Air pressure |
| `light` | `light` | lx | S | Ambient light |

### `location`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `position` | `latitude`, `longitude` | degree | S | Position, WGS 84 |
| `altitude` | `altitude` | m | S | Height above sea level |
| `speed` | `speed` | m/s | S | Speed over ground |
| `course` | `course` | degree | S | Direction of travel, clockwise from north |
| `locationAccuracy` | `locationAccuracy` | m | S | Horizontal accuracy of the position |

### `activity`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `steps` | `steps` | count | S | Steps since midnight, local time |
| `activityType` | `activityType` | string | E | `stationary`, `walking`, `running`, `cycling`, `automotive`, or `unknown` |

### `device`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `batteryLevel` | `batteryLevel` | 0 to 1 | S | Charge of the battery |
| `charging` | `charging` | boolean | S | The phone is being charged |
| `network` | `network` | string | S | `wifi`, `cellular`, `other`, or `none` |
| `thermalState` | `thermalState` | string | S | `nominal`, `fair`, `serious`, or `critical` |
| `powerSaving` | `powerSaving` | boolean | S | The power saving mode of the system is on |
| `cellularSignal` | `cellularSignal` | dBm | S | Signal strength of the mobile network. Android only: iOS offers no public interface for it. |

### `sound`

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `soundLevel` | `soundLevel` | dB | S | Loudness measured by the microphone. No audio is recorded or sent. |

The app measures the sound level only while it is in the foreground. In the background the key is left out, also when the item is selected. Both platforms restrict the microphone in the background and show the user that it is in use.

### `health`

**Planned for stage 4.** This group is not part of the earlier stages. It comes in a release of its own after the app is in productive use (see the [project brief](../project-brief.md#stages)). Until then the apps do not offer it.

Values measured on the body. A phone does not measure them itself. They come from a watch or another device through the health store of the platform.

| Item | Key | Unit | Kind | Meaning |
| --- | --- | --- | --- | --- |
| `heartRate` | `heartRate` | 1/min | E | Heart rate |
| `bodyTemperature` | `bodyTemperature` | °C | E | Body temperature |
| `oxygenSaturation` | `oxygenSaturation` | % | E | Oxygen saturation of the blood |
| `respiratoryRate` | `respiratoryRate` | 1/min | E | Breaths per minute |

Health values are personal data of a special kind. The group is never selected by default. Selecting it needs the user's explicit consent on the phone, with a text that says the values are sent to optiCLOUD. Selecting it through a shared attribute does not replace this consent: without it the app does not send health values.

## Open points

1. Which permission texts and which consent text does the app show? These are needed before a store release.
2. Which values are really available on which platform has to be established when the apps are built. The catalog will then get a column for it.
