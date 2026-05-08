# Swift Migration Parity

This checklist exists to keep the Swift app aligned with the existing product's design language and behavior.

## Source of truth

- Native target: `/Users/lucytrepanier/Code/capstone/swift-app`
- Legacy reference: `/Users/lucytrepanier/Code/capstone/app`
- Supporting reference data: `/Users/lucytrepanier/Code/capstone/data`
- Legacy generation logic: `/Users/lucytrepanier/Code/capstone/services`

## Parity rule

When a screen is ported, match both:

1. visual direction
2. user behavior and flow

Do not treat the Swift app as a redesign unless that change is intentional.

## Screen checklist

### Home / create flow

- [x] voice-first layout exists in Swift
- [x] typed fallback exists in Swift
- [x] onboarding overlay exists in Swift
- [ ] background image treatment matches the Expo app more closely
- [ ] bottom navigation treatment matches the Expo app more closely
- [ ] interaction polish matches Expo mic animations

### Generating flow

- [x] dedicated loading screen exists
- [x] retry path exists
- [ ] animation cadence and visual polish still need parity tuning

### Output flow

- [x] HTML artifact rendering exists via `WKWebView`
- [ ] native palette mode from Expo output screen not yet ported
- [ ] native photo mode from Expo output screen not yet ported
- [ ] native UI concept mode from Expo output screen not yet ported
- [ ] output action layout still needs parity work

### Library

- [x] saved boards exist in Swift
- [x] collection drill-in exists in Swift
- [x] board drill-in exists in Swift
- [ ] detailed board layouts still need closer parity with Expo
- [ ] fullscreen image viewing not yet ported

### Settings

- [x] basic settings shell exists
- [ ] actual settings behavior still placeholder

### Data / services

- [x] session persistence exists
- [ ] real generation pipeline not yet ported
- [ ] backend/security cleanup still needed

## Next priority

1. Port native output modes from the Expo output screen
2. Replace mock generation with a real backend-backed service
3. Tighten visual parity for library board detail layouts
