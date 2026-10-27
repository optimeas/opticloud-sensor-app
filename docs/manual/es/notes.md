---
title: Notas
description: Escribir notas en el dispositivo en optiCLOUD con la app optiCLOUD Sensor, en la app o con Siri, también sin red.
sidebar_label: Notas
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - nota
  - nota rápida
  - Siri
  - atajo
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH y optiMEAS Switzerland GmbH
---

# Notas

Con una nota registras lo que está pasando: una observación, una avería, el inicio de un recorrido de medición. optiCLOUD la guarda como nota en el dispositivo al que envía este teléfono y la muestra allí junto a los valores medidos.

Para escribir tienes que haber iniciado sesión en la app. La nota pertenece a tu cuenta.

## Escribir una nota en la app

1. En la pestaña **Live**, toca el símbolo **Nueva nota** arriba a la derecha.
2. Escribe el texto. El cursor ya está en el campo **Nota**.
3. Toca **Guardar**.

No hace falta un título. Si dejas vacío **Título (opcional)**, la app toma como título la primera línea del texto, como máximo 60 caracteres. Debajo del texto ves cuál será el título.

En **Detalles** ajustas **Estado** y **Prioridad**. Si no los cambias, el estado es **Creado** y la prioridad **Media**.

## Una nota con Siri o un atajo

La app ofrece dos atajos:

| Atajo | Qué hace |
|---|---|
| **Nueva nota de optiCLOUD** | Pide el texto y guarda la nota sin abrir la app. Con Siri dictas el texto. |
| **Nueva nota de optiCLOUD en la app** | Abre la app con el formulario para una nota nueva |

Di por ejemplo «Oye Siri, nueva nota en optiCLOUD Sensor». Siri pregunta «¿Qué debe decir la nota?», dictas el texto y Siri te dice si la nota ya está en optiCLOUD o se enviará más tarde.

También encuentras los dos atajos en Spotlight y en la app Atajos. En un iPhone con botón de acción puedes asignar uno de ellos al botón en Ajustes, en **Botón de acción**.

## Qué se guarda con la nota

- el momento de guardarla, al final del texto en la forma `2026-10-24 15:42 +02:00`,
- la posición del teléfono, si has permitido la ubicación a la app. La app la espera como máximo 5 segundos y, si no llega, guarda la nota sin posición.

optiCLOUD asigna a una nota la hora en que llega. Si llega más tarde, el momento de guardarla sigue estando en el texto.

## Sin red

La app guarda primero cada nota en el teléfono y la envía desde allí. Sin red se queda en el teléfono y sale en cuanto optiCLOUD vuelve a estar accesible. La app lo intenta cada minuto, cuando pasa a primer plano y después de iniciar sesión.

En la pestaña **Live** ves cuántas notas siguen esperando. Si tu sesión ha caducado, vuelve a iniciar sesión; después salen las notas. Tras cerrar sesión se quedan en el teléfono y solo salen cuando vuelves a iniciar sesión con la misma cuenta.

Si optiCLOUD rechaza una nota, por ejemplo porque el dispositivo ya no existe, la app la aparta. En la pestaña **Diagnóstico**, en **Notas**, la ves con el mensaje de optiCLOUD y puedes volver a enviarla o eliminarla (consulta [Diagnóstico](diagnosis.md)). La app nunca elimina una nota por sí sola.

## Después del envío

Una nota enviada la cambias y la archivas en optiCLOUD. La app ya no la cambia. En optiCLOUD las notas no se pueden eliminar una a una; se eliminan junto con su dispositivo.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
