---
title: Invio
description: Frequenza di invio, modalità di invio, connessione e coda offline dell’app optiCLOUD Sensor.
sidebar_label: Invio
sidebar_position: 3
image: "/img/om_social_card.png"
keywords:
  - frequenza di invio
  - telemetria
  - MQTT
  - coda offline
  - connessione
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Invio

Le impostazioni per l’invio si trovano in **Impostazioni → Invio**. L’invio si avvia e si interrompe nel tab **Live**.

## Frequenza di invio

La frequenza di invio stabilisce quanto spesso l’app misura e invia: una volta ogni 1–3600 secondi, di fabbrica ogni 2 secondi. Ogni ciclo produce un campione con un timestamp comune.

I valori rapidi come l’accelerazione e la velocità di rotazione vengono misurati dall’app in modo continuo a 50 Hz tra due cicli. A ogni ciclo invia media, minimo e massimo di queste misurazioni. Così urti e vibrazioni tra due cicli non vanno persi, anche con una frequenza di invio lunga.

## Modalità di invio

| Modalità | Cosa invia l’app |
|---|---|
| **Al cambiamento** (impostazione di fabbrica) | A ogni ciclo solo i valori che sono cambiati dall’ultimo invio. Una volta al minuto tutti i valori. |
| **A ogni ciclo** | A ogni ciclo tutti i valori selezionati. |

«Cambiato» significa: il valore è diverso dopo l’arrotondamento alla risoluzione del sensore (vedi [Sensori](sensors.md)). Un livello della batteria di 0,8312 e uno di 0,8349, arrotondati a 0,01, sono lo stesso valore e non vengono inviati di nuovo. Se in un ciclo non cambia nulla, l’app non invia nulla.

Il campione completo una volta al minuto dà a optiCLOUD un punto di riferimento regolare. Così «Al cambiamento» risparmia volume dati senza creare lunghe lacune in optiCLOUD.

I valori che nascono solo da un evento, come un cambio di attività, l’app li invia subito in entrambe le modalità.

## Connessione

L’app comunica con optiCLOUD tramite MQTT, crittografato con TLS, e si autentica con l’Access Token del dispositivo.

**Avvia invio** connette anche l’app. In **Impostazioni → Connessione** puoi inoltre mantenere la connessione con **Connesso** senza inviare. Finché la connessione è attiva, optiCLOUD può inviare comandi al telefono (vedi [Il dispositivo in optiCLOUD](device-in-opticloud.md)).

Lo stato mostra come sta la connessione:

| Stato | Significato |
|---|---|
| **Disconnesso** | Nessuna connessione e nessun tentativo. |
| **Connessione…** | L’app sta stabilendo la connessione. |
| **Connesso** | L’app è connessa a optiCLOUD. |
| **In attesa** | La connessione si è interrotta o non è stata stabilita, per esempio senza rete. L’app riprova da sola. |
| **Rifiutato** | optiCLOUD ha rifiutato l’Access Token, oppure il dispositivo è associato a un altro telefono. L’app non riprova. |

Con **In attesa** l’app attende prima 1 secondo e raddoppia la pausa a ogni tentativo fallito, fino a 60 secondi. Se iOS segnala che la rete è tornata, riprova subito.

Con **Rifiutato** l’unica soluzione è scegliere di nuovo il dispositivo: accedi e scegli ancora una volta il dispositivo in **Impostazioni → Dispositivo**. Se un altro telefono ha preso in carico il dispositivo, così puoi riprenderlo.

## Coda offline

Ogni campione va prima in una coda sul telefono, anche quando l’app è connessa. Da lì l’app consegna i campioni, dal più vecchio, e li elimina solo quando optiCLOUD ne ha confermato la ricezione.

- Senza rete l’app continua a raccogliere. Non appena la connessione è di nuovo disponibile, consegna i valori arretrati con i timestamp originali. Così in optiCLOUD non si crea nessuna lacuna.
- La coda sopravvive al riavvio dell’app e del telefono.
- Contiene fino a 50 MB. Quando è piena, l’app scarta i campioni più vecchi e li conta.
- Se la connessione si interrompe prima che optiCLOUD abbia confermato un messaggio, l’app lo invia di nuovo. optiCLOUD può allora salvare singoli valori due volte, con lo stesso timestamp.

Quanti campioni sono in attesa e quanti sono stati scartati lo mostra il tab [Diagnostica](diagnosis.md).

## Gestito da optiCLOUD

La frequenza di invio e la selezione dei sensori si possono stabilire anche da optiCLOUD, tramite gli Shared Attributes del dispositivo (vedi [Il dispositivo in optiCLOUD](device-in-opticloud.md)). Se un’impostazione è gestita in questo modo, l’app la mostra con «gestito» e non puoi modificarla sul telefono.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
