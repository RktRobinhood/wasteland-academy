# Encounters

Rare talking events on the road: a Meet, a Deal or a Standoff takes the place of one fight. The questions are the island's ordinary recipe questions. These files hold only the words around them; the game holds every number (damage, heals, Scrap, how often). Full design: the spec on FAL-347.

| File | What it is |
|---|---|
| `signal-tower.json` | The Signal Tower set (Functions): a list of encounters. |
| `cell.json` | The Cell, where every `lockup` bust lands, on every island. One object of line lists. |

New islands get their own `<island>.json` in the same format. A shared wasteland set, when there is one, goes in `wasteland.json`.

## The format

```json
{
  "id": "st-coffee-cart",
  "island": "signal-tower",
  "kind": "meet",
  "rare": false,
  "title": "The Coffee Cart",
  "note": "One line for Field Notes, at most 20 words.",
  "cast": {
    "name": "Name or nickname",
    "look": "One line for the Artist: side-on, what they wear and carry.",
    "voice": "What they want; how they talk; one tic."
  },
  "prize": "heal",
  "bust": "none",
  "take_label": "Buy a coffee",
  "lines": {
    "open": ["At most 2 bubbles."],
    "walk_on": ["Their reaction when you walk on."],
    "right": ["After the 1st right answer.", "After the 2nd.", "After the 3rd, for longer ones."],
    "miss": ["After a miss that isn't a bust.", "Another one."],
    "win": ["1 or 2 bubbles when you get through."],
    "bust": ["1 or 2 bubbles when it goes bad. For lockup or ambush, this leads into it."],
    "spark": ["Optional. At most one Spark line."]
  }
}
```

- `id` starts with the island's prefix (`st-` for Signal Tower), lower case with hyphens. IDs are permanent once on `main`, because saves store them.
- `kind`: `meet`, `deal` or `standoff`.
- `prize`: `heal` or `scrap` for a Meet; `heal`, `lifeline` or `scrap` for a Deal; `scrap` for a Standoff.
- `bust`: `none` for a Meet; `lockup` or `ambush` for a Deal; `big_trap` for a Standoff.
- `rare: true` marks an easter egg. It shows as "???" in Field Notes until found.
- `title`: at most 4 words. `note`: the Field Notes line, at most 20 words. A student reads it when looking back, so make it worth re-reading.
- `take_label` (at most 3 words) and `walk_on`: Meet and Deal only. The other button always says "Walk on". A Standoff has one button, "Go on", and neither field.
- `right` plays in order after each right answer except the one that gets you through, which plays `win`. Write at least 3. Misses can fall between them, so each `right` line has to make sense after a miss too.
- `miss` plays after a miss that doesn't bust. Write at least 2. The miss that busts plays `bust`. A miss never undoes progress, so no miss line says it does.
- `cast.voice` stands in for a full voice sheet for a one-off character. Gear Mira, Dax and Noma stay out of encounters. A `spark` line follows Spark's block in `../voice-sheets.md`.

`cell.json` has `open`, `right` (a bar works loose; at least 2), `miss` (at least 2), `hunger` (said when a hunger tick lands; at least 3), `escape`, and `thrown_out` (the guard gives up after six questions). It is shared by every island, so it names nothing island-specific.

## Rules for the lines

- **Every bubble is at most 70 characters**, so it fits two lines on a 360 px phone.
- **Any question on the island has to fit.** No line names the question's maths or hints at an answer. The question card sits under the bubble.
- **No numbers for stakes or prizes.** The game shows HP and Scrap in a chip. Lines don't promise "double" or "a lot".
- **Every number in a line is checked**, and the checks go in the hand-off. Ask Curriculum Author when unsure.
- Nobody calls a question easy, and no line genders the player (see `../voice-sheets.md`).
- Short text: draft with `game-dialogue`, then one `humanizer` pass.

Check before a pull request:

```sh
jq . writing/encounters/signal-tower.json > /dev/null && jq . writing/encounters/cell.json > /dev/null
jq -r '.[].lines[][]' writing/encounters/signal-tower.json | awk 'length > 70 {print length": "$0}'
jq -r '.[][]' writing/encounters/cell.json | awk 'length > 70 {print length": "$0}'
```

The last two print nothing when every bubble fits.

Written on FAL-348.
