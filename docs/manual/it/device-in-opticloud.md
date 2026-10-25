---
title: Il dispositivo in optiCLOUD
description: Telemetria, attributi client, Shared Attributes e comandi di un dispositivo dell’app optiCLOUD Sensor.
sidebar_label: Il dispositivo in optiCLOUD
sidebar_position: 6
image: "/img/om_social_card.png"
keywords:
  - dispositivo
  - telemetria
  - attributo client
  - Shared Attributes
  - RPC
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Il dispositivo in optiCLOUD

Per optiCLOUD il tuo telefono è un dispositivo come qualsiasi altro. Lo trovi nel progetto selezionato con il suo nome e con il tipo di dispositivo «optiCLOUD Sensor App». I suoi valori li usi in Dashboard, regole di allarme e report come quelli di qualsiasi altro dispositivo.

## Telemetria

I valori misurati arrivano come telemetria. Ogni valore ha il timestamp del momento in cui è stato misurato, non di quello in cui è stato inviato. Per questo i valori della coda offline compaiono nel punto giusto della serie temporale. Quali chiavi esistono è descritto in [Sensori](sensors.md).

## Attributi client

Dopo ogni connessione e a ogni modifica, l’app comunica che cos’è il telefono e che cosa sta facendo:

| Chiave | Contenuto |
|---|---|
| `appVersion` | Versione dell’app |
| `os` | `iOS` o `Android` |
| `osVersion` | Versione del sistema operativo |
| `model` | Modello del telefono, per esempio `iPhone 16 Pro Max` |
| `sensorsAvailable` | I valori che questo telefono offre |
| `sensors` | I valori attualmente selezionati |
| `sendRate` | La frequenza di invio in secondi |
| `transmitting` | Se il telefono sta inviando |

`sensorsAvailable` e `sensors` sono elenchi di gruppi e valori separati da virgole, per esempio `device,location,accelMagnitude`. Il nome di un gruppo vale per tutti i valori del gruppo.

## Impostazioni da optiCLOUD

Due impostazioni dell’app puoi stabilirle in optiCLOUD tramite gli Shared Attributes del dispositivo:

| Shared Attribute | Tipo | Impostazione |
|---|---|---|
| `sendRate` | Numero | Frequenza di invio in secondi, da 1 a 3600 |
| `sensors` | Testo | Selezione dei sensori, per esempio `motion,location` |

- Se lo Shared Attribute esiste, l’app ne adotta il valore e mostra l’impostazione come gestita. Sul telefono non si può più modificare.
- Se elimini lo Shared Attribute, l’app mantiene l’ultimo valore e l’impostazione si può di nuovo modificare sul telefono.
- Un valore che l’app non può usare viene ignorato e segnalato nel tab [Diagnostica](diagnosis.md). Vale per esempio per una frequenza di invio fuori dall’intervallo o per un nome di sensore sconosciuto.
- Se il telefono non è connesso in quel momento, l’app recupera i valori alla connessione successiva.

Così puoi per esempio stabilire la stessa selezione per tutti i telefoni di un progetto, senza impostarli uno per uno.

Lo Shared Attribute `sensorAppInstallation` lo scrive l’app stessa. Associa il dispositivo a un telefono. Non modificarlo né eliminarlo a mano.

## Comandi

Finché il telefono è connesso, puoi inviargli comandi (RPC) da optiCLOUD, per esempio da un Dashboard. L’app risponde a ogni comando e lo mostra nel tab [Diagnostica](diagnosis.md).

| Comando | Parametri | Effetto | Risposta |
|---|---|---|---|
| `ping` | nessuno | nessuno | `{ "pong": true }` |
| `getState` | nessuno | nessuno | per esempio `{ "transmitting": false, "sendRate": 5, "sensors": "motion,location" }` |
| `startTransmission` | nessuno | Avvia l’invio | `{ "transmitting": true }` |
| `stopTransmission` | nessuno | Interrompe l’invio | `{ "transmitting": false }` |
| `setSendRate` | `{ "seconds": 5 }` | Modifica la frequenza di invio | `{ "sendRate": 5 }` |
| `sendNow` | nessuno | Misura subito tutti i valori selezionati e li invia, anche se l’invio è disattivato | `{ "sent": true }` |

Se l’app non può eseguire un comando, non modifica nulla e risponde con un errore, per esempio `{ "error": "unknown method" }`:

| Errore | Causa |
|---|---|
| `unknown method` | L’app non conosce questo comando. |
| `invalid params` | Un parametro manca, ha il tipo sbagliato o è fuori dall’intervallo. |
| `managed setting` | L’impostazione è gestita tramite uno Shared Attribute. |

Un comando raggiunge il telefono solo finché è connesso. Perché il telefono riceva comandi anche senza inviare, attiva l’opzione **Connesso** in **Impostazioni → Connessione**.

## Maggiori dettagli

I messaggi sono descritti con precisione nella specifica: [`docs/spec/messages.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/messages.md).

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
