# Encounters

Rare talking events on the road: a Meet, a Deal or a Standoff takes the place of one fight. The questions are the island's ordinary recipe questions. These files hold only the words around them; the game holds every number (damage, heals, Scrap, how often). Full design: the spec on FAL-347.

| File | What it is |
|---|---|
| `signal-tower.json` | The Signal Tower set (Functions): a list of encounters. |
| `cell.json` | The Cell, where every `lockup` bust lands, on every island. One object: its damage type and its line lists. |
| `damage-types.json` | The damage flashes every encounter picks from, shared by every island. A list of types. |

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
  "damage": "plain",
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
- `damage`: the `id` of one type in `damage-types.json`, or `plain` for an ordinary hit with no flash. Every miss in the encounter shows that type's `flash` beside the hit number, after the answer. The miss that busts a Deal or a Standoff shows it with CRITICAL in front (CRITICAL EMOTIONAL DAMAGE); the game adds that word, so don't write it. A Meet's last miss shows the ordinary flash. It changes the flash, never the HP. Pick the type by its `use` line, and write the `miss` and `bust` lines so each one and the flash land as one joke. The flash hits the character in the scene (the offer, the form, the hat), never the student's maths. Fights and Ambush fights stay plain.
- `rare: true` marks an easter egg. It shows as "???" in Field Notes until found.
- `title`: at most 4 words. `note`: the Field Notes line, at most 20 words. A student reads it when looking back, so make it worth re-reading.
- `take_label` (at most 3 words) and `walk_on`: Meet and Deal only. The other button always says "Walk on". A Standoff has one button, "Go on", and neither field.
- `right` plays in order after each right answer except the one that gets you through, which plays `win`. Write at least 3. Misses can fall between them, so each `right` line has to make sense after a miss too.
- `miss` plays after a miss that doesn't bust. Write at least 2. The miss that busts plays `bust`. A miss never undoes progress, so no miss line says it does. The game starts at a different `miss` line on each run, so they can come in any order, and a Deal or Standoff only plays one before the bust. Every `miss` line has to work as the first one, and has to set up the `bust` on its own.
- `cast.voice` stands in for a full voice sheet for a one-off character. Gear Mira, Dax and Noma stay out of encounters. A `spark` line follows Spark's block in `../voice-sheets.md`.

`cell.json` has `damage` (a type `id`, shown on every hunger tick, after a right answer or a wrong one), `open`, `right` (a bar works loose; at least 2), `miss` (at least 2), `hunger` (said when a hunger tick lands; at least 3), `escape`, and `thrown_out` (the guard gives up after six questions). It is shared by every island, so it names nothing island-specific.

## Damage types

Each entry in `damage-types.json` is one type:

```json
{ "id": "emotional", "flash": "EMOTIONAL DAMAGE", "use": "A cold refusal or a put-down." }
```

- `id`: lower case, one word. Permanent once on `main`, like encounter IDs.
- `flash`: upper case, ending in DAMAGE, at most 22 characters, so CRITICAL still fits in front on a 360 px phone.
- `use`: at most 12 words, telling a later writer when to pick it.
- A new type hits the character in the scene: their offer, their paperwork, their dignity, their wallet, their eardrums. Never the student's maths or brain, never a real injury or medical condition, and nothing about bodies, looks or who someone is. A science joke has to be right. The rest is in `../../TONE.md` under "Damage flashes".

## Rules for the lines

- **Every bubble is at most 70 characters**, so it fits two lines on a 360 px phone.
- **Any question on the island has to fit.** No line names the question's maths or hints at an answer. The question card sits under the bubble.
- **No numbers for stakes or prizes.** The game shows HP and Scrap in a chip. Lines don't promise "double" or "a lot".
- **Every number in a line is checked**, and the checks go in the hand-off. Ask Curriculum Author when unsure.
- Nobody calls a question easy, and no line genders the player (see `../voice-sheets.md`).
- Check every line against `../../TONE.md` too. The IB-survivor undertone is subtext: no line says "IB", and an encounter gets one wink at most, and plenty get none.
- Short text: draft with `game-dialogue`, then one `humanizer` pass.

Check before a pull request:

```sh
cd writing/encounters
jq . damage-types.json > /dev/null && jq . signal-tower.json > /dev/null && jq . cell.json > /dev/null
jq -r '.[].lines[][]' signal-tower.json | awk 'length > 70 {print length": "$0}'
jq -r '.[] | arrays | .[]' cell.json | awk 'length > 70 {print length": "$0}'
ok=$(jq -c '[.[].id, "plain"]' damage-types.json)
jq -r --argjson ok "$ok" '.[] | select(.damage | IN($ok[]) | not) | "bad damage: \(.id) \(.damage)"' signal-tower.json
jq -r --argjson ok "$ok" 'select(.damage | IN($ok[]) | not) | "bad damage: cell \(.damage)"' cell.json
jq -r '.[] | select((.flash | length) > 22 or (.flash | test("^[A-Z ]+ DAMAGE$") | not) or (.use | split(" ") | length) > 12) | "bad type: \(.id)"' damage-types.json
```

The `jq .` line fails on broken JSON. The lines after it print nothing when the files pass: every bubble fits, every `damage` is `plain` or a type `id`, and every type has a short upper-case flash ending in DAMAGE and a `use` of at most 12 words.

Written on FAL-348. Damage types added on FAL-352.
