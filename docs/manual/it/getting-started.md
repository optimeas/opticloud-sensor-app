---
title: Primi passi
description: Accedere, scegliere un dispositivo e inviare per la prima volta valori dei sensori a optiCLOUD.
sidebar_label: Primi passi
sidebar_position: 2
image: "/img/om_social_card.png"
keywords:
  - accesso
  - Tenant
  - progetto
  - dispositivo
  - Access Token
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Primi passi

Al primo avvio l’app mostra «Nessun dispositivo». Prima che possa inviare, accedi a optiCLOUD e scegli il dispositivo a cui questo telefono invia i dati. Ci vuole circa un minuto.

## Accedere

1. Tocca **Accedi**.
2. In **optiCLOUD** c’è l’indirizzo dell’applicazione web optiCLOUD, preimpostato su `https://dashboard.opticloud.io`. Modificalo solo se usi un altro server optiCLOUD.
3. Inserisci l’indirizzo e-mail e la password del tuo account optiCLOUD personale e tocca **Accedi**.
4. Se hai accesso a più tenant, ne scegli uno. Con un solo tenant l’app salta questo passaggio.
5. Se il tenant richiede un codice via e-mail, inseriscilo e tocca **Conferma**. Con **Invia un nuovo codice** ne richiedi uno nuovo.
6. Scegli il progetto.

L’app non salva la tua password. Le serve solo per l’accesso.

## Scegliere il dispositivo

L’app invia i dati a un dispositivo in optiCLOUD, proprio come qualsiasi altro hardware. L’elenco mostra solo i dispositivi di tipo «optiCLOUD Sensor App» nel progetto selezionato.

- **Dispositivo esistente:** tocca il dispositivo.
- **Nuovo dispositivo:** tocca **Nuovo dispositivo**, inserisci un nome e tocca **Crea**. Il nome deve essere univoco nel tenant, per esempio «iPhone Anna».

L’app associa quindi il dispositivo a questo telefono e ne legge l’Access Token. Con l’Access Token in seguito si autentica in optiCLOUD come dispositivo.

Un dispositivo invia sempre da un solo telefono. Se il dispositivo scelto è già associato a un altro telefono, l’app ti chiede se vuoi prenderlo in carico. Se lo prendi in carico, l’altro telefono smette di inviare a questo dispositivo.

Per questi passaggi ti serve in optiCLOUD l’autorizzazione a leggere e creare dispositivi e a scriverne gli attributi. Se manca un’autorizzazione, l’app ti dice quale.

## Inviare per la prima volta

1. Passa al tab **Live**.
2. Tocca **Avvia invio**. L’app si connette a optiCLOUD e comincia a inviare.
3. La prima volta iOS chiede le autorizzazioni di cui hanno bisogno i sensori selezionati, per esempio per la posizione. Per il funzionamento in background consenti prima la posizione «Mentre usi l’app»; poi l’app chiede una volta «Sempre» (vedi [Background e posizione](background.md)).

Da questo momento il tab **Live** mostra i valori misurati, e in optiCLOUD arrivano come telemetria del dispositivo. Di fabbrica l’app invia i valori dei gruppi Dispositivo e Posizione ogni 2 secondi, e solo quando un valore è cambiato. Come modificarlo è descritto in [Invio](sending.md) e [Sensori](sensors.md).

Con **Interrompi invio** smetti di inviare.

## I tre tab

| Tab | Contenuto |
|---|---|
| **Live** | Avviare e interrompere l’invio, i valori attuali |
| **Diagnostica** | Registro, coda offline, invio di valori di prova (vedi [Diagnostica](diagnosis.md)) |
| **Impostazioni** | Dispositivo, Connessione, Invio, Sensori, Volume dati, Account, Informazioni |

## Uscire

In **Impostazioni → Account** esci dal tuo account. Uscire non interrompe l’invio: il telefono continua a inviare con l’Access Token del dispositivo finché non interrompi l’invio. Devi accedere di nuovo solo quando vuoi scegliere un altro dispositivo.

## Scegliere un altro dispositivo

In **Impostazioni → Dispositivo** tocca **Scegli un altro dispositivo**. Se nella coda offline ci sono ancora valori non consegnati, l’app ti dice quanti sono. Appartengono al dispositivo precedente e vengono scartati se ne scegli un altro.

---

Questa documentazione è distribuita con licenza [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it). Attribuzione: optiMEAS GmbH e optiMEAS Switzerland GmbH.
