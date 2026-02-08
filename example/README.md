# example

Example app for `misskey_mfm_renderer` that demonstrates:

- MFM rendering with custom emoji support
- Quick setup using `MfmEmojiConfig`
- Catalog and playground screens for MFM syntax

## Quick Start

```bash
flutter run
```

The app initializes emoji support once at startup and shares the configuration
through `MfmConfig`, so any `MfmText` widget renders custom emojis out of the box.
