---
title: Diagnose
description: Protokoll, Offline-Warteschlange und Testwerte im Tab Diagnose der App optiCLOUD Sensor, und wie du das Protokoll exportierst.
sidebar_label: Diagnose
sidebar_position: 8
image: "/img/om_social_card.png"
keywords:
  - Diagnose
  - Protokoll
  - Support
  - Offline-Warteschlange
last_update:
  date: 2026-10-26
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Diagnose

Der Tab **Diagnose** zeigt, was zwischen dem Telefon und optiCLOUD passiert. Er hilft dir, eine Anbindung zu prüfen, und uns, dir bei einem Problem zu helfen.

## Wert senden

Hier sendest du einen einzelnen Wert von Hand, um zum Beispiel ein Dashboard oder eine Alarmregel zu testen.

1. Gib einen **Schlüssel** ein, in lowerCamelCase, zum Beispiel `testValue`.
2. Wähle den **Typ**: Zahl, Text oder Ja/Nein.
3. Gib den **Wert** ein.
4. Tippe auf **Als Telemetrie senden** oder **Als Client-Attribut senden**.

Telemetrie geht wie jeder Messwert durch die Offline-Warteschlange und kommt auch an, wenn die Verbindung gerade fehlt. Ein Client-Attribut braucht eine bestehende Verbindung.

## Offline-Warteschlange

| Zeile | Bedeutung |
|---|---|
| **Proben** | Wie viele Proben auf die Auslieferung warten |
| **Größe** | Wie viel Platz sie belegen, höchstens 50 MB |
| **Älteste** | Der Zeitstempel der ältesten wartenden Probe |
| **Verworfen** | Wie viele Proben die App verworfen hat, weil die Warteschlange voll war oder optiCLOUD eine Nachricht wiederholt nicht angenommen hat |
| **Verworfener Zeitraum** | Der Zeitraum, aus dem die verworfenen Proben stammen |

Mit **Zähler „Verworfen“ zurücksetzen** setzt du den Zähler auf null. Wie die Warteschlange arbeitet, steht unter [Senden](sending.md).

## Protokoll

Das Protokoll zeigt, das Neueste zuerst:

- Befehle aus optiCLOUD mit ihren Parametern und der Antwort der App,
- Änderungen der Shared Attributes, auch von Schlüsseln, die die App nicht verwendet; statt der Kennung der Installation in `sensorAppInstallation` steht dort nur, ob die Bindung zu diesem Telefon gehört,
- Werte, die die App nicht verwenden konnte, zum Beispiel eine ungültige Senderate,
- Änderungen der Verbindung mit ihrem Grund, zum Beispiel „Kein Netzwerk“,
- Start und Ende der Standortmessung und Probleme damit,
- jeden Start der App, mit dem Hinweis, wenn iOS sie im Hintergrund gestartet hat,
- wann die App in den Hintergrund und wieder in den Vordergrund ging, und **Pausiert**, wenn iOS die App angehalten hat, mit der Dauer der Pause,
- Werte, die du von Hand gesendet hast.

Das Protokoll liegt in den Daten der App auf dem Telefon und hält die letzten 1000 Einträge, auch über einen Neustart der App hinweg. Einträge von früheren Tagen zeigen das Datum. Mit **Löschen** leerst du es.

## Protokoll exportieren

Tippe oben rechts auf das Teilen-Symbol (ein Quadrat mit einem Pfeil nach oben). VoiceOver nennt es **Protokoll exportieren**. Die App erstellt einen Text, den du per Mail, Nachricht oder in eine Datei weitergeben kannst. Er enthält:

- Version der App, Modell des Telefons und iOS-Version,
- Gerät, Projekt, Tenant und Server,
- den Status der Verbindung und des Sendens, Senderate und Sendemodus,
- die gewählten Sensoren,
- den Stand der Offline-Warteschlange,
- alle Einträge des Protokolls.

Der Text enthält weder dein Passwort noch das Access Token des Geräts. Bevor du ihn weitergibst, kannst du ihn lesen: Er ist nur Text.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
