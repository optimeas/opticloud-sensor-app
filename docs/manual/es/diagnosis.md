---
title: Diagnóstico
description: Registro, cola sin conexión y valores de prueba en la pestaña Diagnóstico de la app optiCLOUD Sensor, y cómo exportar el registro.
sidebar_label: Diagnóstico
sidebar_position: 8
image: "/img/om_social_card.png"
keywords:
  - diagnóstico
  - registro
  - soporte
  - cola sin conexión
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Diagnóstico

La pestaña **Diagnóstico** muestra lo que ocurre entre el teléfono y optiCLOUD. Te ayuda a comprobar una integración, y a nosotros a ayudarte cuando hay un problema.

## Enviar un valor

Aquí envías a mano un valor suelto, por ejemplo para probar un Dashboard o una regla de alarma.

1. Introduce una **Clave** en lowerCamelCase, por ejemplo `testValue`.
2. Elige el **Tipo**: Número, Texto o Sí/No.
3. Introduce el **Valor**.
4. Toca **Enviar como telemetría** o **Enviar como atributo de cliente**.

La telemetría pasa, como cualquier valor medido, por la cola sin conexión y llega aunque en ese momento no haya conexión. Un atributo de cliente necesita una conexión abierta.

## Cola sin conexión

| Fila | Significado |
|---|---|
| **Muestras** | Cuántas muestras esperan a ser entregadas |
| **Tamaño** | Cuánto espacio ocupan, como máximo 50 MB |
| **Más antiguo** | La marca de tiempo de la muestra más antigua en espera |
| **Descartados** | Cuántas muestras ha descartado la app porque la cola estaba llena o porque optiCLOUD no aceptó un mensaje repetidas veces |
| **Intervalo descartado** | El periodo del que proceden las muestras descartadas |

Con **Restablecer el contador de descartados** pones el contador a cero. Cómo funciona la cola se explica en [Envío](sending.md).

## Registro

El registro muestra, lo más reciente primero:

- los comandos de optiCLOUD con sus parámetros y la respuesta de la app,
- los cambios de los Shared Attributes, también de claves que la app no usa; en lugar del identificador de la instalación en `sensorAppInstallation` solo indica si la vinculación pertenece a este teléfono,
- los valores que la app no ha podido usar, por ejemplo una frecuencia de envío no válida,
- los cambios de la conexión con su motivo, por ejemplo «Sin red»,
- el inicio y el fin de la ubicación y los problemas con ella,
- cada inicio de la app, con una indicación cuando iOS la inició en segundo plano,
- cuándo la app pasó a segundo plano y volvió a primer plano, y **En pausa** cuando iOS detuvo la app, con la duración de la pausa,
- los valores que has enviado a mano.

El registro está en los datos de la app en el teléfono y guarda las últimas 1000 entradas, también tras un nuevo inicio de la app. Las entradas de días anteriores muestran la fecha. Con **Borrar** lo vacías.

## Exportar el registro

Toca el símbolo de compartir arriba a la derecha (un cuadrado con una flecha hacia arriba). VoiceOver lo llama **Exportar registro**. La app crea un texto que puedes compartir por correo, por mensaje o en un archivo. Contiene:

- la versión de la app, el modelo del teléfono y la versión de iOS,
- el dispositivo, el proyecto, el Tenant y el servidor,
- el estado de la conexión y del envío, la frecuencia de envío y el modo de envío,
- los sensores seleccionados,
- el estado de la cola sin conexión,
- todas las entradas del registro.

El texto no contiene ni tu contraseña ni el Access Token del dispositivo. Antes de compartirlo, puedes leerlo: es solo texto.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
