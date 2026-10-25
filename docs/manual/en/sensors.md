---
title: Sensors
description: Which values the optiCLOUD Sensor app measures, in which units, and under which keys they arrive in optiCLOUD.
sidebar_label: Sensors
sidebar_position: 4
image: "/img/om_social_card.png"
keywords:
  - sensors
  - telemetry
  - acceleration
  - location
  - sound level
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Sensors

The app offers every sensor your phone has. The sensors are arranged in groups. Under **Settings → Transmission → Sensors** you switch whole groups on and off; tap a group to deselect single values in it. Out of the box the groups Device and Location are selected.

If a sensor needs a permission, iOS asks for it as soon as sending starts. If you decline, the values of that sensor are missing; the others are still sent.

In optiCLOUD the values arrive as telemetry of the device, under the keys in the tables below. A key has the same unit and the same meaning on iOS and Android. The app rounds every value to the resolution given. If a value is not available at the moment, the app leaves it out instead of sending a placeholder.

## Motion

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Acceleration | `accelX`, `accelY`, `accelZ` | m/s² | 0.01 |
| Acceleration magnitude | `accelMagnitude` | m/s² | 0.01 |
| Rotation rate | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0.001 |
| Magnetic field | `magX`, `magY`, `magZ` | µT | 0.1 |
| Orientation | `roll`, `pitch`, `yaw` | degree | 0.1 |

The axes refer to the phone held upright in portrait orientation, screen facing you: x points to the right, y up, z out of the screen. A phone lying flat on a table measures about +9.81 m/s² on z, the acceleration due to gravity. The acceleration magnitude does not depend on how the phone is held and is about 9.81 at rest.

Acceleration and rotation rate are measured at 50 Hz. At every tick the app sends the mean under the key itself, plus the minimum and maximum with the suffix `Min` and `Max`, for example `accelXMin` and `accelXMax`.

On orientation: `pitch` is positive when the top edge is raised (90 when upright in portrait), `roll` is positive when the right edge is lowered, and `yaw` is the direction of the top edge, clockwise from magnetic north. As long as iOS has not calibrated the compass, the magnetic field and `yaw` are missing.

## Environment

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Air pressure | `pressure` | hPa | 0.1 |

Air pressure needs the "Motion & Fitness" permission.

Ambient light (`light`) exists on Android only; iOS offers no interface for it.

## Location

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Position | `latitude`, `longitude` | degree (WGS 84) | 0.00001 |
| Altitude | `altitude` | m above sea level | 0.1 |
| Speed | `speed` | km/h | 0.1 |
| Course | `course` | degree, clockwise from north | 1 |
| Location accuracy | `locationAccuracy` | m | 1 |

Location needs your permission. With "Always" the app also goes on sending in the background (see [Background and location](background.md)).

## Activity

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Steps today | `steps` | count | 1 |
| Kind of activity | `activityType` | text | – |

`steps` counts from midnight, local time. `activityType` is one of the texts `stationary`, `walking`, `running`, `cycling`, `automotive`, or `unknown`, and is sent as soon as iOS detects a new activity. A car that stands still is still `automotive`. The group needs the "Motion & Fitness" permission.

## Device

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Battery level | `batteryLevel` | 0 to 1 | 0.01 |
| Charging | `charging` | yes/no | – |
| Network | `network` | text | – |
| Thermal state | `thermalState` | text | – |
| Low power mode | `powerSaving` | yes/no | – |
| Data volume | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | byte | 1000 |

`network` is `wifi`, `cellular`, `other`, or `none`. `thermalState` is `nominal`, `fair`, `serious`, or `critical`. The data volume is that of the app itself, today and in the current month (see [Data volume](data-volume.md)).

The signal strength of the mobile network (`cellularSignal`) exists on Android only; iOS offers no public interface for it.

## Sound

| Value | Key | Unit | Resolution |
|---|---|---|---|
| Sound level | `soundLevel` | dB | 1 |

The app measures only the loudness. It records no audio and sends none.

A phone microphone is not calibrated. The sound level is therefore an estimate: the level of all measurements since the previous tick relative to full scale, plus 100 dB. A quiet room gives about 30 to 50, a conversation about 60 to 70. Different phones can differ by several decibels.

The app measures the sound level only while it is open. iOS restricts the microphone in the background, so the value is missing there.

## Health

Values such as heart rate or oxygen saturation from a watch are planned and come in a later version.

## More details

The full description with all formulas and rules is in the specification: [`docs/spec/sensors.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/sensors.md).

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
