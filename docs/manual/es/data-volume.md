---
title: Volumen de datos
description: Cómo la app optiCLOUD Sensor cuenta su propio volumen de datos y cómo puedes reducirlo.
sidebar_label: Volumen de datos
sidebar_position: 7
image: "/img/om_social_card.png"
keywords:
  - volumen de datos
  - red móvil
  - Wi-Fi
  - frecuencia de envío
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Volumen de datos

Quien usa un teléfono como punto de medición fuera de casa quiere saber cuántos datos móviles consume. Por eso la app cuenta su propio volumen de datos.

## Dónde lo ves

En **Ajustes → Envío → Volumen de datos de hoy** ves el volumen de hoy. Si lo tocas, la app muestra los datos enviados (↑) y recibidos (↓) de hoy, de esta semana (desde el lunes) y de este mes, separados en cada caso por red móvil y Wi-Fi.

Con el grupo **Dispositivo**, la app envía también a optiCLOUD los totales de hoy y del mes (consulta [Sensores](sensors.md)). Así puedes seguir el volumen de varios teléfonos en un Dashboard.

## Cómo cuenta la app

La app cuenta cada mensaje que intercambia con optiCLOUD con su tamaño. Por el cifrado y los protocolos de red, añade un recargo fijo por mensaje. El resultado es una estimación: tu operador de telefonía móvil calcula de otra forma y puede llegar a un valor algo distinto. Lo que usan otras apps no se cuenta.

Los contadores se aplican por día, en la hora local del teléfono. Qué red cuenta lo decide iOS en el momento del mensaje.

Cómo se cuenta exactamente se describe en la especificación: [`docs/spec/connection.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/connection.md#data-volume).

## Cómo ahorrar volumen de datos

- **Modo de envío «Al cambiar»** (de fábrica): la app solo envía los valores que han cambiado.
- **Frecuencia de envío más larga:** enviar cada 10 segundos en lugar de cada 2 segundos genera muchos menos mensajes.
- **Menos sensores:** el grupo Movimiento envía en cada ciclo la media, el mínimo y el máximo de varios ejes y cambia casi siempre. Selecciona solo los valores que necesites, por ejemplo solo la magnitud de la aceleración.

Incluso sin enviar, una conexión abierta consume un poco de volumen, porque la app la comprueba con regularidad.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
