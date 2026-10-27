---
title: Erste Schritte
description: Anmelden, ein Gerät wählen und das erste Mal Sensorwerte an optiCLOUD senden.
sidebar_label: Erste Schritte
sidebar_position: 2
image: "/img/om_social_card.png"
keywords:
  - Anmeldung
  - Tenant
  - Projekt
  - Gerät
  - Access Token
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Erste Schritte

Nach dem ersten Start zeigt die App „Kein Gerät“. Bevor sie senden kann, meldest du dich bei optiCLOUD an und wählst das Gerät, an das dieses Telefon sendet. Das dauert etwa eine Minute.

## Anmelden

1. Tippe auf **Anmelden**.
2. Unter **optiCLOUD** steht die Adresse der optiCLOUD-Webanwendung, voreingestellt `https://dashboard.opticloud.io`. Ändere sie nur, wenn du einen anderen optiCLOUD-Server nutzt.
3. Gib die E-Mail-Adresse und das Passwort deines persönlichen optiCLOUD-Kontos ein und tippe auf **Anmelden**.
4. Hast du Zugang zu mehreren Tenants, wählst du einen aus. Mit nur einem Tenant überspringt die App diesen Schritt.
5. Verlangt der Tenant einen Code per E-Mail, gib ihn ein und tippe auf **Bestätigen**. Mit **Neuen Code senden** forderst du einen neuen an.
6. Wähle das Projekt.

Die App speichert dein Passwort nicht. Sie braucht es nur für die Anmeldung.

## Gerät wählen

Die App sendet an ein Gerät in optiCLOUD, so wie jede andere Hardware auch. Die Liste zeigt nur Geräte vom Typ „optiCLOUD Sensor App“ im gewählten Projekt.

- **Vorhandenes Gerät:** Tippe auf das Gerät.
- **Neues Gerät:** Tippe auf **Neues Gerät**, gib einen Namen ein und tippe auf **Erstellen**. Der Name muss im Tenant eindeutig sein, zum Beispiel „iPhone Anna“.

Die App bindet das Gerät dann an dieses Telefon und liest sein Access Token. Mit dem Access Token meldet sie sich später als Gerät bei optiCLOUD an.

Ein Gerät sendet immer nur von einem Telefon aus. Ist das gewählte Gerät schon an ein anderes Telefon gebunden, fragt die App, ob du es übernehmen willst. Wenn du es übernimmst, hört das andere Telefon auf, an dieses Gerät zu senden.

Für diese Schritte brauchst du in optiCLOUD das Recht, Geräte zu lesen, anzulegen und ihre Attribute zu schreiben. Fehlt ein Recht, sagt die App, welches.

## Das erste Mal senden

1. Wechsle zum Tab **Live**.
2. Tippe auf **Senden starten**. Die App verbindet sich mit optiCLOUD und beginnt zu senden.
3. Beim ersten Mal fragt iOS nach den Erlaubnissen, die die gewählten Sensoren brauchen, zum Beispiel für den Standort. Für den Hintergrundbetrieb erlaubst du den Standort zuerst „Beim Verwenden der App“; die App fragt danach einmal nach „Immer“ (siehe [Hintergrund und Standort](background.md)).

Ab jetzt zeigt der Tab **Live** die gemessenen Werte, und in optiCLOUD kommen sie als Telemetrie des Geräts an. Ab Werk sendet die App die Werte der Gruppen Gerät und Standort alle 2 Sekunden, und zwar nur dann, wenn sich ein Wert geändert hat. Wie du das änderst, steht unter [Senden](sending.md) und [Sensoren](sensors.md).

Mit **Senden stoppen** hörst du auf zu senden.

## Die drei Tabs

| Tab | Inhalt |
|---|---|
| **Live** | Senden starten und stoppen, die aktuellen Werte |
| **Favoriten** | Seiten von optiCLOUD in Safari öffnen (siehe [Favoriten](favorites.md)) |
| **Diagnose** | Protokoll, Offline-Warteschlange, Testwerte senden (siehe [Diagnose](diagnosis.md)) |
| **Einstellungen** | Gerät, Verbindung, Senden, Sensoren, Datenvolumen, Konto, Über die App |

## Abmelden

Unter **Einstellungen → Konto** meldest du dich ab. Das Abmelden beendet das Senden nicht: Das Telefon sendet mit dem Access Token des Geräts weiter, bis du das Senden stoppst. Erst wenn du ein anderes Gerät wählen willst, musst du dich wieder anmelden.

## Ein anderes Gerät wählen

Unter **Einstellungen → Gerät** tippst du auf **Anderes Gerät wählen**. Liegen noch nicht ausgelieferte Werte in der Offline-Warteschlange, sagt die App, wie viele es sind. Sie gehören zum bisherigen Gerät und werden verworfen, wenn du ein anderes wählst.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
