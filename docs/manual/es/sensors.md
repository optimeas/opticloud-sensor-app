---
title: Sensores
description: Qué valores mide la app optiCLOUD Sensor, en qué unidades y con qué claves llegan a optiCLOUD.
sidebar_label: Sensores
sidebar_position: 4
image: "/img/om_social_card.png"
keywords:
  - sensores
  - telemetría
  - aceleración
  - ubicación
  - nivel sonoro
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Sensores

La app ofrece todos los sensores que tiene tu teléfono. Los sensores están ordenados en grupos. En **Ajustes → Envío → Sensores** activas y desactivas grupos completos; si tocas un grupo, puedes desmarcar valores sueltos dentro de él. De fábrica están seleccionados los grupos Dispositivo y Ubicación.

Si un sensor necesita un permiso, iOS lo pide en cuanto se inicia el envío. Si lo deniegas, faltan los valores de ese sensor; los demás se siguen enviando.

En optiCLOUD, los valores llegan como telemetría del dispositivo, con las claves de las tablas de abajo. Una clave tiene la misma unidad y el mismo significado en iOS y en Android. La app redondea cada valor a la resolución indicada. Si un valor no está disponible en ese momento, la app lo omite en lugar de enviar un marcador de posición.

## Movimiento

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Aceleración | `accelX`, `accelY`, `accelZ` | m/s² | 0,01 |
| Magnitud de la aceleración | `accelMagnitude` | m/s² | 0,01 |
| Velocidad de rotación | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0,001 |
| Campo magnético | `magX`, `magY`, `magZ` | µT | 0,1 |
| Orientación | `roll`, `pitch`, `yaw` | grados | 0,1 |

Los ejes se refieren al teléfono sostenido en vertical, con la pantalla hacia ti: x apunta a la derecha, y hacia arriba, z hacia fuera de la pantalla. Un teléfono que está plano sobre la mesa mide en z unos +9,81 m/s², la aceleración de la gravedad. La magnitud de la aceleración no depende de cómo se sostenga el teléfono y, en reposo, es de unos 9,81.

La aceleración y la velocidad de rotación la app las mide a 50 Hz y en cada ciclo envía la media con la propia clave, además del mínimo y el máximo con la terminación `Min` y `Max`, por ejemplo `accelXMin` y `accelXMax`.

Sobre la orientación: `pitch` es positivo cuando el borde superior está levantado (90 en vertical), `roll` es positivo cuando el borde derecho está bajado, y `yaw` es la dirección del borde superior en el sentido de las agujas del reloj desde el norte magnético. Mientras iOS no haya calibrado la brújula, faltan el campo magnético y `yaw`.

## Entorno

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Presión atmosférica | `pressure` | hPa | 0,1 |

La presión atmosférica necesita el permiso de «Movimiento y forma física».

La luz ambiental (`light`) solo existe en Android; iOS no ofrece ninguna interfaz para ello.

## Ubicación

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Posición | `latitude`, `longitude` | grados (WGS 84) | 0,00001 |
| Altitud | `altitude` | m sobre el nivel del mar | 0,1 |
| Velocidad | `speed` | km/h | 0,1 |
| Rumbo | `course` | grados, en el sentido de las agujas del reloj desde el norte | 1 |
| Precisión de la ubicación | `locationAccuracy` | m | 1 |

La ubicación necesita tu permiso. Con «Siempre», la app sigue enviando también en segundo plano (consulta [Segundo plano y ubicación](background.md)).

## Actividad

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Pasos de hoy | `steps` | cantidad | 1 |
| Tipo de actividad | `activityType` | texto | – |

`steps` cuenta desde la medianoche, hora local. `activityType` es uno de los textos `stationary`, `walking`, `running`, `cycling`, `automotive` o `unknown` y se envía en cuanto iOS detecta una nueva actividad. Un coche parado sigue contando como `automotive`. El grupo necesita el permiso de «Movimiento y forma física».

## Dispositivo

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Nivel de batería | `batteryLevel` | 0 a 1 | 0,01 |
| Cargando | `charging` | sí/no | – |
| Red | `network` | texto | – |
| Estado térmico | `thermalState` | texto | – |
| Modo de bajo consumo | `powerSaving` | sí/no | – |
| Volumen de datos | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | byte | 1000 |

`network` es `wifi`, `cellular`, `other` o `none`. `thermalState` es `nominal`, `fair`, `serious` o `critical`. El volumen de datos es el de la propia app, hoy y en el mes en curso (consulta [Volumen de datos](data-volume.md)).

La intensidad de la señal móvil (`cellularSignal`) solo existe en Android; iOS no ofrece ninguna interfaz pública para ello.

## Sonido

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Nivel sonoro | `soundLevel` | dB | 1 |

La app solo mide el volumen. No graba sonido ni lo envía.

El micrófono de un teléfono no está calibrado. Por eso, el nivel sonoro es una estimación: el nivel de todas las mediciones desde el último ciclo con respecto al fondo de escala, más 100 dB. Una sala tranquila da unos 30 a 50, una conversación unos 60 a 70. Distintos teléfonos pueden diferir entre sí en algunos decibelios.

La app solo mide el nivel sonoro mientras está abierta. iOS limita el micrófono en segundo plano; por eso, en segundo plano falta este valor.

## Salud

Los valores como la frecuencia cardiaca o la saturación de oxígeno de un reloj están previstos y llegarán en una versión posterior.

## Señal de prueba

| Valor | Clave | Unidad | Resolución |
|---|---|---|---|
| Contador de ciclos | `testCounter` | cantidad | 1 |
| Seno | `testSine` | −1 a 1 | 0,001 |

La señal de prueba no mide nada. Envía valores conocidos de antemano, para que puedas comprobar en optiCLOUD si ha llegado todo, por ejemplo en una prueba en segundo plano. No necesita ningún permiso y no está seleccionada de fábrica.

`testCounter` empieza en 1 cada vez que se inicia el envío y aumenta en 1 con cada ciclo. `testSine` es un seno con un periodo por minuto, calculado a partir de la marca de tiempo del valor.

Después de la prueba, exporta la telemetría del dispositivo en optiCLOUD como CSV y compruébala con el script [`check-test-signal.py`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/tools/check-test-signal.py):

```bash
python3 check-test-signal.py device-data.csv
```

Informa de los valores perdidos, las pausas en las que la app no se estaba ejecutando, los reinicios del envío y los valores que no corresponden a su marca de tiempo.

## Más detalles

La descripción completa, con todas las fórmulas y reglas, está en la especificación: [`docs/spec/sensors.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/sensors.md).

---

Esta documentación está publicada bajo la licencia [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Atribución: optiMEAS GmbH y optiMEAS Switzerland GmbH.
