---
title: Segundo plano y ubicación
description: Cómo la app optiCLOUD Sensor sigue enviando con la pantalla bloqueada y por qué necesita la ubicación para ello.
sidebar_label: Segundo plano y ubicación
sidebar_position: 5
image: "/img/om_social_card.png"
keywords:
  - segundo plano
  - ubicación
  - permiso de ubicación
  - iOS
  - batería
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Segundo plano y ubicación

iOS cierra las apps en segundo plano al poco tiempo. Una app solo puede seguir funcionando en segundo plano si tiene un motivo reconocido para ello. optiCLOUD Sensor usa para ello la ubicación: mientras la app mide y envía la ubicación, puede seguir funcionando, y con ella todos los demás sensores seleccionados.

La ubicación no es una excusa, sino un valor medido como cualquier otro. La app te dice abiertamente para qué la necesita, e iOS te muestra en todo momento cuándo la usa.

## Qué tienes que configurar

1. Selecciona el grupo **Ubicación** en **Ajustes → Envío → Sensores** (seleccionado de fábrica).
2. Inicia el envío. iOS pide permiso para la ubicación; permítela «Al usar la app».
3. Poco después, iOS pregunta una sola vez si la app puede usar la ubicación «Siempre». Permítelo.

El estado actual lo ves en **Ajustes → Envío → Acceso a la ubicación** mientras la ubicación esté seleccionada. Si has denegado el acceso, ahí aparece **Abrir Ajustes**. Más adelante lo cambias en la app Ajustes de iOS, en **optiCLOUD Sensor → Ubicación**; elige allí **Siempre**.

| Acceso a la ubicación | Qué ocurre |
|---|---|
| **Siempre** | La app envía también con la pantalla bloqueada y cuando usas otra app. |
| **Cuando se use la app** | La app envía mientras está en primer plano. |
| **Nunca** | La app no envía la ubicación y solo envía mientras está en primer plano. |

## Qué ves en el teléfono

Mientras la app usa la ubicación, iOS muestra una flecha en la barra de estado, junto a la hora. Es intencionado: así ves siempre que la app está midiendo. Si detienes el envío, la flecha desaparece.

## Detener el envío en segundo plano

Detén el envío en la pestaña **Live** con **Detener envío**.

Deslizar la app hacia arriba en el selector de apps **no** basta. El envío es un ajuste que se mantiene aunque la app se reinicie: cuando la app vuelve a iniciarse, sigue enviando. Es a propósito, porque un punto de medición no debe fallar solo porque la app se haya cerrado entretanto.

## Qué falta en segundo plano

- **Nivel sonoro:** iOS limita el micrófono en segundo plano. La app solo lo mide mientras está abierta.
- **Vista en directo:** los valores de la pestaña **Live** no se actualizan hasta que vuelves a abrir la app. Aun así, en optiCLOUD siguen llegando de forma continua.

## Batería

Medir la ubicación en segundo plano consume energía. Cuánta depende del teléfono, de la cobertura y de la frecuencia de envío. Para mediciones largas, un cargador ayuda. Con el grupo **Dispositivo** puedes seguir tú mismo el nivel de batería en optiCLOUD.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
