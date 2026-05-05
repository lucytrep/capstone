## Draft Native

This folder contains the standalone native iOS rewrite scaffold for the current Expo app.

## Work here by default

If the iOS app is being updated, assume this folder is the source of truth.

- Active native app: `/Users/lucytrepanier/Code/capstone/swift-app`
- Legacy reference app: `/Users/lucytrepanier/Code/capstone/app`

When porting behavior from the old app, copy the product behavior into Swift rather than editing the Expo implementation unless you explicitly mean to update the legacy reference.

### Current status

- Native SwiftUI app target with its own Xcode project
- Voice-first home screen scaffold using `Speech` and `AVFoundation`
- Session persistence using `UserDefaults`
- Generating screen and artifact output flow
- `WKWebView` artifact renderer so we can preserve the current HTML-based output model
- Native saved-library data model and drill-in screens

### What is still mocked

- Artifact generation currently uses `MockArtifactGenerator`
- No API keys are embedded here on purpose
- The large TypeScript service in `services/api.ts` still needs to be replaced by a backend or ported carefully

### Recommended migration order

1. Wire a backend endpoint for artifact generation
2. Port the output customization controls from `app/output.tsx`
3. Replace the remaining library-specific visual polish from the Expo app
4. Replace placeholder settings screens with real preferences
5. Add tests around session persistence and generation flow

### Direction for future sessions

Use prompts like:

- "Work in `/Users/lucytrepanier/Code/capstone/swift-app` only"
- "Continue the native Swift rewrite"
- "Port the next Expo feature into the Swift app"

### Opening the app

Open `DraftNative.xcodeproj` in Xcode and run the `DraftNative` scheme.
