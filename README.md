# Capstone

## Active app target

The native Swift rewrite now lives in [swift-app](./swift-app).

If you are continuing product work, feature work, bug fixes, or UI updates for the iOS app, start in:

- `/Users/lucytrepanier/Code/capstone/swift-app`

## Important note for future updates

The old Expo / React Native app is still present in this repo for reference and migration only.

Unless you are explicitly porting something from the legacy app, treat these folders as reference material:

- `/Users/lucytrepanier/Code/capstone/app`
- `/Users/lucytrepanier/Code/capstone/components`
- `/Users/lucytrepanier/Code/capstone/services`
- `/Users/lucytrepanier/Code/capstone/data`

## Current native workflow

1. Open `/Users/lucytrepanier/Code/capstone/swift-app/DraftNative.xcodeproj`
2. Build and run the `DraftNative` scheme
3. Implement new native work inside `swift-app`
4. Only read the Expo app when porting behavior or content into Swift

## Migration status

Already rebuilt in Swift:

- app shell and tab structure
- voice-first home flow scaffold
- generation loading flow
- HTML artifact rendering via `WKWebView`
- session persistence
- native library shell

Still to port:

- real generation/backend pipeline
- the richer output controls from the Expo app
- remaining saved-library interactions and polish
- settings/preferences behavior
