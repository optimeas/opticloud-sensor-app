# Welcome and what is new

**Status: draft.** Implemented in the iOS app since 2026-10-27. The Android app follows.

The app greets a new user with a welcome screen, and after an update it says what the new version brings. Both screens can be opened again later, together with the history of all versions.

## Screens

- **Welcome.** The name of the app, what it is for in one sentence, and its main features, each with a symbol, a title, and one sentence on what it brings to the user. A button starts the app; without a device, it leads on to the sign-in.
- **What is new.** The version and its highlights: up to four changes that matter most to the user, each with a symbol, a title, and one sentence. A button closes it.
- **Version history.** Every version, newest first, with its date and its changes, each marked as *new*, *improved*, or *fixed*.

Both the welcome and the what-is-new screen link to the version history. All three can be opened from the information about the app, and the texts are translated into the languages of the app.

## When a screen appears

The app keeps the version whose screen it last showed, the *last seen version*. At start, it compares it with its own version, the version number the user sees in the store, without the build number:

| Last seen version | Device chosen | Highlights for this version | Screen |
| --- | --- | --- | --- |
| same as the app | any | any | none |
| none | no | any | welcome |
| none | yes | yes | what is new |
| none | yes | no | none |
| other | any | yes | what is new |
| other | any | no | none |

- "None" with a device chosen is an app that was used before it kept the last seen version; it gets what is new, not the welcome.
- The last seen version is set to the app's version when the screen closes, or at once when no screen appears. A later start of the same version shows nothing.
- Builds of the same version do not show the screen again.
- A version without highlights shows nothing; its changes are still in the version history.

The test vectors are in [vectors/start-screen.json](vectors/start-screen.json).

## Content

Each app keeps its own versions and texts, because the two apps are released separately. The history describes only what was released. It gives the build number when a version had more than one build.

## Open points

None.
