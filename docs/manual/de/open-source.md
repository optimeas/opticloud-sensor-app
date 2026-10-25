---
title: Warum Open Source
description: Warum optiMEAS die App optiCLOUD Sensor und ihre Schnittstelle offenlegt.
sidebar_label: Warum Open Source
sidebar_position: 1
image: "/img/om_social_card.png"
keywords:
  - Open Source
  - MIT
  - Transparenz
  - optiCLOUD
  - Schnittstelle
last_update:
  date: 2026-10-25
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH und optiMEAS Switzerland GmbH
---

# Warum Open Source

optiCLOUD Sensor ist Open Source. Der vollständige Quellcode beider Apps, die Spezifikation und diese Dokumentation liegen öffentlich auf GitHub: [github.com/optimeas/opticloud-sensor-app](https://github.com/optimeas/opticloud-sensor-app). Der Code steht unter der MIT-Lizenz, die Dokumentation unter CC BY 4.0.

Das hat Gründe, die über diese eine App hinausgehen.

## Du siehst, was die App sendet

Eine App, die Standort, Bewegung und Geräusche misst, verdient Misstrauen, solange man nicht nachsehen kann, was sie damit macht. Bei optiCLOUD Sensor kannst du nachsehen. Jeder Wert, den die App sendet, ist in der Spezifikation beschrieben, und der Code, der ihn misst und sendet, ist für jeden lesbar. Die App sendet nur an das optiCLOUD-Gerät, das du selbst gewählt hast, und an keinen anderen Dienst. Was das im Einzelnen heißt, steht unter [Datenschutz](privacy.md).

Ehrlichkeit gehört dazu: Wo die App schätzt, sagt sie es. Der Schallpegel ist ein Schätzwert und keine geeichte Messung, das Datenvolumen eine Rechnung und keine Abrechnung deines Mobilfunkanbieters.

## Ein Beispiel für die Anbindung an optiCLOUD

Die App ist auch ein vollständiges, lauffähiges Beispiel dafür, wie ein Gerät mit optiCLOUD spricht:

- Anmelden über die REST-Schnittstelle und ein Gerät anlegen oder wählen,
- Telemetrie und Client-Attribute über MQTT senden,
- Shared Attributes empfangen und Einstellungen von optiCLOUD verwalten lassen,
- Befehle (RPC) annehmen und beantworten,
- Messwerte ohne Netz zwischenspeichern und in der richtigen Reihenfolge nachliefern.

Wer selbst ein Gerät, ein Gateway oder eine Software an optiCLOUD anbinden will, findet hier keinen Ausschnitt, sondern ein Ganzes, das im Alltag läuft – in Swift für iOS und bald auch in Kotlin für Android.

## Eine offene Spezifikation

Die Apps folgen einer gemeinsamen Spezifikation im Ordner [`docs/spec`](https://github.com/optimeas/opticloud-sensor-app/tree/main/docs/spec). Sie beschreibt Anmeldung, Verbindung, Nachrichten, Sensoren und die Offline-Warteschlange in eigenen Worten. Testvektoren legen fest, wie Werte gerundet, ausgewählt, zusammengefasst und verpackt werden. Beide Apps müssen jeden Vektor bestehen. So bleiben iOS und Android gleich, und wer eine dritte Umsetzung schreibt, kann sie gegen dieselben Vektoren prüfen.

## Lern uns kennen

optiMEAS steht für Kompetenz, Augenhöhe, Offenheit, Ehrlichkeit und Wissen. Statt das nur zu behaupten, zeigen wir unsere Arbeit: wie wir Anforderungen festhalten, Entscheidungen begründen, testen und dokumentieren. Du kannst dir ein eigenes Bild machen, bevor du mit uns arbeitest.

Wissen teilen wir, weil es dadurch mehr wird. Was wir beim Bau der App über Sensoren, Hintergrundbetrieb und MQTT auf Smartphones gelernt haben, steht in der Spezifikation und im Code – auch die Stolpersteine.

## Mach mit

Fehler, Fragen und Vorschläge sind auf GitHub willkommen, als Issue oder als Pull Request. Wir begegnen Beiträgen auf Augenhöhe, egal ob sie von einem Kunden, einem Studenten oder einem anderen Unternehmen kommen. Wie die Arbeit im Repository organisiert ist, steht in der [README](https://github.com/optimeas/opticloud-sensor-app#readme).

## Nicht das erste Projekt dieser Art

optiCLOUD Sensor ist nicht unser erstes offenes Projekt. Das Open Streaming Format (OSF), unser Dateiformat für Mess- und Prozessdaten, ist ebenfalls offen spezifiziert und auf GitHub veröffentlicht: [github.com/optimeas/osf](https://github.com/optimeas/osf). Seine Dokumentation steht unter Datenformate in der [optiMEAS-Dokumentation](https://docs.optimeas.com). Beide Projekte folgen derselben Idee: Was wir offenlegen, kann jeder prüfen, nutzen und verbessern.

---

Diese Dokumentation steht unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.de). Namensnennung: optiMEAS GmbH und optiMEAS Switzerland GmbH.
