# Real-device checklist (FAL-1042, #187)

One pass on each of: a real iPhone (Safari), an Android phone (Chrome) and a school
Chromebook (Chrome). A person does this: the WebKit job in CI (`tests/webkit`) is an
iPhone profile in a desktop WebKit, so it can't show memory pressure, a real Safari
toolbar or a school network.

**Build id:** the small "Build xxxxxxx" at the bottom right of the title screen. Write it
down first, and check it is the build you meant to test (a stale one means the worker
served an old copy: reload once more).

Use the live test site, with a fresh browser profile or private window (the first-run
screens only show on a blank save). Note device, OS and browser version, build id, and pass
or fail for each line. For a fail, say what happened and take a screenshot.

## Per device

1. **Loads.** The title shows in under about 30 seconds on the school network. Note how long.
2. **First run.** Play asks which course; pick AA SL, Continue. The map opens.
3. **Taps.** Scrap Fields, Sequences and series (tap twice to go in each), Start a run at mile 1.
   Skip the four cards. Every tap lands on what you touched, none on something beside it.
4. **A fight.** Answer one multiple-choice question and one typed one with the on-screen
   keypad (a fraction too). Lock in works. The text is readable without zooming.
5. **Timer.** Note the seconds left, switch to another tab (or another app on a phone)
   for 20 seconds, come back. The seconds are the same, give or take one.
6. **Background and return.** Start a fight, lock the phone for a minute, unlock. The game is
   still there. If the page reloaded, check that the title, not a blank page, comes back and
   Scrap is not lost.
7. **Quit and the summary.** Quit shows Run over with Scrap earned. The buttons all work.
8. **Save.** Reload the page. The Scrap in the bank is still there and the course is not
   asked again.
9. **Rotation (phones).** Turn the phone sideways and back mid-fight. The layout recovers.
10. **Sound.** Nothing plays until the first tap. The mute button works.
11. **Memory.** After about 10 minutes of play, did the tab reload on its own? (iOS drops
    tabs under memory pressure: the pack is about 45 MB.)

## Report

Add a comment to #187 with a table: device, OS, browser, build id, lines that failed.
