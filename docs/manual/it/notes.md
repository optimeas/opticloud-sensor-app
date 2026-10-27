---
title: Note
description: Scrivere note sul dispositivo in optiCLOUD con l’app optiCLOUD Sensor, nell’app o con Siri, anche senza rete.
sidebar_label: Note
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - nota
  - nota rapida
  - Siri
  - comando rapido
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH e optiMEAS Switzerland GmbH
---

# Note

Con una nota registri quello che sta succedendo: un’osservazione, un guasto, l’inizio di un percorso di misura. optiCLOUD la salva come nota sul dispositivo a cui questo telefono invia e la mostra lì accanto ai valori misurati.

Per scrivere devi aver eseguito l’accesso nell’app. La nota appartiene al tuo account.

## Scrivere una nota nell’app

1. Nel tab **Live**, tocca il simbolo **Nuova nota** in alto a destra.
2. Scrivi il testo. Il cursore è già nel campo **Nota**.
3. Tocca **Salva**.

Un titolo non è necessario. Se lasci vuoto **Titolo (facoltativo)**, l’app usa come titolo la prima riga del testo, al massimo 60 caratteri. Sotto il testo vedi quale sarà il titolo.

In **Dettagli** imposti **Stato** e **Priorità**. Senza modifiche lo stato è **Creato** e la priorità **Media**.

## Una nota con Siri o un comando rapido

L’app offre due comandi rapidi:

| Comando rapido | Cosa fa |
|---|---|
| **Nuova nota optiCLOUD** | Chiede il testo e salva la nota senza aprire l’app. Con Siri detti il testo. |
| **Nuova nota optiCLOUD nell’app** | Apre l’app con il modulo per una nuova nota |

Di’ per esempio «Ehi Siri, nuova nota in optiCLOUD Sensor». Siri chiede «Cosa deve dire la nota?», detti il testo e Siri ti dice se la nota è già in optiCLOUD o verrà inviata più tardi.

Trovi entrambi i comandi rapidi anche in Spotlight e nell’app Comandi Rapidi. Su un iPhone con tasto Azione puoi assegnarne uno al tasto in Impostazioni, in **Tasto Azione**.

## Cosa viene salvato con la nota

- il momento del salvataggio, alla fine del testo nella forma `2026-10-24 15:42 +02:00`,
- la posizione del telefono, se hai consentito all’app la localizzazione. L’app la attende al massimo 5 secondi e altrimenti salva la nota senza posizione.

optiCLOUD assegna a una nota l’ora in cui arriva. Se arriva più tardi, il momento del salvataggio resta comunque nel testo.

## Senza rete

L’app salva prima ogni nota sul telefono e la invia da lì. Senza rete resta sul telefono e parte non appena optiCLOUD è di nuovo raggiungibile. L’app riprova ogni minuto, quando torna in primo piano e dopo un accesso.

Nel tab **Live** vedi quante note sono ancora in attesa. Se il tuo accesso è scaduto, accedi di nuovo; poi le note partono. Dopo la disconnessione restano sul telefono e partono solo quando accedi di nuovo con lo stesso account.

Se optiCLOUD rifiuta una nota, per esempio perché il dispositivo non esiste più, l’app la mette da parte. Nel tab **Diagnostica** in **Note** la vedi con il messaggio di optiCLOUD e puoi inviarla di nuovo o eliminarla (vedi [Diagnostica](diagnosis.md)). L’app non elimina mai una nota da sola.

## Dopo l’invio

Una nota inviata la modifichi e la archivi in optiCLOUD. L’app non la modifica più. In optiCLOUD le note non si possono eliminare una per una; vengono eliminate insieme al loro dispositivo.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
