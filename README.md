# 1+1 — Mental Math Speed Trainer

Flutter port of [1+1](https://hexpredator1-boop.github.io/1p1/), originally built as a PWA by Claude.

## Features

- Four operations: addition, subtraction, multiplication, division
- Five difficulty levels per operation
- 15-question sessions with live timer
- Score = ideal time / (actual time + wrong-answer penalties)
- Personal bests and perfect-score trophy cabinet
- Customisable goal time per operation × level
- Haptic feedback on wrong answers

## Building

GitHub Actions automatically builds a release APK on every push to `main`.  
Download the latest APK from the [Releases](../../releases) tab.

### Build locally

```bash
flutter pub get
flutter build apk --release
# APK → build/app/outputs/apk/release/app-release.apk
```

Requires Flutter 3.22+ and Java 17.
