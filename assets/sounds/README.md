# Sound Effects

This directory is intentionally empty. The game ships with no audio files — the `AudioManager` handles missing files gracefully (no-op, no crash).

## Where to drop sounds

Place `.wav` or `.ogg` files here with these exact names:

| Filename | Triggered by |
|---|---|
| `tap.wav` | Any tap/button press |
| `serve_correct.wav` | Correct puri served to customer |
| `serve_wrong.wav` | Wrong puri served (discarded) |
| `customer_happy.wav` | Customer leaves happy |
| `customer_angry.wav` | Customer leaves angry |
| `combo.wav` | Combo multiplier activated |
| `level_complete.wav` | Level completed |

## Recommended free sources

- [freesound.org](https://freesound.org) — CC0 sounds
- [mixkit.co](https://mixkit.co/free-sound-effects/) — Free sound effects
- [zapsplat.com](https://www.zapsplat.com) — Free with attribution

## Format recommendations

- Sample rate: 44100 Hz
- Bit depth: 16-bit
- Duration: 0.1–2 seconds (SFX), loop-ready for BGM
