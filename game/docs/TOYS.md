# Lesson toys

The interface every explainer toy shares (#217), so a new toy plugs into the lesson
player (#218) with no change to the player. The first toy is the relay; the catalogue of
the rest is #221.

## The pieces

| File | What it is |
|---|---|
| `ui/toys/lesson_toy.gd` | `LessonToy`, the base every toy extends: the signals, the task in hand, the board lines, reduced motion |
| `ui/toys/toys.gd` | `Toys`, the registry: toy ids to scripts, `check` and `make` |
| `ui/toys/relay_toy.gd` | `RelayToy`, the relay (Functions, Rook) and its broken variant |
| `ui/toy_screen.gd`, `scenes/toy.tscn` | A toy on its own, as a test bench: `/?toy=relay` |
| `tests/test_relay_toy.gd` | The relay and the interface, driven by touch at a 390 px phone and by scripted actions |

## What the lesson player does with a toy

The lesson player is `ui/lesson/lesson_player.gd` (`docs/LESSONS.md`). The script's `toy` item names the toy by id and carries its set-up and its tasks. The
player hands the item to `Toys.make`, sizes the toy into the board, and gives it the tasks
one at a time. It never looks at which toy it has.

```gdscript
var toy := Toys.make(item)                 # null if Toys.check(item) has errors
toy.reduced_motion = LessonToy.reduce_motion(save)
toy.acted.connect(on_act)                  # every player action
toy.task_done.connect(on_done)             # the task in hand is met
board.add_child(toy)
toy.start(item.tasks[0])
```

- **`acted(action)`** fires on every action. `action.hit` is `true`, `false`, or `null`
  for an action no task marks (a free send). On `false` the player plays a stock
  reaction line (#220); the toy has already shown the cost in its world. `action.board`
  is the line the toy wrote on its log, if any.
- **`task_done(result)`** fires once the task is met: `{"kind", "actions", "misses"}` plus
  the toy's own fields. The player moves the lesson on. Between tasks the toy still
  answers, as free play.
- **`then` and `optional`** belong to the player, not the toy: it plays a task's `then`
  beats once the task is met, and offers "Try it" or "Skip" before an optional toy.
- **No fail state.** A toy never ends a task on a miss, never counts down and keeps no
  score. A miss happens in the world and the player goes again.

## What a toy provides

A toy extends `LessonToy` and overrides:

| Method | Does |
|---|---|
| `static check_spec(item) -> PackedStringArray` | The item's errors, as sentences. Empty when the toy can be built. The checker and `Toys.make` both use it. |
| `setup(item)` | Reads the item. Call `super(item)` first. |
| `start(task)` | Takes one task. Call `super(task)` first. An unknown kind plays as free play. |
| `kinds() -> PackedStringArray` | The task kinds it supports. |
| `script_for(task, with_miss) -> Array` | The actions that meet a task, for scripted runs, tests and the capture. With `with_miss`, the first action misses where the task can be missed. |
| `perform(action)` | Does one of those actions by the same path a tap takes. |

and calls two helpers from the base:

- `_report(action)` for every player action. It counts, keeps `board`, adds the task kind
  and emits `acted`.
- `_finish(extra)` when the task is met. It emits `task_done` and clears the task.

Then it adds its id to `Toys.IDS`. That is the whole change for a new toy.

## Touch, size and motion

- The toy fills the rectangle the player gives it, portrait at phone width first. Every
  control a finger uses is at least `RelayToy.TOUCH` (150) base units tall, about 54 px
  on a 390 px phone.
- Read the mouse events only. A finger arrives as the mouse as well
  (`emulate_mouse_from_touch` is on), so reading both moves a control twice.
- `reduced_motion` is set by the host from `LessonToy.reduce_motion(save)`: the save's
  `settings.reduced_motion` (its switch on the settings screen comes with #196) or the
  browser's `prefers-reduced-motion`. With it on a toy cuts instead of animating and
  holds still instead of flickering. The cost of a miss must still show.
- Placeholder art is drawn in the Salvage Ink colours (`Explainer.INK`, `CHALK` and the
  rest). Real art comes through the prompt-card loop (#201).

## The relay

```json
{"toy": "relay", "rule": "x² − 4", "dial": [-5, 5], "places": {"12": "Scrap Fields"},
 "tasks": [{"kind": "free", "count": 3}, {"kind": "send", "input": -3}, {"kind": "find", "output": 12}]}
```

| Field | Meaning |
|---|---|
| `rule` | The rule in `x`, as the expression engine reads it (`engine/expr.gd`). `x² − 4`, `x^2 - 4` and `6 - 2x` all work. |
| `dial` | The dial's least and greatest whole numbers. `[-5, 5]` if left out. |
| `label` | Optional. Written on the box, such as `f` once the lesson has named it. |
| `places` | Optional. Settlements on the map strip, by output. |
| `broken` | Optional. A second rule: every input then gives two outputs at once (oupa's radio, "that's no function"). |

| Task | Met when | A miss |
|---|---|---|
| `{"kind": "free", "count": 3}` | that many sends | never |
| `{"kind": "send", "input": -3}` | that input is sent | any other input |
| `{"kind": "find", "output": 12, "place": "Scrap Fields"}` | any input that gives the output. `result.answers` lists them all (`[-4, 4]`) | any other output |

A send writes `in −3 → out 5` on the toy's log (`in 2 → out 0 and 8` on the broken
relay). The signal runs up the wire to a pin on the map strip. A miss still goes out: the
line is written in rust, static covers the box, and the pin lights on the wrong part of
the map.

Actions for `perform`: `{"send": n}` turns the dial to `n` and throws the switch;
`{"dial": n}` only turns it. By hand: the − and + keys, a tap on either half of the dial,
a drag along it (one step per 70 units), the arrow keys, and the switch.
