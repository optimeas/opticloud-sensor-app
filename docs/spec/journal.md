# Journal

**Status: draft.** Writing notes was tested against an optiCLOUD test server on 2026-10-24. The offline queue is not yet specified.

A journal entry is a text the user writes in the app. optiCLOUD stores it as a note on the device the phone sends to. A note always belongs to the signed-in user (see [sign-in.md](sign-in.md)).

## Entry

The user fills in:

| Field | Required | Default | Values |
| --- | --- | --- | --- |
| Title | yes | empty | Text |
| Text | yes | empty | Text |
| Status | yes | Created | Created, Archived |
| Priority | yes | Medium | Low, Medium, High |

- The app saves an entry only when title and text are filled in.
- The moment of saving is the time stamp of the entry.
- If the user has allowed location, the app adds the position at the moment of saving.

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
- `name` is the title. `status` is `CREATED` or `ARCHIVED`. `priority` is `LOW`, `MEDIUM`, or `HIGH`.
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

1. The offline queue for entries: order, retries, and what happens when the session has expired. This goes into [offline-queue.md](offline-queue.md) with stage 2.
2. optiMEAS is asked whether a note can carry a time stamp set by the client, and for a history of changes to notes. With a client time stamp, the text addition can go.
