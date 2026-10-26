---
title: Diagnostica
description: Registro, coda offline e valori di prova nel tab Diagnostica dell’app optiCLOUD Sensor, e come esportare il registro.
sidebar_label: Diagnostica
sidebar_position: 8
image: "/img/om_social_card.png"
keywords:
  - diagnostica
  - registro
  - supporto
  - coda offline
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Diagnostica

Il tab **Diagnostica** mostra che cosa succede tra il telefono e optiCLOUD. Aiuta te a verificare un collegamento e noi ad aiutarti in caso di problemi.

## Invia un valore

Qui invii a mano un singolo valore, per esempio per provare un Dashboard o una regola di allarme.

1. Inserisci una **Chiave**, in lowerCamelCase, per esempio `testValue`.
2. Scegli il **Tipo**: Numero, Testo o Sì/No.
3. Inserisci il **Valore**.
4. Tocca **Invia come telemetria** o **Invia come attributo client**.

La telemetria passa, come ogni valore misurato, dalla coda offline e arriva anche se in quel momento manca la connessione. Un attributo client richiede una connessione attiva.

## Coda offline

| Riga | Significato |
|---|---|
| **Campioni** | Quanti campioni attendono la consegna |
| **Dimensione** | Quanto spazio occupano, al massimo 50 MB |
| **Più vecchio** | Il timestamp del campione in attesa più vecchio |
| **Scartati** | Quanti campioni l’app ha scartato perché la coda era piena o perché optiCLOUD ha rifiutato ripetutamente un messaggio |
| **Intervallo scartato** | Il periodo da cui provengono i campioni scartati |

Con **Azzera il contatore degli scartati** riporti il contatore a zero. Come funziona la coda è descritto in [Invio](sending.md).

## Registro

Il registro mostra, dal più recente:

- i comandi da optiCLOUD con i loro parametri e la risposta dell’app,
- le modifiche degli Shared Attributes, anche di chiavi che l’app non usa,
- i valori che l’app non ha potuto usare, per esempio una frequenza di invio non valida,
- le modifiche della connessione con il loro motivo, per esempio «Nessuna rete»,
- l’avvio e l’arresto della localizzazione e i relativi problemi,
- quando l’app è passata in background e di nuovo in primo piano, e **In pausa** quando iOS ha sospeso l’app, con la durata della pausa,
- i valori che hai inviato a mano.

Il registro si trova solo nella memoria del telefono, conserva le ultime 200 voci e ricomincia da capo a ogni avvio dell’app. Con **Cancella** lo svuoti.

## Esporta registro

Tocca il simbolo di condivisione in alto a destra (un quadrato con una freccia verso l’alto). VoiceOver lo chiama **Esporta registro**. L’app crea un testo che puoi condividere via e-mail, messaggio o in un file. Contiene:

- versione dell’app, modello del telefono e versione di iOS,
- dispositivo, progetto, tenant e server,
- lo stato della connessione e dell’invio, la frequenza di invio e la modalità di invio,
- i sensori selezionati,
- lo stato della coda offline,
- tutte le voci del registro.

Il testo non contiene né la tua password né l’Access Token del dispositivo. Prima di condividerlo puoi leggerlo: è solo testo.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
