---
title: Background e posizione
description: Come l’app optiCLOUD Sensor continua a inviare con lo schermo bloccato e perché per questo ha bisogno della posizione.
sidebar_label: Background e posizione
sidebar_position: 5
image: "/img/om_social_card.png"
keywords:
  - background
  - posizione
  - accesso alla posizione
  - iOS
  - batteria
last_update:
  date: 2026-10-28
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Background e posizione

iOS chiude le app in background dopo poco tempo. Un’app può continuare a funzionare in background solo se ha un motivo riconosciuto per farlo. optiCLOUD Sensor usa a questo scopo la posizione: finché l’app misura e invia la posizione, può continuare a funzionare, e con lei tutti gli altri sensori selezionati.

La posizione non è un pretesto, ma un valore misurato come qualsiasi altro. L’app ti dice apertamente a cosa le serve, e iOS ti mostra in ogni momento quando la usa.

## Cosa devi impostare

1. Seleziona il gruppo **Posizione** in **Impostazioni → Invio → Sensori** (selezionato di fabbrica).
2. Avvia l’invio. iOS chiede l’accesso alla posizione; consentilo «Mentre usi l’app».
3. Poco dopo iOS chiede una sola volta se l’app può usare la posizione «Sempre». Consentilo.

Lo stato attuale lo vedi in **Impostazioni → Invio → Accesso alla posizione**, finché la posizione è selezionata. Se hai rifiutato l’accesso, lì compare **Apri Impostazioni**. In seguito lo modifichi nell’app Impostazioni di iOS in **optiCLOUD Sensor → Posizione**; lì scegli **Sempre**.

| Accesso alla posizione | Cosa succede |
|---|---|
| **Sempre** | L’app invia anche con lo schermo bloccato e quando usi un’altra app. |
| **Mentre usi l’app** | L’app invia finché è in primo piano. |
| **Mai** | L’app non invia la posizione e invia solo finché è in primo piano. |

## Cosa vedi sul telefono

Finché l’app usa la posizione, iOS mostra una freccia nella barra di stato accanto all’ora. È voluto: così vedi sempre che l’app sta misurando. Se interrompi l’invio, la freccia scompare.

## Sulla schermata di blocco e nel Centro di Controllo

Finché l’app invia, mostra un’**attività in tempo reale** sulla schermata di blocco e nella Dynamic Island: la nuvola dell’app con lo stato, il dispositivo, da quanto tempo invia e quanti valori sono ancora in attesa. La nuvola è verde finché l’app invia, arancione finché attende una connessione e rossa quando optiCLOUD ha rifiutato il dispositivo. Con **Stop** termini l’invio senza aprire l’app.

Il controllo **Invia a optiCLOUD** avvia e interrompe l’invio dal Centro di Controllo, dalla schermata di blocco o con il tasto Azione. Aggiungilo nel Centro di Controllo con **+** → **Aggiungi un controllo**. Per avviare l’invio apre brevemente l’app, perché iOS avvia l’attività in tempo reale solo dall’app aperta.

iOS termina un’attività in tempo reale dopo otto ore. L’invio continua; la prossima volta che apri l’app, ne mostra una nuova.

## Terminare l’invio in background

Interrompi l’invio nel tab **Live** con **Interrompi invio**, con **Stop** nell’attività in tempo reale o con il controllo **Invia a optiCLOUD**.

Chiudere l’app scorrendola via dalla vista delle app **non** basta. L’invio è un’impostazione che sopravvive al riavvio dell’app: quando l’app si riavvia, continua a inviare. È intenzionale, perché un punto di misura non deve venire a mancare solo perché nel frattempo l’app è stata chiusa.

## Cosa manca in background

- **Livello sonoro:** iOS limita il microfono in background. L’app lo misura solo finché è aperta.
- **Vista live:** i valori nel tab **Live** si aggiornano solo quando riapri l’app. In optiCLOUD arrivano comunque in modo continuo.

## Batteria

La misurazione della posizione in background consuma energia. Quanta dipende dal telefono, dalla ricezione e dalla frequenza di invio. Per misurazioni lunghe è utile un caricabatterie. Il livello della batteria puoi seguirlo tu stesso in optiCLOUD con il gruppo **Dispositivo**.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
