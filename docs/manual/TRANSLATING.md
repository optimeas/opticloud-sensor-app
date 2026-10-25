# Translating the manual

The user manual exists in five languages:

| Tree | Language | Role |
|---|---|---|
| `docs/manual/de/` | German | source of the French, Italian, and Spanish translations |
| `docs/manual/en/` | English | maintained by hand alongside German |
| `docs/manual/fr/` | French | translated from German |
| `docs/manual/it/` | Italian | translated from German |
| `docs/manual/es/` | Spanish | translated from German |

All five are published from this repository: `docs/manual/scripts/sync-to-docusaurus.py` copies them into the optiMEAS documentation site and overwrites what is there. A page edited only in the documentation site is lost at the next sync, so every change to a page of the manual starts here.

## Workflow

A change to a page under `de/` is complete when the same change is in `en/`, `fr/`, `it/`, and `es/`. A change to the app that the manual describes brings the change to the manual in the same pull request.

1. Edit the German page and mirror the change in `en/`.
2. Ask what is open:

   ```bash
   python3 docs/manual/scripts/translation-status.py
   ```

   It lists, per language, the pages whose German source changed since they were translated (`stale`), German pages without a translation (`missing`), translations without a German page (`orphaned`), pages whose headings, code blocks, or front matter no longer line up with German (`structure`), and media files that are absent (`media`). It exits with 1 while anything is open.
3. Bring the listed pages up to date following the rules below. For a small change, apply the same edit to the French, Italian, and Spanish page; for a new or reworked page, translate it again from German.
4. Record that the translations now match the German text:

   ```bash
   python3 docs/manual/scripts/translation-status.py --record
   ```

   This writes `docs/manual/translation-state.json`, which holds the hash of the German page each translation was made from. Commit it together with the pages. `--record sensors.md` or `--locale it` limits what is recorded; use that when only part of the list has been done.
5. Run the status again; it must report `up to date` for every language.

Recording a page states that its translation is current. Do not record to make the list go away.

## Rules for a translation

A translated page keeps the path and file name of its German page.

Left exactly as in German:

- fenced code blocks, including comments inside them, and inline `code`, such as telemetry keys, commands, and JSON
- front matter keys and structure; the values of `image`, `sidebar_position`, `last_update`, `license`, and `copyright`
- link and image targets: relative paths, file names, `#anchors`, URLs
- heading count, order, and level
- table structure, identifiers, numbers, units
- product and company names: `optiCLOUD`, `optiCLOUD Sensor`, `optiMEAS`, `OSF`, `iPhone`, `iOS`, `Android`, `GitHub`

Translated: body text, headings, table headers and cell prose, list items, image alt text, link text, the front matter values `title`, `description`, `sidebar_label`, and generic `keywords`, and the license line at the end of the page.

Write numbers with the decimal separator of the language (German, French, Italian, and Spanish: comma; English: point), except inside `code`.

The names of buttons, tabs, and settings are written exactly as the app shows them in that language. They are in the string catalog of the iOS app, `ios/OptiCloudSensor/Localizable.xcstrings`, and the system texts for permissions in `InfoPlist.xcstrings`. Names of iOS itself, such as the permission "Motion & Fitness" or the Settings app, are written as iOS shows them in that language.

These optiCLOUD terms stay in English in every language, as in the optiMEAS documentation: Tenant, Shared Attribute(s), Access Token, Dashboard, RPC. "Telemetry" and "client attribute" are translated.

Address the reader as the app does: German "du", French "vous", Italian "tu", Spanish "tú". Write natural prose for users, not for developers. Add nothing that is not in the German page and drop nothing.

## Docusaurus

The pages are written for the optiMEAS documentation site, which is built with Docusaurus, and read on GitHub as well. Use only Markdown that renders in both: no MDX components, no admonitions, and no explicit heading ids. Link between pages with relative links to the `.md` file, without anchors, so that a translated heading cannot break a link.

## What the status tool cannot see

It compares structure, not meaning. A page can pass every check and still be a poor translation. Have a native speaker proofread a language before it is announced.
