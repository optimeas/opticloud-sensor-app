---
title: Envío
description: Frecuencia de envío, modo de envío, conexión y cola sin conexión de la app optiCLOUD Sensor.
sidebar_label: Envío
sidebar_position: 3
image: "/img/om_social_card.png"
keywords:
  - frecuencia de envío
  - telemetría
  - MQTT
  - cola sin conexión
  - conexión
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Envío

Los ajustes del envío están en **Ajustes → Envío**. El envío se inicia y se detiene en la pestaña **Live**.

## Frecuencia de envío

La frecuencia de envío determina con qué frecuencia mide y envía la app: una vez cada 1 a 3600 segundos, de fábrica cada 2 segundos. Cada ciclo da lugar a una muestra con una marca de tiempo común.

Los valores rápidos, como la aceleración y la velocidad de rotación, la app los mide de forma continua entre dos ciclos a 50 Hz. En cada ciclo envía la media, el mínimo y el máximo de esas mediciones. Así no se pierden golpes ni vibraciones entre dos ciclos, ni siquiera con una frecuencia de envío larga.

## Modo de envío

| Modo | Qué envía la app |
|---|---|
| **Al cambiar** (de fábrica) | En cada ciclo, solo los valores que han cambiado desde el último envío. Una vez por minuto, todos los valores. |
| **En cada ciclo** | En cada ciclo, todos los valores seleccionados. |

«Cambiado» significa: el valor es distinto tras redondearlo a la resolución del sensor (consulta [Sensores](sensors.md)). Un nivel de batería de 0,8312 y otro de 0,8349, redondeados a 0,01, son el mismo valor y no se vuelven a enviar. Si en un ciclo no cambia nada, la app no envía nada.

La muestra completa una vez por minuto da a optiCLOUD un punto de referencia regular. Así, «Al cambiar» ahorra volumen de datos sin que se produzcan huecos largos en optiCLOUD.

Los valores que solo surgen con un evento, como un cambio de actividad, la app los envía de inmediato en ambos modos.

## Conexión

La app se comunica con optiCLOUD mediante MQTT, cifrado con TLS, y se identifica con el Access Token del dispositivo.

**Iniciar envío** también conecta la app. En **Ajustes → Conexión** puedes además mantener la conexión con **Conectado** sin enviar. Mientras haya conexión, optiCLOUD puede enviar comandos al teléfono (consulta [El dispositivo en optiCLOUD](device-in-opticloud.md)).

El estado muestra cómo está la conexión:

| Estado | Significado |
|---|---|
| **Desconectado** | Sin conexión y sin intentarlo. |
| **Conectando** | La app está estableciendo la conexión. |
| **Conectado** | La app está conectada a optiCLOUD. |
| **En espera** | La conexión se ha perdido o no se ha podido establecer, por ejemplo sin red. La app vuelve a intentarlo por sí sola. |
| **Rechazado** | optiCLOUD ha rechazado el Access Token, o el dispositivo está vinculado a otro teléfono. La app no vuelve a intentarlo. |

En **En espera**, la app espera primero 1 segundo y duplica la pausa con cada intento fallido hasta llegar a 60 segundos. Si iOS indica que la red ha vuelto, lo intenta de inmediato.

En **Rechazado**, la única solución es volver a elegir el dispositivo: inicia sesión y elige de nuevo el dispositivo en **Ajustes → Dispositivo**. Si otro teléfono ha tomado el dispositivo, así puedes recuperarlo.

## Cola sin conexión

Cada muestra va primero a una cola en el teléfono, aunque la app esté conectada. Desde ahí, la app entrega las muestras, la más antigua primero, y no las borra hasta que optiCLOUD ha confirmado su recepción.

- Sin red, la app sigue acumulando. En cuanto vuelve la conexión, entrega lo pendiente con las marcas de tiempo originales. Así no se produce ningún hueco en optiCLOUD.
- La cola se conserva aunque se reinicien la app y el teléfono.
- Tiene capacidad para hasta 50 MB. Si está llena, la app descarta las muestras más antiguas y las cuenta.
- Si la conexión se interrumpe antes de que optiCLOUD haya confirmado un mensaje, la app lo vuelve a enviar. En ese caso, optiCLOUD puede guardar algunos valores por duplicado, con la misma marca de tiempo.

Cuántas muestras esperan y cuántas se han descartado lo muestra la pestaña [Diagnóstico](diagnosis.md).

## Gestionado por optiCLOUD

La frecuencia de envío y la selección de sensores también pueden fijarse desde optiCLOUD, mediante Shared Attributes del dispositivo (consulta [El dispositivo en optiCLOUD](device-in-opticloud.md)). Si un ajuste se gestiona así, la app lo muestra como «gestionado» y no puedes cambiarlo en el teléfono.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
