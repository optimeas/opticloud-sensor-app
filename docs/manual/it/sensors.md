---
title: Sensori
description: Quali valori misura l’app optiCLOUD Sensor, in quali unità e con quali chiavi arrivano in optiCLOUD.
sidebar_label: Sensori
sidebar_position: 4
image: "/img/om_social_card.png"
keywords:
  - sensori
  - telemetria
  - accelerazione
  - posizione
  - livello sonoro
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Sensori

L’app offre ogni sensore che il tuo telefono possiede. I sensori sono ordinati in gruppi. In **Impostazioni → Invio → Sensori** attivi e disattivi interi gruppi; se tocchi un gruppo, puoi deselezionarne singoli valori. Di fabbrica sono selezionati i gruppi Dispositivo e Posizione.

Se un sensore richiede un’autorizzazione, iOS la chiede non appena l’invio si avvia. Se rifiuti, mancano i valori di quel sensore; gli altri continuano a essere inviati.

In optiCLOUD i valori arrivano come telemetria del dispositivo, con le chiavi indicate nelle tabelle qui sotto. Una chiave ha la stessa unità e lo stesso significato su iOS e su Android. L’app arrotonda ogni valore alla risoluzione indicata. Se un valore al momento non è disponibile, l’app lo omette invece di inviare un segnaposto.

## Movimento

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Accelerazione | `accelX`, `accelY`, `accelZ` | m/s² | 0,01 |
| Modulo dell’accelerazione | `accelMagnitude` | m/s² | 0,01 |
| Velocità di rotazione | `gyroX`, `gyroY`, `gyroZ` | rad/s | 0,001 |
| Campo magnetico | `magX`, `magY`, `magZ` | µT | 0,1 |
| Orientamento | `roll`, `pitch`, `yaw` | gradi | 0,1 |

Gli assi si riferiscono al telefono tenuto in verticale in formato ritratto, con lo schermo verso di te: x punta a destra, y verso l’alto, z fuori dallo schermo. Un telefono appoggiato piatto sul tavolo misura su z circa +9,81 m/s², l’accelerazione di gravità. Il modulo dell’accelerazione non dipende da come viene tenuto il telefono e a riposo è di circa 9,81.

L’accelerazione e la velocità di rotazione vengono misurate dall’app a 50 Hz; a ogni ciclo l’app invia la media con la chiave stessa, più minimo e massimo con il suffisso `Min` e `Max`, per esempio `accelXMin` e `accelXMax`.

Sull’orientamento: `pitch` è positivo quando il bordo superiore è sollevato (90 in verticale in formato ritratto), `roll` è positivo quando il bordo destro è abbassato, e `yaw` è la direzione del bordo superiore in senso orario dal nord magnetico. Finché iOS non ha calibrato la bussola, mancano il campo magnetico e `yaw`.

## Ambiente

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Pressione atmosferica | `pressure` | hPa | 0,1 |

La pressione atmosferica richiede l’autorizzazione per «Movimento e fitness».

La luce ambientale (`light`) esiste solo su Android; iOS non offre un’interfaccia per questo.

## Posizione

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Posizione | `latitude`, `longitude` | gradi (WGS 84) | 0,00001 |
| Altitudine | `altitude` | m s.l.m. | 0,1 |
| Velocità | `speed` | km/h | 0,1 |
| Rotta | `course` | gradi, in senso orario dal nord | 1 |
| Precisione della posizione | `locationAccuracy` | m | 1 |

La posizione richiede la tua autorizzazione. Con «Sempre» l’app continua a inviare anche in background (vedi [Background e posizione](background.md)).

## Attività

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Passi di oggi | `steps` | numero | 1 |
| Tipo di attività | `activityType` | testo | – |

`steps` conta dalla mezzanotte, ora locale. `activityType` è uno dei testi `stationary`, `walking`, `running`, `cycling`, `automotive` o `unknown` e viene inviato non appena iOS riconosce una nuova attività. Un’auto ferma continua a valere come `automotive`. Il gruppo richiede l’autorizzazione per «Movimento e fitness».

## Dispositivo

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Livello batteria | `batteryLevel` | da 0 a 1 | 0,01 |
| In carica | `charging` | sì/no | – |
| Rete | `network` | testo | – |
| Stato termico | `thermalState` | testo | – |
| Modalità risparmio energetico | `powerSaving` | sì/no | – |
| Volume dati | `dataMobileToday`, `dataWifiToday`, `dataMobileMonth`, `dataWifiMonth` | byte | 1000 |

`network` è `wifi`, `cellular`, `other` o `none`. `thermalState` è `nominal`, `fair`, `serious` o `critical`. Il volume dati è quello dell’app stessa, oggi e nel mese in corso (vedi [Volume dati](data-volume.md)).

L’intensità del segnale della rete cellulare (`cellularSignal`) esiste solo su Android; iOS non offre un’interfaccia pubblica per questo.

## Suono

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Livello sonoro | `soundLevel` | dB | 1 |

L’app misura solo il volume. Non registra audio e non ne invia.

Il microfono di un telefono non è tarato. Il livello sonoro è quindi una stima: il livello di tutte le misurazioni dall’ultimo ciclo rispetto al fondo scala, più 100 dB. Una stanza silenziosa dà circa 30–50, una conversazione circa 60–70. Telefoni diversi possono differire tra loro di alcuni decibel.

Il livello sonoro viene misurato dall’app solo finché è aperta. iOS limita il microfono in background; in background il valore quindi manca.

## Salute

Valori come la frequenza cardiaca o la saturazione di ossigeno da un orologio sono previsti e arriveranno in una versione successiva.

## Segnale di test

| Valore | Chiave | Unità | Risoluzione |
|---|---|---|---|
| Contatore di cicli | `testCounter` | numero | 1 |
| Seno | `testSine` | da −1 a 1 | 0,001 |

Il segnale di test non misura nulla. Invia valori noti in anticipo, così puoi verificare in optiCLOUD se è arrivato tutto, per esempio in un test in background. Non richiede alcuna autorizzazione e non è selezionato di fabbrica.

`testCounter` parte da 1 a ogni avvio dell’invio e aumenta di 1 a ogni ciclo. `testSine` è un seno con un periodo al minuto, calcolato dalla marca temporale del valore.

Dopo il test, esporta la telemetria del dispositivo in optiCLOUD come CSV e verificala con lo script [`check-test-signal.py`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/tools/check-test-signal.py):

```bash
python3 check-test-signal.py device-data.csv
```

Segnala i valori persi, le pause in cui l’app non era in esecuzione, i riavvii dell’invio e i valori che non corrispondono alla loro marca temporale.

## Maggiori dettagli

La descrizione completa con tutte le formule e le regole si trova nella specifica: [`docs/spec/sensors.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/sensors.md).

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
