---
title: Privacy
description: Quali dati raccoglie l’app optiCLOUD Sensor, dove vanno e che cosa resta sul telefono.
sidebar_label: Privacy
sidebar_position: 10
image: "/img/om_social_card.png"
keywords:
  - privacy
  - posizione
  - microfono
  - Access Token
  - portachiavi
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Privacy

L’app misura cose che possono rivelare molto di te: dove sei, come ti muovi, quanto è rumoroso intorno a te. Per questo qui diciamo esattamente che cosa ne fa. Puoi verificarlo nel [codice sorgente](https://github.com/optimeas/opticloud-sensor-app).

## L’essenziale

- L’app invia solo al server optiCLOUD che indichi all’accesso, e lì solo al dispositivo che hai scelto.
- Invia solo finché hai attivato l’invio, e solo i sensori che hai selezionato.
- Non contiene pubblicità né servizi di analisi o di tracciamento e non comunica con nessun altro servizio.
- Non registra audio. Del microfono usa solo il volume.
- Non salva la tua password.

## Cosa va a optiCLOUD

| Dati | Quando |
|---|---|
| I valori dei sensori selezionati, con timestamp | Finché l’invio è attivo, e una volta con il comando `sendNow` |
| Versione dell’app, sistema operativo, modello del telefono, sensori disponibili e selezionati, frequenza di invio, se è in corso l’invio | Dopo ogni connessione e a ogni modifica |
| Risposte ai comandi | Quando optiCLOUD invia un comando |
| Valori che invii a mano nel tab Diagnostica | Quando li invii |
| Indirizzo e-mail e password | Solo all’accesso, per autenticarti |

In optiCLOUD questi dati appartengono al dispositivo nel tuo tenant. Chi può vederli lì lo stabiliscono le autorizzazioni nel tuo tenant. Tienilo presente, soprattutto per la posizione: tutti coloro che possono vedere il dispositivo in optiCLOUD vedono anche dove è stato il telefono.

La connessione è crittografata (TLS).

## Cosa resta sul telefono

- **Nel portachiavi di iOS:** l’Access Token del dispositivo, la sessione del tuo accesso e un identificativo dell’installazione con cui l’app associa il dispositivo a questo telefono.
- **Nei dati dell’app:** le impostazioni, la coda offline con i valori non ancora inviati, i contatori del volume dati e il registro nel tab Diagnostica. Il registro lascia il telefono solo se lo esporti tu stesso.

## Autorizzazioni

| Autorizzazione | A cosa serve |
|---|---|
| Posizione | Il gruppo Posizione e, con «Sempre», l’invio in background (vedi [Background e posizione](background.md)) |
| Movimento e fitness | Il gruppo Attività (passi e tipo di attività) e la pressione atmosferica |
| Microfono | Il gruppo Suono: solo il volume |

iOS chiede un’autorizzazione solo quando hai selezionato un sensore che ne ha bisogno e avvii l’invio. Puoi revocare ogni autorizzazione in qualsiasi momento nelle Impostazioni di iOS. L’app continua allora a inviare gli altri valori.

## Responsabilità

Per i dati in optiCLOUD valgono gli accordi tra te o la tua azienda e il gestore del server optiCLOUD. Per domande sull’app puoi contattarci tramite il [sito web di optiMEAS](https://optimeas.com) o su [GitHub](https://github.com/optimeas/opticloud-sensor-app/issues).

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
