---
title: Privacidad
description: Qué datos recoge la app optiCLOUD Sensor, adónde van y qué se queda en el teléfono.
sidebar_label: Privacidad
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - privacidad
  - ubicación
  - micrófono
  - Access Token
  - llavero
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Privacidad

La app mide cosas que pueden revelar mucho sobre ti: dónde estás, cómo te mueves, cuánto ruido hay a tu alrededor. Por eso explicamos aquí con exactitud qué hace con ellas. Puedes comprobarlo en el [código fuente](https://github.com/optimeas/opticloud-sensor-app).

## Lo más importante

- La app solo envía al servidor de optiCLOUD que indicas al iniciar sesión, y allí solo al dispositivo que has elegido.
- Solo envía mientras tienes el envío activado, y solo los sensores que has seleccionado.
- No contiene publicidad ni servicios de análisis o de seguimiento, y no se comunica con ningún otro servicio.
- No graba sonido. Del micrófono solo usa el volumen.
- No guarda tu contraseña.

## Qué se envía a optiCLOUD

| Datos | Cuándo |
|---|---|
| Los valores de los sensores seleccionados, con marca de tiempo | Mientras el envío está activado, y una vez con el comando `sendNow` |
| Versión de la app, sistema operativo, modelo del teléfono, sensores disponibles y seleccionados, frecuencia de envío, si se está enviando | Tras cada conexión y con cada cambio |
| Respuestas a comandos | Cuando optiCLOUD envía un comando |
| Valores que envías a mano en la pestaña Diagnóstico | Cuando los envías |
| Correo electrónico y contraseña | Solo al iniciar sesión, para identificarte |

En optiCLOUD, estos datos pertenecen al dispositivo de tu Tenant. Quién puede verlos allí lo determinan los permisos de tu Tenant. Tenlo en cuenta, sobre todo con la ubicación: todos los que pueden ver el dispositivo en optiCLOUD ven también dónde ha estado el teléfono.

La conexión está cifrada (TLS).

## Qué se queda en el teléfono

- **En el llavero de iOS:** el Access Token del dispositivo, la sesión de tu inicio de sesión y un identificador de la instalación con el que la app vincula el dispositivo a este teléfono.
- **En los datos de la app:** los ajustes, la cola sin conexión con los valores aún no enviados, los contadores del volumen de datos y el registro de la pestaña Diagnóstico. El registro solo sale del teléfono si lo exportas tú.

## Permisos

| Permiso | Para qué |
|---|---|
| Ubicación | El grupo Ubicación y, con «Siempre», el envío en segundo plano (consulta [Segundo plano y ubicación](background.md)) |
| Movimiento y forma física | El grupo Actividad (pasos y tipo de actividad) y la presión atmosférica |
| Micrófono | El grupo Sonido: solo el volumen |

iOS solo pide un permiso cuando has seleccionado un sensor que lo necesita e inicias el envío. Puedes retirar cualquier permiso en cualquier momento en los Ajustes de iOS. La app sigue enviando entonces los demás valores.

## Responsabilidad

A los datos en optiCLOUD se aplican los acuerdos entre tú o tu empresa y el operador del servidor de optiCLOUD. Para preguntas sobre la app, puedes contactarnos a través del [sitio web de optiMEAS](https://optimeas.com) o en [GitHub](https://github.com/optimeas/opticloud-sensor-app/issues).

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
