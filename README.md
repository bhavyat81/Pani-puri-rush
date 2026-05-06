# Pani Puri Rush 🍵

A casual time-management mobile game about serving pani puri to hungry customers — built with **Godot 4.3** for Android & iOS (portrait, 1080×1920).

> **Web prototype:** The original browser prototype (`index.html` / `game.js` / `style.css`) is preserved in the repo root. Open `index.html` directly in a browser to play it. The Godot project below is the full mobile game.

---

## First-time setup

Godot generates SVG `.import` sidecars on first editor open. Before you can run the game headlessly, open the editor once to trigger the asset import pass:

```bash
godot --path . -e          # opens editor, imports SVGs — then close it
godot --path .             # runs the game
```

If you see errors like `No loader found for resource: res://assets/sprites/*.svg`, you skipped the editor pre-pass — run the `-e` command above first.

> **Note:** The `.godot/imported/*.ctex` cache files do **not** need to be committed. The `.svg.import` sidecar files in `assets/sprites/` (if generated) should be tracked — the `.gitignore` does not exclude them.

---

## How to Run (Godot Editor)

1. [Download Godot 4.3](https://godotengine.org/download) (standard, not .NET).
2. Open Godot → **Import** → select `project.godot` in this repo.
3. Press **F5** (or the Play button) to run.

---

## Controls

| Action | Input |
|---|---|
| Pick up a puri | Tap **Puri Tray** |
| Add masala | Tap **Masala Bowl** |
| Add pani water flavor | Tap one of the colored **Jug buttons** |
| Send puri to plate | Tap **Puri Tray** again (puri must be ready) |
| Serve customer | Tap the **customer** |
| Discard in-progress puri | Tap **Discard** |
| Pause | Tap **Pause** button (top right) |

---

## Flavors

| Name | Color | Description |
|---|---|---|
| **Teekha** | Green | Spicy mint water |
| **Meetha** | Brown | Sweet tamarind water |
| **Hing** | Yellow | Asafoetida water |
| **Lehsun** | Olive | Garlic water |
| **Jaljeera** | Lime | Cumin cooler |

Flavors unlock progressively across the 10 levels (Days 1–10).

---

## Customer Types

| Type | Patience | Tip | Notes |
|---|---|---|---|
| Normal | 25s | 10 | Balanced |
| VIP | 15s | 30 | Impatient, pays well |
| Kid | 30s | 5 | Only wants Meetha |
| Foodie | 20s | 25 | Wants 3+ different flavors |

---

## Adding / Editing Levels

Edit `data/levels.json`. Each level entry supports:

```json
{
  "id": 1,
  "name": "Day 1 — First Customers",
  "duration_seconds": 60,
  "available_flavors": ["TEEKHA", "MEETHA"],
  "customer_count": 5,
  "spawn_interval": [4, 7],
  "customer_pool": [{"type": "NORMAL", "weight": 100}],
  "stars_thresholds": {"1": 30, "2": 60, "3": 100}
}
```

No code changes needed — the game reads this file at runtime.

---

## Replacing Placeholder Art

All art is SVG placeholders in `assets/sprites/`. Replace any file with a same-name `.svg`, `.png`, or `.webp` and update the path in `scripts/flavor.gd` (for jug sprites) or the relevant scene.

---

## Adding Sounds

Drop `.wav` or `.ogg` files into `assets/sounds/` with the names listed in `assets/sounds/README.md`. The `AudioManager` autoload detects them automatically — no code changes needed.

---

## Android Export

1. Install [Android Studio](https://developer.android.com/studio) and Android SDK.
2. In Godot: **Editor → Export → Android** → configure your keystore.
3. Download Godot 4.3 Android export templates via **Editor → Manage Export Templates**.
4. Click **Export Project** → choose `build/android/pani-puri-rush.apk`.

The GitHub Actions workflow (`.github/workflows/build-android.yml`) automates this on push to `main` using the `barichello/godot-ci:4.3` Docker image.

---

## iOS Export (macOS only)

1. On a Mac with Xcode installed, open the project in Godot 4.3.
2. Download Godot 4.3 iOS export templates via **Editor → Manage Export Templates**.
3. Configure your Apple Developer Team ID in `export_presets.cfg`.
4. **Editor → Export → iOS** → Export Project → `build/ios/pani-puri-rush.ipa`.

---

## Project Structure

```
Pani-puri-rush/
├── index.html          # Browser prototype (original)
├── game.js             # Browser prototype logic
├── style.css           # Browser prototype styles
├── project.godot       # Godot 4.3 project file
├── icon.svg            # App icon
├── export_presets.cfg  # Android + iOS export config
├── data/
│   └── levels.json     # All 10 level definitions
├── scenes/
│   ├── MainMenu.tscn   # Title screen
│   ├── Main.tscn       # Gameplay scene
│   ├── HUD.tscn        # HUD overlay
│   ├── Customer.tscn   # Customer node
│   ├── Puri.tscn       # Puri node
│   ├── Stall.tscn      # Stall/counter node
│   ├── LevelComplete.tscn
│   └── GameOver.tscn
├── scripts/
│   ├── game_manager.gd   # Autoload: score, coins, reputation
│   ├── audio_manager.gd  # Autoload: SFX (graceful no-op if files missing)
│   ├── flavor.gd         # Autoload: flavor enum + color/name data
│   ├── level_loader.gd   # Autoload: reads levels.json
│   ├── main_scene.gd     # Gameplay controller
│   ├── customer.gd       # Customer AI
│   ├── order.gd          # Order data class
│   ├── puri.gd           # Puri state machine
│   ├── hud.gd            # HUD controller
│   ├── stall.gd          # Stall tap handler
│   ├── main_menu.gd      # Main menu controller
│   ├── level_complete.gd # Level complete screen
│   └── game_over.gd      # Game over screen
└── assets/
    ├── sprites/          # SVG placeholder art
    ├── fonts/            # (empty — uses Godot default font)
    └── sounds/           # (empty — AudioManager handles missing files)
```

---

## Roadmap

- [ ] Replace SVG placeholders with hand-drawn pixel art
- [ ] Add background music (loop-ready OGG)
- [ ] Persist high scores with `FileAccess` / cloud save
- [ ] Level select screen with star display
- [ ] Haptic feedback on mobile
- [ ] Localization (Hindi, Marathi)

---

## License

MIT — see [LICENSE](LICENSE).

> **Disclaimer:** "Pani Puri Rush" is an original fan project. All trademarks belong to their respective owners.
