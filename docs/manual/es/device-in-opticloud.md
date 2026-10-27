---
title: El dispositivo en optiCLOUD
description: Telemetría, atributos de cliente, Shared Attributes y comandos de un dispositivo de la app optiCLOUD Sensor.
sidebar_label: El dispositivo en optiCLOUD
sidebar_position: 6
image: "/img/om_social_card.png"
keywords:
  - dispositivo
  - telemetría
  - atributo de cliente
  - Shared Attributes
  - RPC
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# El dispositivo en optiCLOUD

Para optiCLOUD, tu teléfono es un dispositivo como cualquier otro. Lo encuentras en el proyecto seleccionado con su nombre y con el tipo de dispositivo «optiCLOUD Sensor App». Sus valores los usas en Dashboards, reglas de alarma e informes igual que los de cualquier otro dispositivo.

## Telemetría

Los valores medidos llegan como telemetría. Cada valor lleva la marca de tiempo del momento en que se midió, no la del momento en que se envió. Por eso, los valores de la cola sin conexión aparecen en el lugar correcto de la serie temporal. Qué claves existen se indica en [Sensores](sensors.md).

## Atributos de cliente

Tras cada conexión y con cada cambio, la app comunica qué es el teléfono y qué está haciendo en ese momento:

| Clave | Contenido |
|---|---|
| `appVersion` | Versión de la app |
| `os` | `iOS` o `Android` |
| `osVersion` | Versión del sistema operativo |
| `model` | Modelo del teléfono, por ejemplo `iPhone 16 Pro Max` |
| `sensorsAvailable` | Los valores que ofrece este teléfono |
| `sensors` | Los valores seleccionados en este momento |
| `sendRate` | La frecuencia de envío en segundos |
| `transmitting` | Si el teléfono está enviando en este momento |

`sensorsAvailable` y `sensors` son listas de grupos y valores separadas por comas, por ejemplo `device,location,accelMagnitude`. El nombre de un grupo equivale a todos los valores del grupo.

## Ajustes desde optiCLOUD

Puedes fijar tres ajustes de la app en optiCLOUD mediante Shared Attributes del dispositivo:

| Shared Attribute | Tipo | Ajuste |
|---|---|---|
| `sendRate` | Número | Frecuencia de envío en segundos, de 1 a 3600 |
| `sensors` | Texto | Selección de sensores, por ejemplo `motion,location` |
| `dashboard` | Texto | Dashboard predeterminado en la pestaña [Favoritos](favorites.md), el ID del Dashboard |

- Si el Shared Attribute existe, la app adopta su valor y muestra el ajuste como gestionado. En ese caso no se puede cambiar en el teléfono.
- Si borras el Shared Attribute, la app conserva el último valor y el ajuste vuelve a poder cambiarse en el teléfono.
- Un valor que la app no puede usar lo ignora y lo muestra en la pestaña [Diagnóstico](diagnosis.md). Esto vale, por ejemplo, para una frecuencia de envío fuera del rango o un nombre de sensor desconocido.
- Si el teléfono no está conectado en ese momento, la app recoge los valores en la siguiente conexión.

Así puedes, por ejemplo, fijar la misma selección para todos los teléfonos de un proyecto sin configurar cada uno por separado.

El Shared Attribute `sensorAppInstallation` lo escribe la propia app. Vincula el dispositivo a un teléfono. No lo cambies ni lo borres a mano.

## Comandos

Mientras el teléfono esté conectado, puedes enviarle comandos (RPC) desde optiCLOUD, por ejemplo desde un Dashboard. La app responde a cada comando y lo muestra en la pestaña [Diagnóstico](diagnosis.md).

| Comando | Parámetros | Efecto | Respuesta |
|---|---|---|---|
| `ping` | ninguno | ninguno | `{ "pong": true }` |
| `getState` | ninguno | ninguno | por ejemplo `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | ninguno | Inicia el envío | `{ "transmitting": true }` |
| `stopTransmission` | ninguno | Detiene el envío | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Cambia la frecuencia de envío | `{ "sendRate": 5 }` |
| `sendNow` | ninguno | Mide al instante todos los valores seleccionados y los envía, aunque el envío esté desactivado | `{ "sent": true }` |

Si la app no puede ejecutar un comando, no cambia nada y responde con un error, por ejemplo `{ "error": "unknown method" }`:

| Error | Causa |
|---|---|
| `unknown method` | La app no conoce este comando. |
| `invalid params` | Falta un parámetro, tiene un tipo incorrecto o está fuera del rango. |
| `managed setting` | El ajuste se gestiona mediante un Shared Attribute. |

Un comando solo llega al teléfono mientras está conectado. Para que el teléfono reciba comandos también sin enviar, activa la opción **Conectado** en **Ajustes → Conexión**.

## Más detalles

Los mensajes se describen con precisión en la especificación: [`docs/spec/messages.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/messages.md).

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
