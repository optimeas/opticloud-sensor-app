---
title: Por qué código abierto
description: Por qué optiMEAS publica la app optiCLOUD Sensor y su interfaz.
sidebar_label: Por qué código abierto
sidebar_position: 1
image: "/img/om_social_card.png"
keywords:
  - código abierto
  - MIT
  - transparencia
  - optiCLOUD
  - interfaz
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Por qué código abierto

optiCLOUD Sensor es de código abierto. El código fuente completo de ambas apps, la especificación y esta documentación son públicos en GitHub: [github.com/optimeas/opticloud-sensor-app](https://github.com/optimeas/opticloud-sensor-app). El código está bajo la licencia MIT, y la documentación, bajo CC BY 4.0.

Hay motivos para ello que van más allá de esta app.

## Ves lo que envía la app

Una app que mide la ubicación, el movimiento y los sonidos merece desconfianza mientras no se pueda comprobar qué hace con ellos. Con optiCLOUD Sensor puedes comprobarlo. Cada valor que envía la app está descrito en la especificación, y el código que lo mide y lo envía puede leerlo cualquiera. La app solo envía al dispositivo de optiCLOUD que tú mismo has elegido, y a ningún otro servicio. Qué significa esto en detalle se explica en [Privacidad](privacy.md).

La honestidad forma parte de ello: donde la app estima, lo dice. El nivel sonoro es una estimación y no una medición calibrada; el volumen de datos, un cálculo y no la factura de tu operador de telefonía móvil.

## Un ejemplo de integración con optiCLOUD

La app es también un ejemplo completo y funcional de cómo un dispositivo se comunica con optiCLOUD:

- iniciar sesión mediante la interfaz REST y crear o elegir un dispositivo,
- enviar telemetría y atributos de cliente mediante MQTT,
- recibir Shared Attributes y dejar que optiCLOUD gestione los ajustes,
- aceptar y responder comandos (RPC),
- guardar temporalmente los valores medidos sin red y entregarlos después en el orden correcto.

Quien quiera conectar a optiCLOUD su propio dispositivo, gateway o software no encuentra aquí un fragmento, sino un conjunto completo que funciona en el día a día: en Swift para iOS y pronto también en Kotlin para Android.

## Una especificación abierta

Las apps siguen una especificación común en la carpeta [`docs/spec`](https://github.com/optimeas/opticloud-sensor-app/tree/main/docs/spec). Describe con palabras propias el inicio de sesión, la conexión, los mensajes, los sensores y la cola sin conexión. Los vectores de prueba fijan cómo se redondean, seleccionan, agrupan y empaquetan los valores. Ambas apps tienen que superar todos los vectores. Así, iOS y Android se mantienen iguales, y quien escriba una tercera implementación puede comprobarla con los mismos vectores.

## Conócenos

optiMEAS representa competencia, trato de igual a igual, apertura, honestidad y conocimiento. En lugar de limitarnos a afirmarlo, mostramos nuestro trabajo: cómo recogemos los requisitos, justificamos las decisiones, probamos y documentamos. Puedes formarte tu propia opinión antes de trabajar con nosotros.

Compartimos el conocimiento porque así crece. Lo que hemos aprendido al construir la app sobre sensores, funcionamiento en segundo plano y MQTT en smartphones está en la especificación y en el código, también los escollos.

## Participa

Los errores, las preguntas y las propuestas son bienvenidos en GitHub, como issue o como pull request. Tratamos las contribuciones de igual a igual, tanto si vienen de un cliente como de un estudiante o de otra empresa. Cómo se organiza el trabajo en el repositorio se explica en el [README](https://github.com/optimeas/opticloud-sensor-app#readme).

## No es el primer proyecto de este tipo

optiCLOUD Sensor no es nuestro primer proyecto abierto. El Open Streaming Format (OSF), nuestro formato de archivo para datos de medición y de proceso, también tiene una especificación abierta y está publicado en GitHub: [github.com/optimeas/osf](https://github.com/optimeas/osf). Su documentación está en Formatos de datos, en la [documentación de optiMEAS](https://docs.optimeas.com). Ambos proyectos siguen la misma idea: lo que publicamos, cualquiera puede comprobarlo, usarlo y mejorarlo.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
