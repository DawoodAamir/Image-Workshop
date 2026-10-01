# Verification

Xcode 27 Debug and Release builds and Debug/Release Swift Testing checks passed. Core checks cover immutable assets, crop/output validation, PNG rendering, PDF contact sheets, and invalid imports.

[Hosted native workflow, October 1, 2026](https://github.com/DawoodAamir/Image-Workshop/actions/runs/36809047090) passed: import through the system picker, title/caption edits, saving, favourites, and persistence after relaunch. Its window screenshot is included in the README. Test libraries use isolated sandbox folders.

Local macOS UI automation could not initialise with this machine's current developer automation settings; the hosted run supplies interaction evidence. No system security setting was changed.

Remaining manual checks: Apple Image Playground generation/cancellation/limits, an on-device prompt response, model availability transitions, signed distribution, VoiceOver, increased contrast, keyboard-only navigation, and extended large-library use. These checks require suitable hardware/settings and are not inferred from ordinary editing tests.
