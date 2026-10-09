# Color Fill

**Color Fill** by WAJIHA — flood the whole board with one color! A warm, physical flood-fill puzzle: pick paint colors, watch the wave spread across wooden tiles, and clear the board in as few moves as you can.

- **Package:** `com.gameswajiha.colorfill`
- **Engine:** Flutter + Dart, custom deterministic flood-fill engine (`lib/engine/colorfill_engine.dart`)
- **Rules:** see [RULES.md](RULES.md) — the authoritative source of truth

## Features

- **Campaign**: 20 hand-seeded levels across 3 difficulty tiers (8×8/5 colors → 10×10/6 → 12×12/7)
- **Daily Challenge**: one seeded board per day with a streak counter
- **Quick Play**: random board at your chosen difficulty
- Animated flood-wave spread, move counter vs par, 3-star scoring, move limit (par + 8)
- Undo (30 steps), 3 greedy-AI hints per board
- **12 table themes** (4 free + 8 Pro) and **8 physical tile styles** (Rounded, Pebble, Wood Block, Marble, Candy, Ceramic, Slate, Pillow) + custom theme creator (Pro)
- Renameable player profile (saved on every keystroke, order-preserving JSON)
- Synthesized audio: menu music, gameplay BGM, pour/click/win/lose SFX — no asset files
- Pro screen with Free-vs-Pro comparison, real Play Billing (`colorfillpro`, `colorfillcoffee`, `colorfillchocolate`), tip jar, restore
- Share + in-app review wired to the real Play Store URL

## Build

```bash
flutter pub get
flutter analyze
flutter build appbundle --release
```

Release signing: drop the upload keystore config at `android/key.properties` (see `android/app/build.gradle.kts`); local builds fall back to debug keys.
