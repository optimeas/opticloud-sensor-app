---
title: Volume dati
description: Come l’app optiCLOUD Sensor conta il proprio volume dati e come puoi ridurlo.
sidebar_label: Volume dati
sidebar_position: 7
image: "/img/om_social_card.png"
keywords:
  - volume dati
  - rete cellulare
  - Wi-Fi
  - frequenza di invio
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Volume dati

Chi usa un telefono come punto di misura in movimento vuole sapere quanto costa in dati mobili. Per questo l’app conta il proprio volume dati.

## Dove lo vedi

In **Impostazioni → Invio → Volume dati di oggi** vedi il volume di oggi. Se lo tocchi, l’app mostra i dati inviati (↑) e ricevuti (↓) per oggi, questa settimana (da lunedì) e questo mese, separati ogni volta tra rete cellulare e Wi-Fi.

Con il gruppo **Dispositivo** l’app invia anche a optiCLOUD i totali di oggi e del mese (vedi [Sensori](sensors.md)). Così puoi seguire il volume di più telefoni in un Dashboard.

## Come conta l’app

L’app conta ogni messaggio che scambia con optiCLOUD con la sua dimensione. Per la crittografia e i protocolli di rete aggiunge a ogni messaggio un supplemento fisso. Il risultato è una stima: il tuo operatore di telefonia mobile calcola in modo diverso e può arrivare a un valore un po’ diverso. Le altre app non vengono conteggiate.

I contatori valgono per giorno, nell’ora locale del telefono. Quale rete conta lo decide iOS nel momento del messaggio.

Come viene contato esattamente è descritto nella specifica: [`docs/spec/connection.md`](https://github.com/optimeas/opticloud-sensor-app/blob/main/docs/spec/connection.md#data-volume).

## Come risparmiare volume dati

- **Modalità di invio «Al cambiamento»** (impostazione di fabbrica): l’app invia solo i valori che sono cambiati.
- **Frequenza di invio più lunga:** inviare ogni 10 secondi invece che ogni 2 secondi produce molti meno messaggi.
- **Meno sensori:** il gruppo Movimento invia a ogni ciclo media, minimo e massimo per più assi e cambia quasi sempre. Seleziona solo i valori che ti servono, per esempio solo il modulo dell’accelerazione.

Anche senza invio, una connessione esistente consuma un po’ di volume, perché l’app la verifica regolarmente.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
