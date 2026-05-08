# Capstone Agent Rules

## Scope

- For iOS work, use `/Users/lucytrepanier/Code/capstone/swift-app` as the source of truth.
- The Expo app in `/Users/lucytrepanier/Code/capstone/app` is reference-only unless the task is explicitly about migration or parity.

## Product

`Draft` is a voice-first creative generation app. A user gives a prompt, the app generates three directions, and the result is reviewed in a designed output flow and later revisited in the library.

Do not treat this as a generic sample app.

## Output Modes

Every prompt must resolve into one of these output types:

1. `UI`
2. `color`
3. `image`
4. `moodboard`

Rules:

- `image` means image gathering only.
- `moodboard` means a mixed output that combines image gathering and color.
- Do not collapse `image` and `moodboard` into the same experience.
- Final output should always present three directions.
- The final output must show a bottom indicator so the user knows which direction/page they are viewing.

## Priorities

- Preserve the voice-first flow.
- Preserve parity with the established React product unless a redesign is intentional.
- Keep the output feeling editorial and deliberate, not generic.
- Make generation quality more important than speed when those conflict.

## Generation Rules

- Generations are the core product output. Treat them as high-value.
- API-backed material should be used for generation quality.
- Do not silently degrade to weak local-only output for image-heavy generations.
- If the required API-backed source is missing, fail clearly instead of pretending the result is complete.
- Do not hardcode secrets or ship keys in source.

## Architecture Rules

- `AppModel` owns generation state and session state.
- Keep UI-facing state changes on the main actor.
- Keep the output parser and renderer contracts in sync.
- If you change payload shape, update the parser and output UI in the same pass.

## Important Swift Files

- `swift-app/DraftNative/App/AppModel.swift`
- `swift-app/DraftNative/Views/HomeView.swift`
- `swift-app/DraftNative/Views/OutputView.swift`
- `swift-app/DraftNative/Models/ArtifactPayload.swift`
- `swift-app/DraftNative/Services/MockArtifactGenerator.swift`
- `swift-app/DraftNative/Services/SpeechRecognizer.swift`

## Working Rules

- Start in Swift first.
- Check the React version before changing major product behavior.
- Avoid broad rewrites when a focused fix will do.
- Document real product decisions here if they are easy to lose.

## Bad Changes

- Flattening the app into default SwiftUI patterns
- Removing parity behaviors because they are harder to port
- Blurring the difference between `image` and `moodboard`
- Hiding missing API-backed generation behind weak fallback output
- Removing the three-direction comparison model

## Keep This File Lean

Only keep rules here that future agents truly need.
