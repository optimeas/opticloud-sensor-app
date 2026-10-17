# optiCLOUD Sensor

Native apps (Swift on iOS, Kotlin on Android) that turn a phone into a sensor for optiCLOUD, the IoT platform by optiMEAS.

Read [docs/project-brief.md](docs/project-brief.md) before doing anything else. It holds the product idea, the decisions, the stages, and the open questions. When a decision changes, update it in the same commit.

## Rules

- **This repository is public.** Everything pushed here, including history, is visible to everyone.
- **Never copy from the private optiCLOUD source.** No code, comments, configuration, internal host names, credentials, ticket references, or details of internal defects. Describe interfaces in your own words in `docs/spec/`. The full rules are in the [project brief](docs/project-brief.md#working-with-the-opticloud-source).
- **Never commit secrets:** access tokens, passwords, signing keys, provisioning profiles, local environment files.
- **`docs/spec/` is the master.** Change the specification, both apps' behavior, and the shared test vectors together. Neither app is the reference for the other.
- **Follow each platform's design standards** and use the system font. Do not port one platform's look to the other.
- **Spelling is exact:** optiMEAS, optiCLOUD, optiCLOUD Sensor.
- **Keep the documentation true.** Describe only what exists; mark plans as plans.
- **Stay in your lane.** The iOS app and the Android app are developed in separate sessions. `ios/CLAUDE.md` and `android/CLAUDE.md` hold the platform rules. Work on branches named `ios/<topic>` or `android/<topic>`, change only your own app directory and `docs/`, and merge into `main` through pull requests.
- Use [Conventional Commits](https://www.conventionalcommits.org/). Commit and push only when asked.
