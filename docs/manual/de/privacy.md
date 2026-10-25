---
title: Datenschutz
description: Welche Daten die App optiCLOUD Sensor erhebt, wohin sie gehen und was auf dem Telefon bleibt.
sidebar_label: Datenschutz
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - Datenschutz
  - Standort
  - Mikrofon
  - Access Token
  - Schlüsselbund
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Datenschutz

Die App misst Dinge, die viel über dich verraten können: wo du bist, wie du dich bewegst, wie laut es um dich herum ist. Deshalb sagen wir hier genau, was sie damit tut. Prüfen kannst du es im [Quellcode](https://github.com/optimeas/opticloud-sensor-app).

## Das Wichtigste

- Die App sendet nur an den optiCLOUD-Server, den du bei der Anmeldung angibst, und dort nur an das Gerät, das du gewählt hast.
- Sie sendet nur, solange du das Senden eingeschaltet hast, und nur die Sensoren, die du gewählt hast.
- Sie enthält keine Werbung, keine Analyse- oder Tracking-Dienste und spricht mit keinem anderen Dienst.
- Sie nimmt keinen Ton auf. Vom Mikrofon nutzt sie nur die Lautstärke.
- Sie speichert dein Passwort nicht.

## Was an optiCLOUD geht

| Daten | Wann |
|---|---|
| Die Werte der gewählten Sensoren, mit Zeitstempel | Solange das Senden eingeschaltet ist, und einmal auf den Befehl `sendNow` |
| App-Version, Betriebssystem, Modell des Telefons, verfügbare und gewählte Sensoren, Senderate, ob gesendet wird | Nach jedem Verbinden und bei Änderungen |
| Antworten auf Befehle | Wenn optiCLOUD einen Befehl schickt |
| Werte, die du im Tab Diagnose von Hand sendest | Wenn du sie sendest |
| E-Mail-Adresse und Passwort | Nur bei der Anmeldung, um dich anzumelden |

In optiCLOUD gehören diese Daten zum Gerät in deinem Tenant. Wer sie dort sehen kann, regeln die Rechte in deinem Tenant. Denk daran, besonders beim Standort: Alle, die das Gerät in optiCLOUD sehen dürfen, sehen auch, wo das Telefon war.

Die Verbindung ist verschlüsselt (TLS).

## Was auf dem Telefon bleibt

- **Im Schlüsselbund von iOS:** das Access Token des Geräts, die Sitzung deiner Anmeldung und eine Kennung der Installation, mit der die App das Gerät an dieses Telefon bindet.
- **In den Daten der App:** die Einstellungen, die Offline-Warteschlange mit noch nicht gesendeten Werten und die Zähler für das Datenvolumen.
- **Nur im Speicher:** das Protokoll im Tab Diagnose. Es verlässt das Telefon nur, wenn du es selbst exportierst.

## Erlaubnisse

| Erlaubnis | Wofür |
|---|---|
| Standort | Die Gruppe Standort, und mit „Immer“ das Senden im Hintergrund (siehe [Hintergrund und Standort](background.md)) |
| Bewegung & Fitness | Die Gruppe Aktivität (Schritte und Art der Aktivität) und den Luftdruck |
| Mikrofon | Die Gruppe Schall: nur die Lautstärke |

iOS fragt nach einer Erlaubnis erst, wenn du einen Sensor gewählt hast, der sie braucht, und das Senden startest. Du kannst jede Erlaubnis jederzeit in den iOS-Einstellungen entziehen. Die App sendet dann die übrigen Werte weiter.

## Verantwortung

Für die Daten in optiCLOUD gelten die Vereinbarungen zwischen dir oder deinem Unternehmen und dem Betreiber des optiCLOUD-Servers. Für Fragen zur App erreichst du uns über die [optiMEAS-Website](https://optimeas.com) oder auf [GitHub](https://github.com/optimeas/opticloud-sensor-app/issues).

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
