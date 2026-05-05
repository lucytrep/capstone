## Draft Native

This folder contains the standalone native iOS rewrite scaffold for the current Expo app.

### Current status

- Native SwiftUI app target with its own Xcode project
- Voice-first home screen scaffold using `Speech` and `AVFoundation`
- Session persistence using `UserDefaults`
- Generating screen and artifact output flow
- `WKWebView` artifact renderer so we can preserve the current HTML-based output model
- Static library and settings screens as placeholders for the React Native equivalents

### What is still mocked

- Artifact generation currently uses `MockArtifactGenerator`
- No API keys are embedded here on purpose
- The large TypeScript service in `services/api.ts` still needs to be replaced by a backend or ported carefully

### Recommended migration order

1. Wire a backend endpoint for artifact generation
2. Port the library data model from `data/library.ts`
3. Port the output customization controls from `app/output.tsx`
4. Replace placeholder settings screens with real preferences
5. Add tests around session persistence and generation flow

### Opening the app

Open `DraftNative.xcodeproj` in Xcode and run the `DraftNative` scheme.
