# Image request: ProfessionWheel in-game wheel textures, batch 1

Generate 5 original images with your image generation tool and save each as a PNG
at `art/wheel/raw/<file>`, relative to the current working directory. Create the
folder if needed. Change no other files.

## Context

These are the building blocks of an addon's radial menu. The addon assembles them
in game: one big disc, up to five round slot frames on it (each with a game icon
inside), gold spokes from the center to each slot, small star accents between the
slots, and a glowing hub orb in the middle. The target look is the attached /
existing reference `art/curseforge/logo.png` (the frame, rim, slot rings, spokes,
stars and hub of that image), but **every piece is drawn separately and alone**.

## Style (all 5)

- Same as the reference: restrained fantasy, painterly but clean, hammered warm
  gold metal (#9e8552 to bright #e0b660 highlights), near-black brown face
  (#17140f), soft light from the top-left.
- Perfectly centered, perfectly round / symmetric where round, viewed straight on
  (no perspective).
- **Background: flat pure magenta #FF00FF everywhere outside the object**, with no
  shadow, glow, gradient or texture on the magenta. (The magenta is removed
  automatically, so it must be a single flat color and must not appear anywhere in
  the object.) **No outer glow or drop shadow** on any piece.
- No text, letters, numbers, symbols, icons or tools inside any piece. Original
  artwork only; do not imitate Blizzard / World of Warcraft UI art.

## The pieces

| file | size | content |
|---|---|---|
| `disc.png` | 1024 × 1024 | A complete round disc filling 98% of the canvas. Thick hammered-gold outer rim (about 4% of the diameter) with a thin inner bevel line. The face is near-black warm brown with very subtle leather/stone texture and a gentle darker vignette toward the rim. **Nothing else on the face**: no slots, spokes, stars, hub or ornaments. |
| `slot.png` | 512 × 512 | A single round gold ring frame, like one slot of the reference: ring band about 7% of the diameter, outer edge at 96% of the canvas, slight bevel and hammered texture. **The whole inside of the ring is flat magenta** (it is a hole for an icon). |
| `hub.png` | 512 × 512 | The center hub: a round gold ring (band about 12% of diameter, outer edge at 90% of canvas) holding a smooth glowing amber-gold orb that fills the inside. The orb is brightest in the middle. No light rays, no glow spilling outside the ring. |
| `spoke.png` | 1024 × 1024 | A single straight horizontal gold bar through the exact center of the canvas, 90% of the canvas wide and about 5% tall, slightly flared at both ends like the spokes in the reference, hammered gold with a top-left highlight. Everything else is magenta. |
| `star.png` | 512 × 512 | One small four-pointed gold star accent like those between the slots in the reference: four long sharp points (up, down, left, right) with a slightly concave diamond shape, filling 85% of the canvas, centered. |

## When finished

Reply with the files written, the tool used, and the exact prompt for each image.
