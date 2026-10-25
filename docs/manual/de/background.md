---
title: Hintergrund und Standort
description: Wie die App optiCLOUD Sensor bei gesperrtem Bildschirm weitersendet und warum sie dafür den Standort braucht.
sidebar_label: Hintergrund und Standort
sidebar_position: 5
image: "/img/om_social_card.png"
keywords:
  - Hintergrund
  - Standort
  - Standortfreigabe
  - iOS
  - Akku
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Hintergrund und Standort

iOS beendet Apps im Hintergrund nach kurzer Zeit. Eine App darf nur dann im Hintergrund weiterlaufen, wenn sie dafür einen anerkannten Grund hat. optiCLOUD Sensor nutzt dafür den Standort: Solange die App den Standort misst und sendet, darf sie weiterlaufen, und mit ihr alle anderen gewählten Sensoren.

Der Standort ist dabei kein Vorwand, sondern ein Messwert wie jeder andere. Die App sagt dir offen, wofür sie ihn braucht, und iOS zeigt dir jederzeit, wann sie ihn nutzt.

## Was du einstellen musst

1. Wähle die Gruppe **Standort** unter **Einstellungen → Senden → Sensoren** (ab Werk gewählt).
2. Starte das Senden. iOS fragt nach dem Standort; erlaube ihn „Beim Verwenden der App“.
3. Kurz danach fragt iOS ein Mal, ob die App den Standort „Immer“ nutzen darf. Erlaube das.

Den aktuellen Stand siehst du unter **Einstellungen → Senden → Standortzugriff**, solange der Standort gewählt ist. Hast du den Zugriff abgelehnt, steht dort **Einstellungen öffnen**. Später änderst du ihn in der iOS-App Einstellungen unter **optiCLOUD Sensor → Standort**; wähle dort **Immer**.

| Standortzugriff | Was passiert |
|---|---|
| **Immer** | Die App sendet auch bei gesperrtem Bildschirm und wenn du eine andere App benutzt. |
| **Beim Verwenden der App** | Die App sendet, solange sie im Vordergrund ist. |
| **Nie** | Die App sendet keinen Standort und nur, solange sie im Vordergrund ist. |

## Was du auf dem Telefon siehst

Solange die App den Standort nutzt, zeigt iOS einen Pfeil in der Statusleiste neben der Uhrzeit. Das ist gewollt: So siehst du immer, dass die App misst. Stoppst du das Senden, verschwindet der Pfeil.

## Das Senden im Hintergrund beenden

Stoppe das Senden im Tab **Live** mit **Senden stoppen**.

Die App in der App-Übersicht wegzuwischen reicht **nicht**. Das Senden ist eine Einstellung, die einen Neustart der App übersteht: Startet die App wieder, sendet sie weiter. Das ist Absicht, denn ein Messpunkt soll nicht ausfallen, nur weil die App zwischendurch beendet wurde.

## Was im Hintergrund fehlt

- **Schallpegel:** iOS schränkt das Mikrofon im Hintergrund ein. Die App misst ihn nur, solange sie geöffnet ist.
- **Live-Ansicht:** Die Werte im Tab **Live** aktualisieren sich erst, wenn du die App wieder öffnest. In optiCLOUD kommen sie trotzdem laufend an.

## Akku

Die Standortmessung im Hintergrund kostet Strom. Wie viel, hängt vom Telefon, vom Empfang und von der Senderate ab. Für lange Messungen hilft ein Ladegerät. Den Akkustand kannst du mit der Gruppe **Gerät** selbst in optiCLOUD verfolgen.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
