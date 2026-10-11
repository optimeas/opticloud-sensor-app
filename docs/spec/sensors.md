# Sensors

**Status: draft.** The catalog is a first proposal. Keys, units, and the list itself are not final.

The app offers every sensor the phone has. This document defines how sensors are found, selected, and sampled, and which keys and units their values have. How the values are sent is in [messages.md](messages.md).

## Principles

- **Discovery at run time.** Phones differ. At start the app finds out which sensors exist and offers only those. A sensor that needs a permission is offered, and the permission is asked for when the user selects it.
- **Groups.** Sensors are organized in groups. The user selects groups, not single values. A group has a key, for example `motion`.
- **Same meaning on both platforms.** A key has the same unit, the same sign, and the same axes on iOS and Android. Each app converts what its platform delivers.
- **No invented values.** If a value is not available at the moment, its key is left out of the sample. The app does not send a placeholder.
- **Units.** Values use SI units and the common units derived from them. The unit is not part of the key.

## Axes

Values with three axes refer to the phone held upright in portrait orientation with the screen facing the user:

- x points to the right,
- y points up,
- z points out of the screen toward the user.

A phone that lies flat on a table with the screen up reports an acceleration of about +9.81 m/s² on z.

## Sampling

There are two kinds of values.

**Sampled values** exist at any moment, such as acceleration or battery level. While transmission is on, the app takes one sample of all selected sampled values at every tick of the send rate. All values of one tick share one time stamp and form one sample.

**Event values** appear when something is measured or changes, such as a heart rate reading from a watch. The app sends each one when it arrives, with the time stamp of the measurement. The send rate does not apply.

## Catalog

The column "Kind" says whether a value is sampled (S) or an event (E).

### `motion`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `accelX`, `accelY`, `accelZ` | m/s² | S | Acceleration including gravity |
| `gyroX`, `gyroY`, `gyroZ` | rad/s | S | Rotation rate |
| `magX`, `magY`, `magZ` | µT | S | Magnetic field |
| `roll`, `pitch`, `yaw` | degree | S | Orientation of the phone |

### `environment`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `pressure` | hPa | S | Air pressure |
| `light` | lx | S | Ambient light |
| `ambientTemperature` | °C | S | Air temperature |
| `humidity` | % | S | Relative humidity |
| `proximity` | boolean | S | Something is close to the screen |

### `location`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `latitude`, `longitude` | degree | S | Position, WGS 84 |
| `altitude` | m | S | Height above sea level |
| `speed` | m/s | S | Speed over ground |
| `course` | degree | S | Direction of travel, clockwise from north |
| `locationAccuracy` | m | S | Horizontal accuracy of the position |

### `activity`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `steps` | count | S | Steps since midnight, local time |
| `activityType` | string | E | `stationary`, `walking`, `running`, `cycling`, `automotive`, or `unknown` |

### `device`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `batteryLevel` | 0 to 1 | S | Charge of the battery |
| `charging` | boolean | S | The phone is being charged |
| `network` | string | S | `wifi`, `cellular`, `other`, or `none` |
| `thermalState` | string | S | `nominal`, `fair`, `serious`, or `critical` |

### `sound`

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `soundLevel` | dB | S | Loudness measured by the microphone. No audio is recorded or sent. |

### `health`

Values measured on the body. A phone does not measure them itself. They come from a watch or another device through the health store of the platform.

| Key | Unit | Kind | Meaning |
| --- | --- | --- | --- |
| `heartRate` | 1/min | E | Heart rate |
| `bodyTemperature` | °C | E | Body temperature |
| `oxygenSaturation` | % | E | Oxygen saturation of the blood |
| `respiratoryRate` | 1/min | E | Breaths per minute |

Health values are personal data of a special kind. The group is never selected by default. Selecting it needs the user's explicit consent on the phone, with a text that says the values are sent to optiCLOUD. Selecting it through a shared attribute does not replace this consent: without it the app does not send health values.

## Open points

1. Which sensors that this catalog lists are not wanted, and which are missing?
2. Is one value at each tick enough for fast sensors such as acceleration, or does the app have to send minimum, maximum, and mean of the interval? This matters for vibration and shock.
3. In which stage does the `health` group come? It needs access to the health store on both platforms, a watch for most values, and additional statements for both app stores. It may be better as its own stage after the foundation.
4. Does the user select whole groups, as written here, or single values?
5. Which permission texts and which consent text does the app show? These are needed before a store release.
6. Which values are really available on which platform has to be established when the apps are built. The catalog will then get a column for it.
