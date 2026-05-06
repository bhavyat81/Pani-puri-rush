# DEV_NOTES — Visual Fix for Pani Puri Rush

## Problem

After the initial scaffold merge, running `godot --path .` showed only an orange
background with text labels. No customers, no puri, no jugs, no masala bowl, and
no plate were visible because:

1. **SVGs missing `width` / `height` attributes** — Godot 4 requires these to know
   the raster dimensions when importing an SVG as a Texture2D. Without them the
   importer either errors out silently or falls back to a tiny default texture.

2. **Scenes used `ColorRect` / `PanelContainer` / plain `Button` instead of
   textured nodes** — No `ext_resource` reference to any sprite existed in
   `Main.tscn`, `MainMenu.tscn`, or `Customer.tscn`, so no SVG was ever loaded.

## Changes Made

### SVG rewrites (`assets/sprites/`)

All 14 existing files were rewritten with:
- Explicit `width="…"` and `height="…"` attributes (required by Godot 4 SVG importer)
- Matching `viewBox` so the art scales correctly
- Significantly improved cartoon artwork recognisable at mobile screen sizes

Three new files were added:
| File | Purpose |
|---|---|
| `puri_flavored.svg` | Puri with a white droplet that takes on the flavor colour via `Sprite2D.modulate` |
| `counter.svg` | Wooden counter background behind the jug/action row |
| `icon_pause.svg` | Two-bar pause icon for the HUD button |

### Scene wiring

| Scene | Change |
|---|---|
| `MainMenu.tscn` | Background `ColorRect` → `TextureRect` using `background_market.svg` |
| `Main.tscn` | Background `ColorRect` → `TextureRect`; added `counter.svg` behind stall area; `PuriTrayBtn` and `MasalaBowlBtn` now have `icon =` the matching SVG; a `PlateBG TextureRect` shows `plate.svg` under the assembly area |
| `Customer.tscn` | `ColorRect Body` + `ColorRect Head` removed; replaced with a single `Sprite2D BodySprite` defaulting to `customer_neutral.svg` |
| `HUD.tscn` | PauseButton now uses `icon_pause.svg` instead of text |

### Script changes

| Script | Change |
|---|---|
| `customer.gd` | Preloads three customer textures; `_update_mood()` swaps `body_sprite.texture` between neutral/angry/happy instead of changing a `ColorRect` colour |
| `main_scene.gd` | Preloads `puri_empty/filled/flavored.svg`; `_build_jug_buttons()` sets `btn.icon` to the jug SVG; `_update_puri_display()` / `_update_plate_display()` create `TextureRect` nodes with the appropriate puri texture (and sets `modulate` to the flavor colour for the flavored variant) |

## Verification

To verify the fix on a fresh clone:

```bash
git clone https://github.com/bhavyat81/Pani-puri-rush.git
cd Pani-puri-rush

# Check Godot is available
godot --version   # should print 4.3.x

# Headless import pass (no window)
godot --headless --quit --path .

# Run the game
godot --path .
```

Expected result after the fix:
- **Main Menu**: market background (orange-purple gradient with stall silhouettes and
  fairy lights) visible behind the title text and Play button.
- **Gameplay**: wooden counter at the bottom; jug buttons show the coloured glass-jug
  illustrations; Puri Tray button shows the golden puri; Masala button shows the bowl;
  customers walk in as cartoon characters and switch between neutral / angry faces as
  their patience drains.
- **Puri assembly**: picking up a puri shows the golden puri sprite; adding masala
  shows the filled puri; dipping in a flavor tints a white droplet to that flavor's colour.
