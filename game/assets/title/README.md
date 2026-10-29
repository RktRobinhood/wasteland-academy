# Title screen art

The title screen key art: Tilly Redback, Banjo Brumby and Spark on the road at dusk, looking at the Signal Tower.
The game draws the title and the buttons on top, so there is no text in the art.

| File | Size | Bytes | Used for |
|---|---|---|---|
| `key-art.webp` | 1920×1080 | 232,364 | PC and landscape title screen |
| `key-art-phone.webp` | 1080×1920 | 221,890 | Phone and portrait title screen, recomposed rather than cropped |
| `share-card.png` | 1200×630 | 229,034 | Link preview. The group and the tower sit inside the centre 1000×500 |

Batch total: 683,288 bytes.

Reserved zones, all measured on the files above (white text needs 4.5:1, which is WCAG AA):

| File | Title zone | White text on its mean | On its brightest 10% | Button zone |
|---|---|---|---|---|
| `key-art.webp` | top 30% | 7.86:1 | 5.23:1 | lowest 20%: dark road, mean luminance 0.014 |
| `key-art-phone.webp` | top 35% | 9.48:1 | 6.10:1 | lowest 25%: dark road, mean luminance 0.006 |
| `share-card.png` | upper-left third | 7.44:1 | 4.35:1 | none |

Contrast is 1.05 / (L + 0.05), where L is the WCAG relative luminance of the zone.

## Where it came from

Everything was rendered locally in ComfyUI with Qwen Image 2.1 (int8): 25 steps, euler/simple, cfg 1. Edits were
done in Pillow. The work took four rounds and 32 renders, with 24 landscape and 8 phone. Method, rounds and
counters are on FAL-472.

References:

- The characters are the accepted FAL-206 full-body masters of Tilly, Banjo and Spark. The avatars and
  `assets/journey/party/` were drawn from these same masters.
- The tower is `assets/journey/signal-tower/far.webp`.
- The mood comes from `assets/style-guide/style-02-main-menu-home-hub.png`.
- All of these sit on one reference board, which every render saw as `<image1>`.

| File | Graph | Seed | Made from | Edits |
|---|---|---|---|---|
| `key-art.webp` | `qwen21_patch_ref`, denoise 0.68 (prompt `1e2bf4d6`) | 47221 | A layout made from round 1 #6 (`qwen21_t2i_styleref`, seed 47202, prompt `91d02968`). Its group (BiRefNet cutout) moved to the left third, and its tower (BiRefNet cutout) shrunk to the right on a clean sky, then repainted over the whole frame | Centre crop from 1920×1088. Top 22% darkened to 0.90, easing back over 12%. WebP q94 |
| `key-art-phone.webp` | `qwen21_patch_ref`, denoise 0.80 (prompt `3c11b238`), then the border outpainted at denoise 1.00 (prompt `330a9269`) | 47221, then 47242 | The same group and tower, restaged for portrait. The render was then scaled to 0.84 inside a new border, so the group and the tower fit a 390×844 cover-fit | The centre was spliced back from the source render with a 32 px ramp. A vignette darkens the sides of the road and the bottom, which hides the outpaint seam. Top 27% darkened to 0.84. Centre crop from 1088 wide. WebP q94 |
| `share-card.png` | none, made from `key-art.webp` | none | `key-art.webp` scaled to 0.64, with a 1200×630 window at (10, 40) | Top 22% darkened to 0.84. 256 colours (libimagequant, dithered), because a full-colour PNG is 693 KB. JPEG was not needed |
