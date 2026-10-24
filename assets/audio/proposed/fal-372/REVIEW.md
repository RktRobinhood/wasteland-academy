# FAL-372 SFX technical review

Seven proposed Kenney CC0 effects for Salvage Neon Bazaar. Library-first round, zero GPU renders; no generation defect to justify GPU use. All 10 local pack categories searched; interface and casino packs supply the selected short mechanical/tonal gestures. Voice, weapons, explosions and error buzzers excluded. Wrong answer uses filtered `pluck_002.ogg`; whether this reads as a kind comic beat remains Matt’s listening decision. No claim of listening is made.

| File | Seconds | LUFS-I¹ | dBTP | Edge silence ms start/end² | Energy >6kHz |
|---|---:|---:|---:|---:|---:|
| ui-confirm-01.wav | 0.022 | -27.75 | -1.10 | 0.07/0.63 | 0.127% |
| answer-correct-01.wav | 0.523 | -14.90 | -1.10 | 0.09/1.68 | 0.000% |
| answer-retry-01.wav | 0.141 | -21.45 | -1.10 | 0.05/1.95 | 0.057% |
| hint-relay-01.wav | 0.224 | -18.63 | -1.10 | 0.23/1.90 | 0.080% |
| scrap-reward-01.wav | 0.158 | -28.55 | -1.13 | 1.84/2.00 | 12.995% |
| encounter-open-01.wav | 0.148 | -15.49 | -1.09 | 1.77/0.02 | 24.201% |
| encounter-clear-01.wav | 0.487 | -12.32 | -1.10 | 1.09/1.95 | 0.000% |

¹ ffmpeg loudnorm input measurement, each exact export padded with digital silence to one second **for measurement only**. Short effects have no specified integrated target; this fixed measurement window makes sub-400ms effects measurable. These readings are not the music target of −18 LUFS. Exports retain natural duration and peak near −1.1 dBTP. Proposed runtime gain is 0.16 (−15.9dB), with clear at 0.10 (−20dB), avoiding classroom startle and making the dense completion quieter. Preview exports use −1dB additional codec headroom but do not reflect runtime attenuation.

² Threshold −60dBFS. All endpoints exactly zero; 5ms linear edge tapers; active content trimmed at −50dB relative to source peak. No looped SFX; loop seam tests not applicable. Spectrograms accompany each candidate; high-frequency energy measured above 6kHz. No voiced content selected, no long ambience tails. Spectrum and measurements cannot establish perceived kindness or style.

Recommendation: review this one cohesive palette as the first option. Retry is only 141ms with 2kHz low-pass and a short tail; completion 487ms. All seven pass duration, PCM16/44.1kHz/mono, edge, and true-peak gates. No generation required unless listening rejects a specific library cue.

## Game integration and approval gate

`js/sfx.js` provides opt-in, default-off, single-voice playback, quiet gain, hidden-tab stop and safe autoplay/missing-file handling. `audition.html` uses the actual controller. `runtime-integration.patch` is staged against the game: adds the script, an accessible sound toggle, offline caching, answer feedback, lifeline and clear cues. Reward and open are available for sparse future use; no sound on every keypad press or countdown. Activation awaits Studio Manager acceptance and Matt’s one palette decision, as required by the Audio Designer instructions. Normal game entry point is unchanged during review.

Source licences: [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds), [Kenney Casino Audio](https://kenney.nl/assets/casino-audio). Kenney credited for every export in `assets/audio/CREDITS.md`. Shared raw files stay outside the repo. Sonniss excluded because the game repo is public; Freesound API not used.
