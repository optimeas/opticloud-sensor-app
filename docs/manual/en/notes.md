---
title: Notes
description: Write notes on the device in optiCLOUD with the optiCLOUD Sensor app, in the app or with Siri, also without a network.
sidebar_label: Notes
sidebar_position: 9
image: "/img/om_social_card.png"
keywords:
  - note
  - quick note
  - Siri
  - shortcut
last_update:
  date: 2026-10-27
  author: optiMEAS GmbH
license: CC-BY-4.0
copyright: © 2026 optiMEAS GmbH and optiMEAS Switzerland GmbH
---

# Notes

A note records what is happening right now: an observation, a fault, the start of a measurement run. optiCLOUD stores it as a note on the device this phone sends to and shows it there next to the measured values.

To write notes, you must be signed in in the app. The note belongs to your account.

## Writing a note in the app

1. On the **Live** tab, tap the **New Note** symbol at the top right.
2. Write the text. The cursor is already in the **Note** field.
3. Tap **Save**.

A title is not needed. If you leave **Title (optional)** empty, the app takes the first line of the text as the title, at most 60 characters. Below the text you see what the title will be.

Under **Details** you set **Status** and **Priority**. Unless you change them, the status is **Created** and the priority **Medium**.

## A note with Siri or a shortcut

The app offers two shortcuts:

| Shortcut | What it does |
|---|---|
| **New optiCLOUD Note** | Asks for the text and saves the note without opening the app. With Siri you dictate the text. |
| **New optiCLOUD Note in the App** | Opens the app with the form for a new note |

Say, for example, "Hey Siri, new note in optiCLOUD Sensor". Siri asks "What should the note say?", you dictate the text, and Siri tells you whether the note is already in optiCLOUD or will be sent later.

You also find both shortcuts in Spotlight and in the Shortcuts app. On an iPhone with an Action button, you can put one of them on the button in Settings under **Action Button**.

## What is saved with the note

- the moment of saving, at the end of the text in the form `2026-10-24 15:42 +02:00`,
- the position of the phone, if you have allowed the app to use location. The app waits at most 5 seconds for it and otherwise saves the note without a position.

optiCLOUD sets the time at which a note arrives. If it arrives later, the moment of saving is still in the text.

## Without a network

The app first saves every note on the phone and sends it from there. Without a network it stays on the phone and goes out as soon as optiCLOUD can be reached again. The app tries every minute, when it comes to the foreground, and after a sign-in.

On the **Live** tab you see how many notes are still waiting. If your sign-in has expired, sign in again; the notes go out afterwards. After you sign out they stay on the phone and go out only when you sign in again with the same account.

If optiCLOUD refuses a note, for example because the device no longer exists, the app sets it aside. On the **Diagnosis** tab under **Notes** you see it with the message from optiCLOUD and can send it again or delete it (see [Diagnosis](diagnosis.md)). The app never deletes a note by itself.

## After sending

You change and archive a sent note in optiCLOUD. The app no longer changes it. Single notes cannot be deleted in optiCLOUD; they are deleted with their device.

---

This documentation is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Attribution: optiMEAS GmbH and optiMEAS Switzerland GmbH.
