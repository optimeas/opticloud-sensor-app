---
title: Notizen
description: Mit der App optiCLOUD Sensor Notizen am Gerät in optiCLOUD schreiben, in der App oder mit Siri, auch ohne Netz.
sidebar_label: Notizen
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - Notiz
  - Schnellnotiz
  - Siri
  - Kurzbefehl
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Notizen

Mit einer Notiz hältst du fest, was gerade passiert: eine Beobachtung, eine Störung, den Beginn einer Messfahrt. optiCLOUD speichert sie als Notiz am Gerät, an das dieses Telefon sendet, und zeigt sie dort neben den Messwerten.

Zum Schreiben musst du in der App angemeldet sein. Die Notiz gehört zu deinem Konto.

## Notiz in der App schreiben

1. Tippe im Tab **Live** oben rechts auf das Symbol **Neue Notiz**.
2. Schreibe den Text. Der Cursor steht schon im Feld **Notiz**.
3. Tippe auf **Sichern**.

Ein Titel ist nicht nötig. Lässt du **Titel (optional)** leer, nimmt die App die erste Zeile des Texts als Titel, höchstens 60 Zeichen. Unter dem Text siehst du, wie der Titel heißen wird.

Unter **Details** stellst du **Status** und **Priorität** ein. Ohne Änderung ist der Status **Erstellt** und die Priorität **Mittel**.

## Notiz mit Siri oder einem Kurzbefehl

Die App bietet zwei Kurzbefehle:

| Kurzbefehl | Was er tut |
|---|---|
| **Neue optiCLOUD-Notiz** | Fragt nach dem Text und sichert die Notiz, ohne die App zu öffnen. Mit Siri diktierst du den Text. |
| **Neue optiCLOUD-Notiz in der App** | Öffnet die App mit dem Formular für eine neue Notiz |

Sag zum Beispiel „Hey Siri, neue Notiz in optiCLOUD Sensor“. Siri fragt „Was soll in der Notiz stehen?“, du diktierst den Text, und Siri sagt dir, ob die Notiz schon in optiCLOUD ist oder später gesendet wird.

Beide Kurzbefehle findest du auch in Spotlight und in der App Kurzbefehle. Auf einem iPhone mit Aktionstaste kannst du einen davon in den Einstellungen unter **Aktionstaste** auf die Taste legen.

## Was mit der Notiz gespeichert wird

- der Zeitpunkt des Sicherns, am Ende des Texts in der Form `2026-10-24 15:42 +02:00`,
- die Position des Telefons, wenn du der App den Standort erlaubt hast. Die App wartet höchstens 5 Sekunden darauf und sichert die Notiz sonst ohne Position.

optiCLOUD setzt für eine Notiz die Zeit, zu der sie ankommt. Kommt sie später an, steht der Zeitpunkt des Sicherns trotzdem im Text.

## Ohne Netz

Die App sichert jede Notiz zuerst auf dem Telefon und sendet sie von dort. Ohne Netz bleibt sie auf dem Telefon und geht los, sobald optiCLOUD wieder erreichbar ist. Die App versucht es jede Minute, wenn sie in den Vordergrund kommt und nach einer Anmeldung.

Im Tab **Live** siehst du, wie viele Notizen noch warten. Ist deine Anmeldung abgelaufen, melde dich wieder an; danach gehen die Notizen los. Nach dem Abmelden bleiben sie auf dem Telefon und gehen erst los, wenn du dich mit demselben Konto wieder anmeldest.

Lehnt optiCLOUD eine Notiz ab, zum Beispiel weil das Gerät nicht mehr existiert, legt die App sie zur Seite. Im Tab **Diagnose** unter **Notizen** siehst du sie mit der Meldung von optiCLOUD und kannst sie erneut senden oder löschen (siehe [Diagnose](diagnosis.md)). Die App löscht keine Notiz von sich aus.

## Nach dem Senden

Eine gesendete Notiz änderst und archivierst du in optiCLOUD. Die App ändert sie nicht mehr. Einzelne Notizen lassen sich in optiCLOUD nicht löschen; sie werden mit ihrem Gerät gelöscht.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
