# Journal

**Status: draft.** Writing notes was tested against an optiCLOUD test server on 2026-10-24. The quick note, the title taken from the text, and the queue of entries are not yet tested against an optiCLOUD server.

A journal entry is a text the user writes in the app. optiCLOUD stores it as a note on the device the phone sends to. A note always belongs to the signed-in user (see [sign-in.md](sign-in.md)).

## Entry

The user fills in:

| Field | Required | Default | Values |
| --- | --- | --- | --- |
| Title | no | empty | Text |
| Text | yes | empty | Text |
| Status | yes | Created | Created, Archived |
| Priority | yes | Medium | Low, Medium, High |

- The app saves an entry only when the text has a character other than white space.
- Without a title the app takes the title from the text, see [Title from the text](#title-from-the-text).
- The moment of saving is the time stamp of the entry.
- If the user has allowed location, the app adds the position at the moment of saving. It waits at most 5 seconds for a position and saves the entry without one if none comes.
- Saving needs a signed-in user. The entry belongs to this user and is delivered only through a session of the same user (see [offline-queue.md](offline-queue.md#journal-entries)).
- Saving does not need a network. The app puts the entry into the queue of journal entries and delivers it from there.

### Title from the text

The title is the title the user typed, without white space at its start and end. If that is empty, the app takes the first line of the text that has a character other than white space, without white space at its start and end. If this line is longer than 60 characters, the app keeps the first 59 characters and adds `…` (U+2026). Characters are counted as the user sees them, as extended grapheme clusters. The test vectors are in [`journal-title.json`](vectors/journal-title.json).

## Quick note

A quick note is a journal entry the user writes in a few seconds, without leaving what they are doing.

- **In the app.** The live view has a button that opens a short form. The cursor is in the text. Title and the section "Details" with status and priority are optional; "Details" is closed and holds the defaults.
- **App Shortcut "New optiCLOUD Note".** The app offers two actions to the system, so that they work with Siri, in Spotlight, in the Shortcuts app, and on the Action button:
  1. *New optiCLOUD Note* asks for the text, for example by dictation through Siri, and saves the entry with the defaults without opening the app. It waits up to 10 seconds for the delivery and answers whether the note is in optiCLOUD or waits in the queue.
  2. *New optiCLOUD Note in the App* opens the app with the form.
- The phrases contain the name of the app, for example "New note in optiCLOUD Sensor". On iOS, "optiCLOUD" is also given as an alternative name of the app; in the first test on 2026-10-27 Siri did not take it (see Open points).
- The names and phrases of the shortcuts are translated into the languages of the app.

## Note

The app creates the note with `POST /api/notes` through the user's session:

```json
{
  "entityId": { "entityType": "DEVICE", "id": "<deviceId>" },
  "tenantId": { "entityType": "TENANT", "id": "<tenantId>" },
  "projectId": { "entityType": "PROJECT", "id": "<projectId>" },
  "authorityDataId": { "entityType": "AUTHORITY_DATA", "id": "<authorityDataId>" },
  "name": "Brake check",
  "text": "Brake test at the depot passed.\n\n2025-10-09 10:53 +02:00",
  "status": "CREATED",
  "priority": "MEDIUM",
  "additionalInfo": {
    "source": "optiCLOUD Sensor App",
    "savedAt": 1760000000000,
    "latitude": 47.3769,
    "longitude": 8.5417
  }
}
```

- `tenantId`, `projectId`, and `authorityDataId` come from the claims of the access token.
- Every identifier needs its `entityType`. Without it the server refuses the request.
- `name` is the title, or the title from the text. `status` is `CREATED` or `ARCHIVED`. `priority` is `LOW`, `MEDIUM`, or `HIGH`.
- `additionalInfo.source` is always `optiCLOUD Sensor App`.
- `additionalInfo.savedAt` is the moment of saving in milliseconds.
- `additionalInfo.latitude` and `additionalInfo.longitude` are present only if a position was known.
- The answer is the stored note with its `id`.

## Time stamp

The server sets the time of a note itself, when the note arrives. It ignores a time sent by the app. An entry delivered later therefore has the delivery time in optiCLOUD. To keep the real time:

- `additionalInfo.savedAt` holds the moment of saving.
- The app adds the moment of saving at the end of the text, so that it is visible in optiCLOUD: an empty line, then the local time of the phone with its offset from UTC in the form `YYYY-MM-DD HH:MM ±HH:MM`, for example `2026-10-24 15:42 +02:00`. The form has no words, so it reads the same in every language.

## Afterwards

- The app does not change or delete a note once it is delivered. Archiving and editing happen in optiCLOUD.
- optiCLOUD cannot delete single notes. They are deleted with their device.

## Open points

1. optiMEAS is asked whether a note can carry a time stamp set by the client, and for a history of changes to notes. With a client time stamp, the text addition can go.
2. iOS: whether Siri takes the alternative name "optiCLOUD", for example after a restart of the phone, so that "New optiCLOUD Note" works. Phrases that start with "New Note" can go to the notes app of the system instead.
