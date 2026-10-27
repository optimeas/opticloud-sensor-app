---
title: Primeros pasos
description: Iniciar sesión, elegir un dispositivo y enviar por primera vez valores de sensores a optiCLOUD.
sidebar_label: Primeros pasos
sidebar_position: 2
image: "/img/om_social_card.png"
keywords:
  - inicio de sesión
  - Tenant
  - proyecto
  - dispositivo
  - Access Token
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Primeros pasos

Tras el primer inicio, la app muestra «Ningún dispositivo». Antes de que pueda enviar, inicias sesión en optiCLOUD y eliges el dispositivo al que envía este teléfono. Esto lleva aproximadamente un minuto.

## Iniciar sesión

1. Toca **Iniciar sesión**.
2. En **optiCLOUD** figura la dirección de la aplicación web de optiCLOUD, por defecto `https://dashboard.opticloud.io`. Cámbiala solo si usas otro servidor de optiCLOUD.
3. Introduce el correo electrónico y la contraseña de tu cuenta personal de optiCLOUD y toca **Iniciar sesión**.
4. Si tienes acceso a varios Tenants, elige uno. Si solo tienes un Tenant, la app se salta este paso.
5. Si el Tenant pide un código por correo electrónico, introdúcelo y toca **Confirmar**. Con **Enviar un código nuevo** solicitas otro.
6. Elige el proyecto.

La app no guarda tu contraseña. Solo la necesita para iniciar sesión.

## Elegir un dispositivo

La app envía a un dispositivo de optiCLOUD, igual que cualquier otro hardware. La lista muestra solo dispositivos del tipo «optiCLOUD Sensor App» del proyecto seleccionado.

- **Dispositivo existente:** toca el dispositivo.
- **Dispositivo nuevo:** toca **Nuevo dispositivo**, introduce un nombre y toca **Crear**. El nombre debe ser único en el Tenant, por ejemplo «iPhone Anna».

A continuación, la app vincula el dispositivo a este teléfono y lee su Access Token. Con el Access Token se identifica después ante optiCLOUD como dispositivo.

Un dispositivo envía siempre desde un solo teléfono. Si el dispositivo elegido ya está vinculado a otro teléfono, la app te pregunta si quieres tomarlo. Si lo tomas, el otro teléfono deja de enviar a este dispositivo.

Para estos pasos necesitas en optiCLOUD el permiso para leer y crear dispositivos y para escribir sus atributos. Si falta un permiso, la app te dice cuál.

## Enviar por primera vez

1. Cambia a la pestaña **Live**.
2. Toca **Iniciar envío**. La app se conecta a optiCLOUD y empieza a enviar.
3. La primera vez, iOS pide los permisos que necesitan los sensores seleccionados, por ejemplo para la ubicación. Para el funcionamiento en segundo plano, permite primero la ubicación «Al usar la app»; después, la app pregunta una vez por «Siempre» (consulta [Segundo plano y ubicación](background.md)).

A partir de ahora, la pestaña **Live** muestra los valores medidos, y en optiCLOUD llegan como telemetría del dispositivo. De fábrica, la app envía los valores de los grupos Dispositivo y Ubicación cada 2 segundos, y solo cuando ha cambiado algún valor. Cómo cambiarlo se explica en [Envío](sending.md) y [Sensores](sensors.md).

Con **Detener envío** dejas de enviar.

## Las tres pestañas

| Pestaña | Contenido |
|---|---|
| **Live** | Iniciar y detener el envío, los valores actuales |
| **Favoritos** | Abrir páginas de optiCLOUD en Safari (consulta [Favoritos](favorites.md)) |
| **Diagnóstico** | Registro, cola sin conexión, enviar valores de prueba (consulta [Diagnóstico](diagnosis.md)) |
| **Ajustes** | Dispositivo, Conexión, Envío, Sensores, Volumen de datos, Cuenta, Acerca de |

## Cerrar sesión

En **Ajustes → Cuenta** cierras la sesión. Cerrar sesión no detiene el envío: el teléfono sigue enviando con el Access Token del dispositivo hasta que detengas el envío. Solo cuando quieras elegir otro dispositivo tendrás que volver a iniciar sesión.

## Elegir otro dispositivo

En **Ajustes → Dispositivo** toca **Elegir otro dispositivo**. Si en la cola sin conexión quedan valores aún no entregados, la app te dice cuántos son. Pertenecen al dispositivo anterior y se descartan si eliges otro.

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
