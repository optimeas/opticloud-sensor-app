---
title: Perché open source
description: Perché optiMEAS rende pubblici l’app optiCLOUD Sensor e la sua interfaccia.
sidebar_label: Perché open source
sidebar_position: 1
image: "/img/om_social_card.png"
keywords:
  - open source
  - MIT
  - trasparenza
  - optiCLOUD
  - interfaccia
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Perché open source

optiCLOUD Sensor è open source. Il codice sorgente completo di entrambe le app, la specifica e questa documentazione sono pubblici su GitHub: [github.com/optimeas/opticloud-sensor-app](https://github.com/optimeas/opticloud-sensor-app). Il codice è distribuito con licenza MIT, la documentazione con licenza CC BY 4.0.

I motivi vanno oltre questa singola app.

## Vedi cosa invia l’app

Un’app che misura posizione, movimento e rumori merita diffidenza finché non si può verificare che cosa ne fa. Con optiCLOUD Sensor puoi verificarlo. Ogni valore che l’app invia è descritto nella specifica, e il codice che lo misura e lo invia è leggibile da chiunque. L’app invia solo al dispositivo optiCLOUD che hai scelto tu e a nessun altro servizio. Che cosa significa nel dettaglio è descritto in [Privacy](privacy.md).

Fa parte anche l’onestà: dove l’app stima, lo dice. Il livello sonoro è una stima e non una misura tarata, il volume dati è un calcolo e non la fattura del tuo operatore di telefonia mobile.

## Un esempio di collegamento a optiCLOUD

L’app è anche un esempio completo e funzionante di come un dispositivo comunica con optiCLOUD:

- accedere tramite l’interfaccia REST e creare o scegliere un dispositivo,
- inviare telemetria e attributi client tramite MQTT,
- ricevere Shared Attributes e far gestire le impostazioni da optiCLOUD,
- accettare comandi (RPC) e rispondere,
- memorizzare temporaneamente i valori misurati senza rete e consegnarli in seguito nell’ordine giusto.

Chi vuole collegare a optiCLOUD un proprio dispositivo, un gateway o un software non trova qui un frammento, ma un insieme completo che funziona nell’uso quotidiano – in Swift per iOS e presto anche in Kotlin per Android.

## Una specifica aperta

Le app seguono una specifica comune nella cartella [`docs/spec`](https://github.com/optimeas/opticloud-sensor-app/tree/main/docs/spec). Descrive accesso, connessione, messaggi, sensori e coda offline con parole proprie. I vettori di test stabiliscono come i valori vengono arrotondati, selezionati, riepilogati e impacchettati. Entrambe le app devono superare ogni vettore. Così iOS e Android restano uguali, e chi scrive una terza implementazione può verificarla con gli stessi vettori.

## Conoscici

optiMEAS è sinonimo di competenza, parità, apertura, onestà e conoscenza. Invece di limitarci ad affermarlo, mostriamo il nostro lavoro: come registriamo i requisiti, motiviamo le decisioni, testiamo e documentiamo. Puoi farti un’idea tua prima di lavorare con noi.

Condividiamo la conoscenza perché così cresce. Quello che abbiamo imparato costruendo l’app su sensori, funzionamento in background e MQTT sugli smartphone si trova nella specifica e nel codice – anche gli ostacoli.

## Partecipa

Errori, domande e proposte sono benvenuti su GitHub, come issue o come pull request. Accogliamo i contributi alla pari, che vengano da un cliente, da uno studente o da un’altra azienda. Come è organizzato il lavoro nel repository è descritto nel [README](https://github.com/optimeas/opticloud-sensor-app#readme).

## Non il primo progetto di questo tipo

optiCLOUD Sensor non è il nostro primo progetto aperto. Anche l’Open Streaming Format (OSF), il nostro formato di file per dati di misura e di processo, ha una specifica aperta ed è pubblicato su GitHub: [github.com/optimeas/osf](https://github.com/optimeas/osf). La sua documentazione si trova in Formati di dati nella [documentazione optiMEAS](https://docs.optimeas.com). Entrambi i progetti seguono la stessa idea: ciò che rendiamo pubblico, chiunque può verificarlo, usarlo e migliorarlo.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
