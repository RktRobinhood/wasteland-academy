# Audio credits — Wasteland Academy

Every audio file this repository ships has an entry here: source or model,
licence, what was changed, and its SHA-256.


## FAL-372 — accepted free-library SFX palette

Accepted by Matt on 2026-10-24; integrated with quiet opt-in playback. Downloaded shared library 2026-10-24; official source pages and packaged CC0 licences checked. No generation or AI input audio.

### assets/audio/proposed/fal-372/ui-confirm-01.wav

- Source/author: Kenney, interface-sounds; original `click_001.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 3200Hz; trim to active content (cap 0.25s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `82988d82e27e2713360fa0afba3bfdb5cb3e94bfa8fb05d1c776b4e116b02539`

### assets/audio/proposed/fal-372/answer-correct-01.wav

- Source/author: Kenney, interface-sounds; original `confirmation_002.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 4500Hz; trim to active content (cap 0.8s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `598d7e9fa84e4262e609205383ada6b19a788953825947e50c311a2680d2fea5`

### assets/audio/proposed/fal-372/answer-retry-01.wav

- Source/author: Kenney, interface-sounds; original `pluck_002.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 2000Hz; trim to active content (cap 0.55s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `41b3420be368e299957354980f30bcb02f4649257dc42f5179360725d513b7fc`

### assets/audio/proposed/fal-372/hint-relay-01.wav

- Source/author: Kenney, interface-sounds; original `switch_003.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 3500Hz; trim to active content (cap 0.6s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `b18b79422c8016a5e88cc40e520048043a219c684f98e6c2ce74938fb0d8c239`

### assets/audio/proposed/fal-372/scrap-reward-01.wav

- Source/author: Kenney, casino-audio; original `chips-collide-2.ogg`.
- URL: https://kenney.nl/assets/casino-audio
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 3800Hz; trim to active content (cap 0.65s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.025306s.
- SHA-256: `bacc3648a29dac99c3c1a71e87914d49ab1c4bd868dd366745b3fdf50f5b9983`

### assets/audio/proposed/fal-372/encounter-open-01.wav

- Source/author: Kenney, interface-sounds; original `open_001.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 3800Hz; trim to active content (cap 0.6s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `496caa309b931e901cbb6b69e5f41106ee5caddcfcd2bf5c163f457e9d27f94c`

### assets/audio/proposed/fal-372/encounter-clear-01.wav

- Source/author: Kenney, interface-sounds; original `confirmation_004.ogg`.
- URL: https://kenney.nl/assets/interface-sounds
- Licence: CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/
- Changes: Mono 44.1kHz PCM16; high-pass 65Hz, low-pass 4500Hz; trim to active content (cap 0.8s); 5ms edge fades; linked static gain to -1.1dBTP. Source trim begins at 0.000000s.
- SHA-256: `227bee690a3fa9d1e80d3646d37289662c05ee7a039331ea1a392c6310bcc9b1`

## FAL-371 — proposed location and boss music

Rounds 2–3. Studio Manager approved the set on FAL-371 and recommended two seeds per cue; Matt's listening choice is still open. The twelve loops the Godot build plays are copies of these files, recorded again under FAL-385 below. Generated locally with Stable Audio 3 using original text prompts, no source recordings. Model `stable_audio_3_medium.safetensors`; encoder `t5gemma_b_b_ul2.safetensors`; 8 steps, cfg 1, lcm, simple; optional Qwen expansion bypassed for full authored prompts and VRAM economy. Date: 2026-10-24.

Rights basis: [Stability AI Community License](https://stability.ai/community-license-agreement), checked 2026-10-24. Free model use below US$1M yearly revenue subject to terms. As between us and Stability, outputs owned to the extent permitted by applicable law. Never use outputs to train another model. No Kenney, Sonniss or Freesound recordings included.

### assets/audio/proposed/fal-371/round2/overworld-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 72 BPM. Downtempo trip-hop with warm analog pads, sparse twangy electric guitar, softly overdriven bass, dusty brushed drums and little plucked synth motifs; curious hopeful travel.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.333333s; rotation 683550 samples; exported length 106.666667s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.00 LUFS-I, -4.92dBTP.
- SHA-256: `7eae2c337d5f5d250f97f40ae356fe43fec0ef16f4cea227275ea08235415423`

### assets/audio/proposed/fal-371/round2/overworld-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 72 BPM. Downtempo trip-hop with warm analog pads, sparse twangy electric guitar, softly overdriven bass, dusty brushed drums and little plucked synth motifs; curious hopeful travel.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.333333s; rotation 738675 samples; exported length 106.666667s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -5.48dBTP.
- SHA-256: `033a4e2e39fba2bd54af77fe4e88d23deabee54ef8f29aa27730895a9657b9d2`

### assets/audio/proposed/fal-371/round2/overworld-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 72 BPM. Downtempo trip-hop with warm analog pads, sparse twangy electric guitar, softly overdriven bass, dusty brushed drums and little plucked synth motifs; curious hopeful travel.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.333333s; rotation 540225 samples; exported length 106.666667s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -3.70dBTP.
- SHA-256: `92eee11ab16ed8d0f6b32734de3b16cade8103524217d5fa79abd876d06ef1c5`

### assets/audio/proposed/fal-371/round2/scrap-fields-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 2899575 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -5.88dBTP.
- SHA-256: `6933e86100c9161ba2eb93af6dcc70e94b4266faaaf467dea608361006772d00`

### assets/audio/proposed/fal-371/round2/scrap-fields-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 882000 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -5.48dBTP.
- SHA-256: `2ebc5287b92efb2b7b0017505b52e1dcd865c861328fb6fd302429b6a02a0bb5`

### assets/audio/proposed/fal-371/round2/scrap-fields-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 220500 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -4.82dBTP.
- SHA-256: `16131722ff40129daefc3ce44fed5200f2829c77f6451146327820e460f6d47c`

### assets/audio/proposed/fal-371/round2/scrap-fields-boss-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 1896300 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -3.28dBTP.
- SHA-256: `31d5251d9f194fde8ed579cd5e331e65cb4ee61558a67ae370a069dcacd1376a`

### assets/audio/proposed/fal-371/round2/scrap-fields-boss-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 3671325 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -4.59dBTP.
- SHA-256: `4b63d7e8b2743eb88e1492311f5eb416bbf65f2a25b2755531ac4653ffdaa47d`

### assets/audio/proposed/fal-371/round2/scrap-fields-boss-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 231525 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -2.53dBTP.
- SHA-256: `cd426c0735c99420fb8cf931bbe3add187aae527fccf02528315a009c7c58857`

### assets/audio/proposed/fal-371/round2/signal-tower-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 2050650 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.00 LUFS-I, -5.41dBTP.
- SHA-256: `1a4e68efe3e45f162b5f3b9e68f76958e38377de425f8741c18a66089de04943`

### assets/audio/proposed/fal-371/round2/signal-tower-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 286650 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -2.21dBTP.
- SHA-256: `17d0aa3691f93e8ecfa90a95a5b949b2b6e716a71f4ed63fe1374d00f26ba602`

### assets/audio/proposed/fal-371/round2/signal-tower-boss-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 66150 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter True. Exact mastering filter: `volume=0.010000000000001563dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.05 LUFS-I, -2.17dBTP.
- SHA-256: `ec5097658d4506744165fb9a8e785b37b8924444c0354e145df4996cf417a959`

### assets/audio/proposed/fal-371/round2/signal-tower-boss-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 2017575 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -2.97dBTP.
- SHA-256: `6885a60c48bda9bf8e80b76f6a25e2687f41be83d30cf240afe224ef7c31be97`

### assets/audio/proposed/fal-371/round2/dry-flats-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 4310775 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.01 LUFS-I, -5.29dBTP.
- SHA-256: `d7bcb14d837ef724ab525e1bd7e4745eb49c6bed712424d52889880b60be8bfa`

### assets/audio/proposed/fal-371/round2/dry-flats-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 584325 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -4.47dBTP.
- SHA-256: `705ab5fe142159986325ed90d6389adc595bed816287b972d3c4ea02677b4746`

### assets/audio/proposed/fal-371/round2/dry-flats-boss-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 584325 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -4.63dBTP.
- SHA-256: `2fcb12b1c31b93b54d2e399f3452918352ac8cb6e6f70bb7bcf4871a50ce02f7`

### assets/audio/proposed/fal-371/round2/dry-flats-boss-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 584325 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -3.58dBTP.
- SHA-256: `e54b661f9114f307df165536b4c919e247f5b7f38bde2682684dbe6f11924ec3`

### assets/audio/proposed/fal-371/round2/dry-flats-boss-r2-seed37203-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 275625 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.04 LUFS-I, -2.16dBTP.
- SHA-256: `a3295776c2b254ecc36013dec0009c9f0f0fa7d516702875b4b6d8de7efe350e`

### assets/audio/proposed/fal-371/round2/radio-spires-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 3980025 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.97 LUFS-I, -5.17dBTP.
- SHA-256: `6897e5b5970643c8ff618696c1475315e8bbaf48ad2fa10f5a1c19248d6c2ed1`

### assets/audio/proposed/fal-371/round2/radio-spires-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 4002075 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -3.67dBTP.
- SHA-256: `9b1517d96079934174e47b34eb7ec6975e9d9e9da2e830169249fa76d5bdd3ed`

### assets/audio/proposed/fal-371/round2/radio-spires-boss-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 77175 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.97 LUFS-I, -3.01dBTP.
- SHA-256: `f52a691dac1e4f12b7e0e46d965674c0de7c92bb08d685e34196a0c10b4bbd17`

### assets/audio/proposed/fal-371/round2/radio-spires-boss-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 606375 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -4.79dBTP.
- SHA-256: `acf0a154bc424cf54a0cae0665ebfaec1721dfb05db8f2491058f34b4c649c35`

### assets/audio/proposed/fal-371/round2/engine-core-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 88 BPM. Restrained industrial metal and downtempo techno. Audible repeating palm-muted distorted electric guitar riff and gritty electric bass, steady sequencer pulse, controlled piston-like kick, low toms and warm filtered chords. Persistent mechanical momentum, rounded distortion and no harsh cymbals.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 1289925 samples; exported length 87.272721s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.00 LUFS-I, -3.73dBTP.
- SHA-256: `28590545fb19260756a0601aaa83b0e221c0e4213072c563c51bd5511751c41e`

### assets/audio/proposed/fal-371/round2/engine-core-boss-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 88 BPM. Restrained industrial metal and downtempo techno. Audible repeating palm-muted distorted electric guitar riff and gritty electric bass, steady sequencer pulse, controlled piston-like kick, low toms and warm filtered chords. Persistent mechanical momentum, rounded distortion and no harsh cymbals. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 3572100 samples; exported length 87.272721s.
- Additional repair: compression True; static gain with oversampled peak limiter True. Exact mastering filter: `volume=5.039999999999999dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.02 LUFS-I, -2.42dBTP.
- SHA-256: `ff3c9ed01ab5ce755f9e6d0346f92cb3e3d204ca8e3b05f5c3f4d4bd341fe72d`

### assets/audio/proposed/fal-371/round2/engine-core-boss-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 88 BPM. Restrained industrial metal and downtempo techno. Audible repeating palm-muted distorted electric guitar riff and gritty electric bass, steady sequencer pulse, controlled piston-like kick, low toms and warm filtered chords. Persistent mechanical momentum, rounded distortion and no harsh cymbals. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 2491650 samples; exported length 87.272721s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.00 LUFS-I, -3.52dBTP.
- SHA-256: `e66c5c4b0e9bb511893a2f91c4cf3886056a2431e69e006e9ff16d1dfdbb7b58`

### assets/audio/proposed/fal-371/round2/thunderdome-r2-seed37201-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 96 BPM. Retro wasteland arena industrial heavy metal with tribal rock groove. Prominent down-tuned palm-muted electric guitar power-chord riff and distorted bass, scrap-barrel toms, slow stomping half-time drums, weathered analog brass and synth drone. Theatrical improvised arena ritual, stubborn courage and hard-won hope, energetic but controlled, no crowd or chants, no borrowed theme or recognizable melody.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.500000s; rotation 474075 samples; exported length 80.000000s.
- Additional repair: compression True; static gain with oversampled peak limiter True. Exact mastering filter: `volume=5.390000000000001dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.02 LUFS-I, -2.75dBTP.
- SHA-256: `992c9a353ac60e7eb159d66fd05b15cad4094e654c56c2855ac862e969628b57`

### assets/audio/proposed/fal-371/round2/thunderdome-r2-seed37202-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 96 BPM. Retro wasteland arena industrial heavy metal with tribal rock groove. Prominent down-tuned palm-muted electric guitar power-chord riff and distorted bass, scrap-barrel toms, slow stomping half-time drums, weathered analog brass and synth drone. Theatrical improvised arena ritual, stubborn courage and hard-won hope, energetic but controlled, no crowd or chants, no borrowed theme or recognizable melody.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.500000s; rotation 209475 samples; exported length 80.000000s.
- Additional repair: compression True; static gain with oversampled peak limiter True. Exact mastering filter: `volume=4.629999999999999dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.02 LUFS-I, -3.05dBTP.
- SHA-256: `0d0a72377aba4d061ae7e09d205f841917e71cbdb9c2acd76264b6220072ec46`

### assets/audio/proposed/fal-371/round2/engine-core-r3-seed37301-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental music for an industrial engine region in a neon wasteland study game, 88 BPM, 4/4. Restrained industrial metal and downtempo techno. Continuous sustained distorted electric guitar chords and warm analog synth drone under a simple steady legato electric bass line, soft low drum groove, gentle piston pulse. Smooth dense underlying harmonic bed remains clearly audible between every drum hit. Rounded distortion and warm midrange, quiet hopeful mechanical persistence. Moderate stable dynamics for classroom maths concentration. Continuous unbroken texture, no rhythmic stops or gated silences, no breakdown, no intro or outro, no solo, no singing, no speech, no crowd. Repeating eight-bar phrases with subtle harmonic variation, original composition.
- Seed: `37301`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 374850 samples; exported length 87.272721s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `loudnorm=I=-18:TP=-2:LRA=11:measured_I=-14.02:measured_TP=1.95:measured_LRA=2.20:measured_thresh=-24.02:offset=-0.28:linear=true`.
- Measured: -18.01 LUFS-I, -2.03dBTP.
- SHA-256: `ec6ad7989429c83a9dd0b85b0abfd4c37ea89920a8d356c8ba85440acd234e6c`

### assets/audio/proposed/fal-371/round2/engine-core-r3-seed37302-loop.ogg

- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental music for an industrial engine region in a neon wasteland study game, 88 BPM, 4/4. Restrained industrial metal and downtempo techno. Continuous sustained distorted electric guitar chords and warm analog synth drone under a simple steady legato electric bass line, soft low drum groove, gentle piston pulse. Smooth dense underlying harmonic bed remains clearly audible between every drum hit. Rounded distortion and warm midrange, quiet hopeful mechanical persistence. Moderate stable dynamics for classroom maths concentration. Continuous unbroken texture, no rhythmic stops or gated silences, no breakdown, no intro or outro, no solo, no singing, no speech, no crowd. Repeating eight-bar phrases with subtle harmonic variation, original composition.
- Seed: `37302`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 1907325 samples; exported length 87.272721s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `loudnorm=I=-18:TP=-2:LRA=11:measured_I=-13.26:measured_TP=1.77:measured_LRA=2.30:measured_thresh=-23.26:offset=-0.24:linear=true`.
- Measured: -18.01 LUFS-I, -2.93dBTP.
- SHA-256: `759e44a33454d91baac6f32714bac8d51543bd730d3c82c23e3254864853c05e`

## FAL-385 — the Godot build's music and effects

A Godot project cannot reach outside `game/`, so the files it plays live under
`game/assets/audio/`. Nothing here was re-encoded or re-edited: every file is a
byte-for-byte copy of one recorded elsewhere in this file, under a shorter name.
Which loop plays where is `game/audio/music_tracks.gd`.

### Location music, copied from the FAL-371 proposal

Twelve loops, one per location: the first seed Studio Manager recommended for
each cue. Matt's listening pass has not happened, so each cue also names the
second recommended seed as `alternate` in `game/audio/music_tracks.gd`. The
alternates are not inside `game/`, because everything in there goes into the web
build; they are committed with the rest of the proposal under
`assets/audio/proposed/fal-371/round2/` and recorded in the FAL-371 section above.

Rights basis for all twelve: [Stability AI Community License](https://stability.ai/community-license-agreement),
checked 2026-10-24. Free below US$1M yearly revenue, subject to terms. Never use
these outputs to train another model. No library recordings are in them.

### game/assets/audio/music/overworld-seed37202-loop.ogg

- Plays at: **overworld**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/overworld-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 72 BPM. Downtempo trip-hop with warm analog pads, sparse twangy electric guitar, softly overdriven bass, dusty brushed drums and little plucked synth motifs; curious hopeful travel.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.333333s; rotation 738675 samples; exported length 106.666667s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -5.48dBTP.
- SHA-256: `033a4e2e39fba2bd54af77fe4e88d23deabee54ef8f29aa27730895a9657b9d2`

### game/assets/audio/music/scrap-fields-seed37201-loop.ogg

- Plays at: **scrap-fields**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/scrap-fields-r2-seed37201-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 2899575 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -5.88dBTP.
- SHA-256: `6933e86100c9161ba2eb93af6dcc70e94b4266faaaf467dea608361006772d00`

### game/assets/audio/music/scrap-fields-boss-seed37203-loop.ogg

- Plays at: **scrap-fields-boss**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/scrap-fields-boss-r2-seed37203-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 76 BPM. Lo-fi country rock with a relaxed train rhythm, palm-muted twangy electric guitar, softly distorted baritone guitar riff, warm electric bass, sparse banjo plucks, worn electric piano and tiny scrap clicks. Resourceful rural scavengers, warm and patient. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37203`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.157891s; rotation 231525 samples; exported length 101.052630s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -2.53dBTP.
- SHA-256: `cd426c0735c99420fb8cf931bbe3add187aae527fccf02528315a009c7c58857`

### game/assets/audio/music/signal-tower-seed37202-loop.ogg

- Plays at: **signal-tower**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/signal-tower-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 2050650 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.00 LUFS-I, -5.41dBTP.
- SHA-256: `1a4e68efe3e45f162b5f3b9e68f76958e38377de425f8741c18a66089de04943`

### game/assets/audio/music/signal-tower-boss-seed37202-loop.ogg

- Plays at: **signal-tower-boss**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/signal-tower-boss-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 80 BPM. Minimal industrial post-rock, repeating palm-muted distorted guitar eighth notes quietly under warm relay-like synth arpeggios, rounded electric bass and dry electronic drums. Reassuring repeating signals, calm precision. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.000000s; rotation 2017575 samples; exported length 96.000000s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -2.97dBTP.
- SHA-256: `6885a60c48bda9bf8e80b76f6a25e2687f41be83d30cf240afe224ef7c31be97`

### game/assets/audio/music/dry-flats-seed37202-loop.ogg

- Plays at: **dry-flats**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/dry-flats-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 4310775 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -18.01 LUFS-I, -5.29dBTP.
- SHA-256: `d7bcb14d837ef724ab525e1bd7e4745eb49c6bed712424d52889880b60be8bfa`

### game/assets/audio/music/dry-flats-boss-seed37202-loop.ogg

- Plays at: **dry-flats-boss**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/dry-flats-boss-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 68 BPM. Spacious desert country and slow stoner rock, dusty slide guitar phrases, low fuzzy baritone guitar, warm bass, restrained brushed kick and shaker, airy analog drone. Lonesome open horizon with hopeful suspended harmony. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.529410s; rotation 584325 samples; exported length 112.941179s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.99 LUFS-I, -3.58dBTP.
- SHA-256: `e54b661f9114f307df165536b4c919e247f5b7f38bde2682684dbe6f11924ec3`

### game/assets/audio/music/radio-spires-seed37201-loop.ogg

- Plays at: **radio-spires**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/radio-spires-r2-seed37201-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 3980025 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.97 LUFS-I, -5.17dBTP.
- SHA-256: `6897e5b5970643c8ff618696c1475315e8bbaf48ad2fa10f5a1c19248d6c2ed1`

### game/assets/audio/music/radio-spires-boss-seed37202-loop.ogg

- Plays at: **radio-spires-boss**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/radio-spires-boss-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 74 BPM. Lo-fi broken beat and alternative rock, gently syncopated electric bass, soft overdriven guitar chords, sparse mallet synth and filtered radio grain; warm suspended jazz harmony, curious playful variations, dry restrained drum machine. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 3.243243s; rotation 606375 samples; exported length 103.783787s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `two-pass loudnorm as above`.
- Measured: -17.98 LUFS-I, -4.79dBTP.
- SHA-256: `acf0a154bc424cf54a0cae0665ebfaec1721dfb05db8f2491058f34b4c649c35`

### game/assets/audio/music/engine-core-seed37301-loop.ogg

- Plays at: **engine-core**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/engine-core-r3-seed37301-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental music for an industrial engine region in a neon wasteland study game, 88 BPM, 4/4. Restrained industrial metal and downtempo techno. Continuous sustained distorted electric guitar chords and warm analog synth drone under a simple steady legato electric bass line, soft low drum groove, gentle piston pulse. Smooth dense underlying harmonic bed remains clearly audible between every drum hit. Rounded distortion and warm midrange, quiet hopeful mechanical persistence. Moderate stable dynamics for classroom maths concentration. Continuous unbroken texture, no rhythmic stops or gated silences, no breakdown, no intro or outro, no solo, no singing, no speech, no crowd. Repeating eight-bar phrases with subtle harmonic variation, original composition.
- Seed: `37301`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 374850 samples; exported length 87.272721s.
- Additional repair: compression False; static gain with oversampled peak limiter False. Exact mastering filter: `loudnorm=I=-18:TP=-2:LRA=11:measured_I=-14.02:measured_TP=1.95:measured_LRA=2.20:measured_thresh=-24.02:offset=-0.28:linear=true`.
- Measured: -18.01 LUFS-I, -2.03dBTP.
- SHA-256: `ec6ad7989429c83a9dd0b85b0abfd4c37ea89920a8d356c8ba85440acd234e6c`

### game/assets/audio/music/engine-core-boss-seed37202-loop.ogg

- Plays at: **engine-core-boss**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/engine-core-boss-r2-seed37202-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 88 BPM. Restrained industrial metal and downtempo techno. Audible repeating palm-muted distorted electric guitar riff and gritty electric bass, steady sequencer pulse, controlled piston-like kick, low toms and warm filtered chords. Persistent mechanical momentum, rounded distortion and no harsh cymbals. Boss encounter variation: stronger repeating low distorted guitar riff, firmer electric bass ostinato and driving low toms, tighter rhythmic tension, minor modal harmony with a resilient upward response. Preserve the regional instruments. Controlled urgency rather than fear, sparse melody, steady pulse and clear edit points; no jump scares.
- Seed: `37202`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.727279s; rotation 3572100 samples; exported length 87.272721s.
- Additional repair: compression True; static gain with oversampled peak limiter True. Exact mastering filter: `volume=5.039999999999999dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.02 LUFS-I, -2.42dBTP.
- SHA-256: `ff3c9ed01ab5ce755f9e6d0346f92cb3e3d204ca8e3b05f5c3f4d4bd341fe72d`

### game/assets/audio/music/thunderdome-seed37201-loop.ogg

- Plays at: **thunderdome**
- Copied byte for byte from the FAL-371 proposal `proposed/fal-371/round2/thunderdome-r2-seed37201-loop.ogg`; renamed only.
- Model: `stable_audio_3_medium.safetensors`
- Full prompt: 132-second instrumental game background music, steady 4/4 groove with repeating eight-bar phrases and subtle variation, continuous music from the start, no intro or ending. Salvaged neon wasteland, weathered handmade machines, resilient hopeful survivors. Warm lo-fi production, rounded treble, restrained dynamics, plenty of space for maths concentration. No vocals, no speech, no crowd, no alarm, no sudden drops, no guitar solos. Original composition. 96 BPM. Retro wasteland arena industrial heavy metal with tribal rock groove. Prominent down-tuned palm-muted electric guitar power-chord riff and distorted bass, scrap-barrel toms, slow stomping half-time drums, weathered analog brass and synth drone. Theatrical improvised arena ritual, stubborn courage and hard-won hope, energetic but controlled, no crowd or chants, no borrowed theme or recognizable melody.
- Seed: `37201`
- Date: 2026-10-24
- Generated locally with Stable Audio 3
- Changes: Trim source from 4 seconds; cut 32 bars calculated from the requested BPM (actual beat/bar alignment unverified); one requested-tempo bar of complementary cosine circular crossfade; rotate to a quiet stable source boundary; 88-sample (2ms) edge tapers; two-pass ffmpeg loudnorm toward −18 LUFS-I / −2dBTP before codec; OGG Vorbis q6, 44.1kHz stereo. No speed or pitch change. Preview AAC receives −1dB additional gain for codec headroom.
- Actual edit: source starts at 4s; crossfade 2.500000s; rotation 474075 samples; exported length 80.000000s.
- Additional repair: compression True; static gain with oversampled peak limiter True. Exact mastering filter: `volume=5.390000000000001dB,aresample=176400,alimiter=limit=0.749894:level=false:attack=5:release=50:latency=true,aresample=44100`.
- Measured: -18.02 LUFS-I, -2.75dBTP.
- SHA-256: `992c9a353ac60e7eb159d66fd05b15cad4094e654c56c2855ac862e969628b57`

### Sound effects, mirrored from the HTML game

The seven accepted FAL-372 files, copied into the Godot project so both games
play the same palette under the same cue names. All Kenney CC0 1.0, unedited.

- `game/assets/audio/sfx/ui-confirm-01.wav` — cue `confirm`. Byte-for-byte copy of `assets/audio/proposed/fal-372/ui-confirm-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `82988d82e27e2713360fa0afba3bfdb5cb3e94bfa8fb05d1c776b4e116b02539`, unchanged.
- `game/assets/audio/sfx/answer-correct-01.wav` — cue `correct`. Byte-for-byte copy of `assets/audio/proposed/fal-372/answer-correct-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `598d7e9fa84e4262e609205383ada6b19a788953825947e50c311a2680d2fea5`, unchanged.
- `game/assets/audio/sfx/answer-retry-01.wav` — cue `retry`. Byte-for-byte copy of `assets/audio/proposed/fal-372/answer-retry-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `41b3420be368e299957354980f30bcb02f4649257dc42f5179360725d513b7fc`, unchanged.
- `game/assets/audio/sfx/hint-relay-01.wav` — cue `hint`. Byte-for-byte copy of `assets/audio/proposed/fal-372/hint-relay-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `b18b79422c8016a5e88cc40e520048043a219c684f98e6c2ce74938fb0d8c239`, unchanged.
- `game/assets/audio/sfx/scrap-reward-01.wav` — cue `reward`. Byte-for-byte copy of `assets/audio/proposed/fal-372/scrap-reward-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `bacc3648a29dac99c3c1a71e87914d49ab1c4bd868dd366745b3fdf50f5b9983`, unchanged.
- `game/assets/audio/sfx/encounter-open-01.wav` — cue `open`. Byte-for-byte copy of `assets/audio/proposed/fal-372/encounter-open-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `496caa309b931e901cbb6b69e5f41106ee5caddcfcd2bf5c163f457e9d27f94c`, unchanged.
- `game/assets/audio/sfx/encounter-clear-01.wav` — cue `clear`. Byte-for-byte copy of `assets/audio/proposed/fal-372/encounter-clear-01.wav`, whose Kenney CC0 source, URL and edits are recorded above. SHA-256 `227bee690a3fa9d1e80d3646d37289662c05ee7a039331ea1a392c6310bcc9b1`, unchanged.

## FAL-1132 — Bodge's shop lines, local voice clone (voice)

42 voice files in `game/assets/audio/voice/bodge/lines/`: every line in `game/data/shopkeeper.json` (`lines`: first_visit 3, enter 8, idle 8, buy 8, broke 6, capped 4, leave 5). Each file is named by its text: the first 12 hex characters of the SHA-1 of the exact UTF-8 line, so a line that is later edited stops matching its old take (the rule shared with FAL-1134). The words fed to the model are each line exactly. Generated locally with VoxCPM2 on 2026-11-18. No recordings of any real person went in.

Rights basis: as for FAL-1110 below. VoxCPM2 (OpenBMB) code and weights are released under the [Apache License 2.0](https://github.com/OpenBMB/VoxCPM/blob/main/LICENSE), which allows commercial use; model card https://huggingface.co/openbmb/VoxCPM2. Package `voxcpm` 2.0.3, weights `openbmb/VoxCPM2` from the local Hugging Face cache. The voice is cloned from Bodge's one reference take (`bodge`, SHA-256 `ef8086ebb2233cd37389752baee5d31aafc41765c1c5634febaead2754f7cb83`): Bodge reading the template paragraph, generated with Gemini text-to-speech (`gemini-3.8-flash-tts`, voice `en-au-storyteller-1`, the direction in `teachers.json`) via the Gemini API on 2026-11-17 (FAL-1099). The reference stays in the local falcon-voice repo and doesn't ship. No model was trained or fine-tuned. Matt chose this clone for Bodge on FAL-1110.

- **Cloning:** VoxCPM2 "ultimate" mode: the reference is both `reference_wav_path` and `prompt_wav_path`, and its words are `prompt_text`. cfg 2.0, 10 inference timesteps, denoiser off, text normalisation off. Seed per file below (`torch.manual_seed`): 1099 first, then 1100 for the 6 lines whose words didn't match at 1099.
- **Changes, every file** (falcon-voice `clone/post.sh`): resample the 48 kHz clone to 24 kHz mono; trim silence below −50 dB at both ends; 10 ms fade-in and 40 ms fade-out; 30 ms lead-in and 60 ms tail; then Bodge's approved chain from `teachers.json`, the 2% tape slowdown (`asetrate=23520,aresample=24000`); then falcon-voice `master.sh` (two-pass loudnorm to −16 LUFS, true peak at or below −1 dBTP, 44.1 kHz mono OGG Vorbis q5). No take needed `clone/prelimit.sh`.
- **Checks:** every take transcribed with faster-whisper small (CPU) and compared word by word with the line. All 42 shipped takes match. The six seed-1099 takes that didn't ("stall" heard as "store", "bet" as "bit", "are" as "of", "or" as "we'll", "looking's" as "lookings", "checked" as "check") were replaced by seed 1100, so no mismatch was accepted.
- **Measured across all 42** (music-tools `bin/check`, 4× oversampled true peak): −16.97 to −15.83 LUFS-I, −2.62 to −1.38 dBTP, 2.24 to 7.14 s long, 3.6 minutes in all. The first and last 20 ms of every file are at least 88 dB below its loudest 20 ms.

| File (`game/assets/audio/voice/bodge/lines/`) | Line (`shopkeeper.json`) | Seed | Seconds | LUFS-I | dBTP | Words heard | SHA-256 |
|---|---|---|---|---|---|---|---|
| `856cc3ac3ce6.ogg` | first_visit 1 | `1099` | 5.4 | -16.6 | -1.6 | all | `d567833328224561b91b1abd7538826b0b0c1cda9fafb4c1b8b6f0092a536ca3` |
| `34654fd0dd0d.ogg` | first_visit 2 | `1100` | 6.1 | -16.1 | -1.5 | all | `a35bc2f8765de07d982cb80665c8ee3572b18417657b8dc0b40042a85c53eec5` |
| `2e422429312d.ogg` | first_visit 3 | `1099` | 5.0 | -16.8 | -1.7 | all | `38dbda2c01ca95c6835f0476461dfe382f90410faad2f42d2b204adbdf468462` |
| `85761829a904.ogg` | enter 1 | `1099` | 4.8 | -16.1 | -1.9 | all | `0c798dc87e45e416135a198cf1a98b44648103f7f975866bc1d7acd6749f5c67` |
| `b122862a94cc.ogg` | enter 2 | `1099` | 4.1 | -16.1 | -1.4 | all | `4f7900c7f68a20949bb20c92a1e225789ec3e0ff0ddf6749884f8ca44edececd` |
| `41448294b8c7.ogg` | enter 3 | `1099` | 5.3 | -16.0 | -1.8 | all | `ff9627f6001a7faf2269fc2c5b1f5bf00d74cfe80b70889f149053bf01fd885e` |
| `880f8bf12150.ogg` | enter 4 | `1099` | 5.1 | -16.5 | -1.7 | all | `7863a56612c1067c468044e749ae37f1354896075a30cee696c9fc9cb1808e3b` |
| `96be3be7fc41.ogg` | enter 5 | `1099` | 4.6 | -16.2 | -1.6 | all | `f9e9fbca82770751a0d7baefe102f681c0ce80f73c5c360f21a23d1401aa73fe` |
| `490723d891bd.ogg` | enter 6 | `1099` | 4.9 | -16.2 | -1.8 | all | `c0cfd02e580be77dcb0f4798557fa1a0f7a339cf9844b4eacc510365b5c2a64a` |
| `7254149d01ee.ogg` | enter 7 | `1099` | 4.6 | -15.8 | -1.8 | all | `582c3403c4afed78267754fc0b47ec594c0e89128821e9924400a09623693aa0` |
| `53d6e15ba05e.ogg` | enter 8 | `1100` | 4.8 | -15.8 | -1.7 | all | `554253aa3e9f464fa82bfaf1bcee9a46e7f84c7973e25d4ffb86686928d7e9b0` |
| `f53a9503aeee.ogg` | idle 1 | `1099` | 5.5 | -16.5 | -1.7 | all | `d435be7eabb19fd5c08eaae120d4c6b506e008ce1dee4cf6e25199dc99b0f111` |
| `60cb4a8dbf26.ogg` | idle 2 | `1099` | 5.9 | -16.9 | -1.7 | all | `4f1c6c40af61504b837da6b36a5097331d5d7ac1498b948da9f6e33bc609a236` |
| `7c8b4ded913c.ogg` | idle 3 | `1099` | 4.8 | -16.9 | -1.8 | all | `81bb406d49d32308235ea6ff452e216300f60a273bbde84d21d2de98a2518820` |
| `3c8e592329a6.ogg` | idle 4 | `1099` | 5.8 | -16.0 | -1.8 | all | `4a0f139f3eaeacfa848c777fce25d8ed7c933d844c36203b1f04de3d16a657ae` |
| `b46c337ab603.ogg` | idle 5 | `1099` | 6.2 | -16.4 | -1.8 | all | `01fa7de1057ee3b1ed054a627900b6c4d050c04e521b0666fb9d04bd1caa442c` |
| `cee01fc07c48.ogg` | idle 6 | `1099` | 7.2 | -16.4 | -1.8 | all | `1fe40e9558117996c93da7b60cf8f5b3bb3f80a2cbb439954440665632bc82d1` |
| `9a6dab88811d.ogg` | idle 7 | `1099` | 5.9 | -16.8 | -1.8 | all | `ed34048a628e989f859fd27944ae5484614b016c7c433b74543d985532be0750` |
| `7ee038d7a7a3.ogg` | idle 8 | `1099` | 6.5 | -16.3 | -1.8 | all | `8cd1a6b6b9529fca4b323f34b330418a80b03cf0ce69b3fd906a68f06fbc76e8` |
| `24fce716f89e.ogg` | buy 1 | `1099` | 6.3 | -16.2 | -1.6 | all | `720abed78eb76bc870eff74567ec6386fa2034086a1c9230f88b57db707f0e79` |
| `171f86ab35dc.ogg` | buy 2 | `1099` | 6.1 | -16.4 | -1.7 | all | `ea96a1a9347e62497ebd33b18279837dc76d0be69d24e868b909935591307cff` |
| `a246eb6fe5e1.ogg` | buy 3 | `1099` | 5.1 | -16.0 | -1.6 | all | `fe9eacd5845beb043ee0a10a5447976eecba4ff73c15a65a16bf8262e1344f74` |
| `ada695041fc8.ogg` | buy 4 | `1099` | 5.6 | -16.6 | -1.5 | all | `73df3af624fd48729a6d7c90ec64e9cd3fd86143ec80d31f3317ec9009ab8fc5` |
| `d11947dc06cf.ogg` | buy 5 | `1099` | 6.0 | -16.3 | -1.7 | all | `95bea956f8e82abeaa274b6b821045e8d14cadc88525de644983c9f304d217b2` |
| `05f58aeb3872.ogg` | buy 6 | `1099` | 6.7 | -16.1 | -1.6 | all | `aec2b39160575574c5384acda99083973b10c629febed33988f60e23b8b9e0b8` |
| `10a06e76c751.ogg` | buy 7 | `1099` | 6.1 | -16.4 | -1.7 | all | `9d319f1aa440088dcba7afa09814ad52c49fa97744479744c914555cbee81d6b` |
| `e9a216ea1a2c.ogg` | buy 8 | `1099` | 5.2 | -16.1 | -1.6 | all | `610f84eee9461d9a2b0005412b2692b69b984afb89647ab9dbb7bd61d010a23e` |
| `0c9d3a927e4f.ogg` | broke 1 | `1099` | 5.5 | -16.6 | -1.5 | all | `29e835c6699d2adfb80428cf6af128ef81acfd395389c76891349172b17b2411` |
| `acc4e6b1106c.ogg` | broke 2 | `1099` | 4.7 | -16.4 | -1.8 | all | `4e374f77b539a61b61a43d0949501084bea6d0858b6f4664a70bab3d33bb9bc0` |
| `c401f260929e.ogg` | broke 3 | `1099` | 4.8 | -16.5 | -1.7 | all | `1bd1c3c7b96525ea996f6e1eaa6f08efacefc24728a8e8c9f0971ffd628a9382` |
| `3e1568f4837b.ogg` | broke 4 | `1100` | 4.7 | -16.6 | -1.8 | all | `1905532151df0fc5ce4fbe306647323ba9e39f6a12cf96c86b17e53a89a54362` |
| `8853fc6b214a.ogg` | broke 5 | `1100` | 4.9 | -16.3 | -1.4 | all | `1ea6bcd3c04c4e6ba8f1b6ed167db0790476dee7905279dceb27b37bbd6a3bbe` |
| `acd63e2f0458.ogg` | broke 6 | `1100` | 6.0 | -15.8 | -1.4 | all | `da97a5ef6bd1b4373c6cd5e1a8fcc0c37c8872f6695c3fe658e439a4e487e7a0` |
| `b83ba6b55d0a.ogg` | capped 1 | `1099` | 4.6 | -16.3 | -1.6 | all | `c7538134c9b7316b6bc9fafe91345d709e4bd9d74ad32a2b2a329406de276bc7` |
| `2090295d7969.ogg` | capped 2 | `1100` | 5.7 | -16.4 | -1.5 | all | `3895c3b8b0e8a70ed985c6653aa73e6b76cadff2540def996029dba309660e62` |
| `60bbbc23013a.ogg` | capped 3 | `1099` | 2.24 | -16.0 | -2.6 | all | `b9a8d43afbbed130ff2947b3bd4c8a8e5462fe5137661e800d6faac9f1f6c134` |
| `17d313d3803b.ogg` | capped 4 | `1099` | 2.97 | -16.0 | -2.5 | all | `a6f247dba9b56788738a54e402a1ea483f30d5fe0f9509af3a8f1eb95f72d111` |
| `3a05c401105d.ogg` | leave 1 | `1099` | 5.3 | -16.6 | -1.7 | all | `089116adf2fa6851743bf777ea1f02370165bf7b1b1674955c1384ed1fd29c28` |
| `ccbd0f982e14.ogg` | leave 2 | `1099` | 3.31 | -16.3 | -1.8 | all | `32302ee6bc7db4760acc99422ebe447bf9d89247e8c548e9c3c36428304cf946` |
| `78a8ce046268.ogg` | leave 3 | `1099` | 3.62 | -15.9 | -1.8 | all | `3f05259cecd4819203f9a503c9321b316f4d91fc635a5641fd85796d63940114` |
| `312a7f3bfdf6.ogg` | leave 4 | `1099` | 5.3 | -16.6 | -1.6 | all | `963061a6278673e5858d7a806f31abfc6e6fb5ad645f6c6de646b8e65582069a` |
| `8ca3e4bd0590.ogg` | leave 5 | `1099` | 4.4 | -16.7 | -1.7 | all | `d1b828e06ddbe864a3f7b7e3d14aa9165d174fb579cd67c28ef018b74d995d8d` |

## FAL-992 — Spark's explainer move lines, local voice clone (voice)

162 voice files in `game/assets/audio/voice/spark/moves/`: two takes (`_1`, `_2`) of every move line in `curriculum/moves.json` (81 moves), with the same names and format the game already loads. The words are each move's `say` text exactly, because the explainer captions show them (FAL-991 found none changed). Generated locally with VoxCPM2 on 2026-11-18, replacing the FAL-428 takes of 2026-10-30. No recordings of any real person went in.

Rights basis: as for FAL-1110 below. VoxCPM2 (OpenBMB) code and weights are released under the [Apache License 2.0](https://github.com/OpenBMB/VoxCPM/blob/main/LICENSE), which allows commercial use; model card https://huggingface.co/openbmb/VoxCPM2. Package `voxcpm` 2.0.3, weights `openbmb/VoxCPM2` from the local Hugging Face cache. The voice is cloned from Spark's one reference take (`spark`, SHA-256 `a456ce468559a8da7a6b060a1b90cea785533581abf52f7ec71978e1066ff151`): Spark reading the template paragraph, generated with Gemini text-to-speech (`gemini-3.8-flash-tts`, voice `leda`, the direction in `teachers.json`) via the Gemini API on 2026-11-17 (FAL-1099). The reference stays in the local falcon-voice repo and doesn't ship. No model was trained or fine-tuned. Matt chose this clone for Spark on FAL-1110.

- **Cloning:** VoxCPM2 "ultimate" mode: the reference is both `reference_wav_path` and `prompt_wav_path`, and its words are `prompt_text`. cfg 2.0, 10 inference timesteps, denoiser off, text normalisation off. Seed per file below (`torch.manual_seed`). `_1` takes start at seed 1099, then 1100 to 1103 for a line whose words didn't match; `_2` takes start at 1100 (1100 to 1103, then 1099), so the two takes of a line are never the same render. 152 files kept their first seed. `eliminate_2` passed on 1100, but the take ended mid-word, so it was retaken; seeds 1101 to 1103 all ended cleanly, and 1101 was kept.
- **Text fed to the model** is the `say` line, unchanged.
- **Changes, every file** (falcon-voice `clone/post.sh`): resample the 48 kHz clone to 24 kHz mono; trim silence below −50 dB at both ends; 10 ms fade-in and 40 ms fade-out; 30 ms lead-in and 60 ms tail; then Spark's approved chain from `teachers.json`, `fx/spark-sheen.sh` (2% tape-style slowdown, `rubberband` pitch ×1.189 with shifted formants, `fx/vocoder.py` at 15% wet, high-pass 200 Hz, low-pass 7500 Hz); then falcon-voice `master.sh` (two-pass loudnorm to −16 LUFS, true peak at or below −1 dBTP, 44.1 kHz mono OGG Vorbis q5). Takes that `master.sh` left below −17 LUFS (sharp peaks) first went through a 4× oversampled `alimiter` (`clone/prelimit.sh`). `standardise_2` then had +0.4 dB of static gain, re-encoded at q5, to bring it inside −16 ±1 LUFS.
- **Checks:** every take transcribed with faster-whisper small (CPU) and compared word by word with `say`. 156 matched. These 6 differ only where the transcriber can't follow, and were accepted on reading the diff: `use-complement_1` and `_2` (whole heard as hole, on all five seeds); `expected-value_1` and `_2` (weight heard as wait, on all five seeds); `simplify-surd_1` and `_2` (surd heard as "SIRD"; a second pass with the maths words in the prompt hears "surd" on both).
- **Measured across all 162** (music-tools `bin/check`, 4× oversampled true peak): −16.97 to −15.90 LUFS-I, −2.97 to −1.11 dBTP, 1.55 to 4.78 s long, 9.2 minutes in all. The first and last 20 ms of every file are at least 60 dB below its loudest 20 ms.

| File (`game/assets/audio/voice/spark/moves/`) | Seed | Seconds | LUFS-I | dBTP | Words heard | SHA-256 |
|---|---|---|---|---|---|---|
| `add-probabilities_1.ogg` | `1099` | 2.41 | -16.9 | -1.9 | all | `e0bc9d60c72a3f9e9b7a885c4ab5c1c90769b5e7e79f6f0d522d4879b9bd8c4d` |
| `add-probabilities_2.ogg` | `1100` | 2.4 | -16.0 | -2.4 | all | `db60635d7227c8d2bf62caa32a830ef78be745989706ad8f0f3357f6875bed8e` |
| `angle-sum_1.ogg` | `1099` | 3.35 | -16.2 | -1.6 | all | `db52e0c6f4e5280a61b9715d037ab672a8128ec1ca7521948c85aa3155c8512c` |
| `angle-sum_2.ogg` | `1100` | 3.6 | -16.0 | -1.9 | all | `eabc40237a8341b436c7de97a302927d5d7b55d62958b7803ad7844c6ee79482` |
| `apply-condition_1.ogg` | `1099` | 2.63 | -16.0 | -2.8 | all | `6d95c9b2f8d7e1e8aec6ff1bac6ca5d343b52dd5682fe49833e92dafbfaa96b6` |
| `apply-condition_2.ogg` | `1100` | 2.88 | -16.0 | -2.8 | all | `cc154c1c4e06a66688575892717cba96ad1d72cfcff1941df4ffd26b6e8fba57` |
| `apply-inverse_1.ogg` | `1099` | 3.57 | -16.0 | -1.9 | all | `45f9319617832010f0ea4af9f1a4df18cdccdc0001c3553cc45b2ebd57ee11c5` |
| `apply-inverse_2.ogg` | `1100` | 4.0 | -16.1 | -1.8 | all | `868aa7b3f898b5266b6605b1a22a05a0518a403c14842330eb9aee912b2c51d5` |
| `ask-what-power_1.ogg` | `1099` | 2.73 | -16.0 | -2.1 | all | `df8180fb95ed27bf5c08f4971b02cd3486b4ee31795045fc5467c5b0dad10772` |
| `ask-what-power_2.ogg` | `1100` | 2.68 | -16.0 | -2.0 | all | `d0cd30d32302a32d1ccc04ec9ef596bad87e7cf18fcc05c5f8eec223ca7c2d44` |
| `change-of-base_1.ogg` | `1099` | 2.35 | -16.0 | -2.7 | all | `44e32bf93c1808b33fbdf60bf63a58bbcb2cb8ffa01e17da44c85b6f73bb360f` |
| `change-of-base_2.ogg` | `1100` | 2.66 | -16.0 | -2.4 | all | `867f3ca1c08baf333e60499775656132777f13b2d8d74a9704993e3e91af9f5a` |
| `check_1.ogg` | `1099` | 1.92 | -16.0 | -2.4 | all | `a47b9c2e95cd8683550367b26cd5a19c2b29da0bd267ce3b36f8d55cd023451c` |
| `check_2.ogg` | `1100` | 1.95 | -16.0 | -1.9 | all | `75185208999f30a6ae994f18f170527c56548dcfc275a0b5c88a7e5d219baa13` |
| `choose-rule_1.ogg` | `1099` | 3.15 | -16.0 | -1.7 | all | `354d512790091b5f31ba5ff8e8c5a6c3e323b321b408b08266c350ab99c4eab4` |
| `choose-rule_2.ogg` | `1100` | 3.18 | -16.1 | -1.6 | all | `cc1f785d732fe606031e3438305eabafe996ad7a18e5d63b8124774f03d3b7a2` |
| `classify-turning-point_1.ogg` | `1099` | 3.04 | -16.0 | -1.7 | all | `3c84888e47d2f6aa335277076a57bcccf7e9090acb1f3df9edb32edd72f2924f` |
| `classify-turning-point_2.ogg` | `1100` | 3.19 | -15.9 | -2.0 | all | `b03ff0d54d2e17a3c4fada6cd4fbb19ba6e8a13ca64f2bb91875f9069c17f07a` |
| `clear-fractions_1.ogg` | `1099` | 3.74 | -16.3 | -1.9 | all | `91cdaea1beaec5b970093ab75ce1be5f9f4ae414d16fbd69c702251d849ca5e8` |
| `clear-fractions_2.ogg` | `1100` | 3.13 | -16.3 | -1.7 | all | `8e17d2efd3ff4df4a8d098b950933ab64de7b2208e212dc4123062c4d32b3dd8` |
| `compare-coefficients_1.ogg` | `1099` | 4.4 | -16.1 | -1.7 | all | `35be148e6d487b63749965d9c3255ebbc31f8e991b23cbea65fc330be629db2e` |
| `compare-coefficients_2.ogg` | `1100` | 4.0 | -16.0 | -1.8 | all | `d5fa70481ab088caf8c1d85fe317e4d3ddeb530e44eef12dab30ddcbece744f3` |
| `compare-neighbours_1.ogg` | `1099` | 4.0 | -16.0 | -1.7 | all | `65aebc2473936f3d133dffa0d0ee0aa07a0913cffccca96fb2451d0d9ae85f82` |
| `compare-neighbours_2.ogg` | `1100` | 4.1 | -16.1 | -1.9 | all | `4cec598746ad1c22a56471f7e2e11620953cbd903f8410e49a304fa579c40826` |
| `complete-square_1.ogg` | `1099` | 2.54 | -16.0 | -2.4 | all | `21ebf80b67c1544cdbdee2311281e8adcfb901481cdc74bbfbbbcc7790dc152d` |
| `complete-square_2.ogg` | `1100` | 2.66 | -16.0 | -2.4 | all | `cdf00f130bc04614c62c093741d6cdee109810b927294cb849c065756ef0a1e0` |
| `compose_1.ogg` | `1099` | 3.21 | -16.1 | -1.7 | all | `9ab22862a2bc5f78af4f241801ab65d816bbc5d697a88de5b52b2598e3f7b2f7` |
| `compose_2.ogg` | `1100` | 3.64 | -16.0 | -1.8 | all | `66337c0d3b0dba6d5cb64e64d0a85b2a35eabfef7fc5fe216a439fe976c4e743` |
| `compute-discriminant_1.ogg` | `1099` | 3.52 | -16.0 | -1.8 | all | `0d11d705677e22fabc05a8b396e733300d8cb303e1a02276d77d76b2f676e804` |
| `compute-discriminant_2.ogg` | `1100` | 4.1 | -16.1 | -1.5 | all | `545d82b30b526c7606f10b14f5bb6ba472f6935b9341a162212a49a8c0f58920` |
| `convert-log-exp_1.ogg` | `1099` | 4.7 | -16.0 | -1.9 | all | `2051372dff2766a01163fff1fb35a161e06eee68fc926427e7f6b2c5cccaee14` |
| `convert-log-exp_2.ogg` | `1100` | 4.5 | -16.2 | -1.8 | all | `14bcb3a38f506a5a1088c2c81832c98282ffe9380743bb9d0713783c4e455b0e` |
| `count-steps_1.ogg` | `1099` | 4.4 | -15.9 | -1.8 | all | `2641f6945d338474a67140b256704cdeaf5eebb1cf08f08215d446c2e73822d2` |
| `count-steps_2.ogg` | `1100` | 3.61 | -16.3 | -1.7 | all | `4ed035d2e6f1577588b81a2844186b42db30b31329fcb15d43111e6aeb801072` |
| `definite-integral_1.ogg` | `1099` | 4.2 | -16.2 | -1.6 | all | `4e3e5c9550630602c7de5239d67f3d71bb39eeb85858ad9f6d57b3475af5ec20` |
| `definite-integral_2.ogg` | `1100` | 4.7 | -16.3 | -1.7 | all | `b63f20c26c0b33734616f4a27d0e8b42287ca0c22ee57b06e9c8408cfb294dbc` |
| `describe-transformation_1.ogg` | `1099` | 3.19 | -16.1 | -1.8 | all | `dc948ed1c7aa9663c125080c8aafd62152e4f464494827ce67aa3ec6be4ff3ac` |
| `describe-transformation_2.ogg` | `1100` | 3.55 | -16.2 | -1.8 | all | `8996285ff90b25b296352b3c63f3db4ef2be281aa2da5bd2bd788bfd97b0ac27` |
| `differentiate_1.ogg` | `1099` | 3.25 | -16.4 | -2.0 | all | `4b7e646cd8c2109ab8d812f8e2a154b8168f700712b63b26a606912c174c623b` |
| `differentiate_2.ogg` | `1100` | 2.76 | -16.0 | -3.0 | all | `215a57bd0c6c967643d234df57cc9f093c8ec9d9c312f9716c92b723d1b7c4c0` |
| `draw-construction_1.ogg` | `1099` | 2.52 | -16.2 | -2.2 | all | `16ba152c2116e9f7e14c1bdde5400db8cb92d5224540e6091be2f6fb9278e3f5` |
| `draw-construction_2.ogg` | `1100` | 2.81 | -16.0 | -2.3 | all | `4d7dd65099c2763b1a38e7e8f48bbc255ca61ccd8946d7129d1598772bb7e396` |
| `eliminate_1.ogg` | `1099` | 3.27 | -16.0 | -2.0 | all | `55056002bf4c461c024809aa03bfdae83a05846492f78d48bec509c10f7f851c` |
| `eliminate_2.ogg` | `1101` | 3.61 | -16.0 | -1.8 | all | `3bebbddf6cf90b43e8a0b74097a16232a51c79121935327b117965a967d8e5cf` |
| `end-behaviour_1.ogg` | `1099` | 3.79 | -16.2 | -1.9 | all | `bd28ecaf27f29dce1481ad3ec3c548392a8133f3549535a2488b19734eb1fcca` |
| `end-behaviour_2.ogg` | `1100` | 3.67 | -16.2 | -1.6 | all | `14075f3b3331069984c4670a8843dbb7068f5ea1f2b5f6f7ad0e67e308992ed7` |
| `equate_1.ogg` | `1099` | 3.49 | -16.3 | -1.8 | all | `01fd656954bb4b4008e9446bf818af1d117fd024b0104b58f29371ab190655dd` |
| `equate_2.ogg` | `1100` | 3.18 | -16.1 | -1.8 | all | `a3f5cec3b00386125f01bc0f1887f33ce463776c785a3fe314e735164acbbd94` |
| `evaluate_1.ogg` | `1099` | 1.55 | -16.0 | -2.7 | all | `baceb3bc271d734ffbb57eb2eba304cf92fba00ae45630146acb6e279d51f414` |
| `evaluate_2.ogg` | `1100` | 1.57 | -16.0 | -2.8 | all | `d1aa8f1effa7a5eb515085355143383c5b907cb5a9f061e807c7428f43d48d56` |
| `exact-value_1.ogg` | `1099` | 3.64 | -16.4 | -1.6 | all | `765e2ac86a32efc7c7e717ce4680aa6ee65533000f9890d534d92be452a30f0c` |
| `exact-value_2.ogg` | `1100` | 3.63 | -16.4 | -1.6 | all | `f2602ad5dd5079b8fa3591e8057af1f5b425fe1d5fb0e3d401a681a587536b5b` |
| `expand_1.ogg` | `1099` | 3.25 | -16.5 | -1.7 | all | `a70afdf9b4a314a297139ffe1f4c83f74e7bb823275b6623f4d9eefe018ad866` |
| `expand_2.ogg` | `1100` | 3.25 | -16.0 | -1.7 | all | `64b711672705b26c0eac6b8c28faccc5608a64d23d37c5c3eeb7f62e65176420` |
| `expected-count_1.ogg` | `1099` | 3.08 | -16.0 | -1.8 | all | `f40771e1b144b9af2ca3dfcde687d34224f002a3c638acbbbe7e1ee339cf8677` |
| `expected-count_2.ogg` | `1100` | 3.04 | -16.0 | -1.8 | all | `256c0b996720613aeb42e0473b7f21f37494c449b0c3065f12bbab6d8e7c43d4` |
| `expected-value_1.ogg` | `1099` | 3.77 | -16.3 | -1.8 | accepted on review | `a1d9eca3de1c08bb7c2c3341c82c95e66489bed454faec31000019a094549e05` |
| `expected-value_2.ogg` | `1100` | 3.67 | -15.8 | -1.5 | accepted on review | `15ea43d5532f24a8778d92184b52a06ac6bb268cf2b02fb93b60c00895c7571c` |
| `factorise_1.ogg` | `1099` | 3.52 | -16.2 | -1.7 | all | `c9cfe1950ba3cd5a63b796e80dc1a72cb4d11fde9644ec1fdb8d54cc19fa071f` |
| `factorise_2.ogg` | `1100` | 3.34 | -16.3 | -1.7 | all | `2287335c496c20496647f4d033157563ca951a069f5c91baa57c0b96d8da1160` |
| `find-all-angles_1.ogg` | `1099` | 4.4 | -16.0 | -1.7 | all | `93b74e5fd2e90063b5d7276e5f934f4a68f2a06ce689f10f4580adb85c029efe` |
| `find-all-angles_2.ogg` | `1100` | 4.4 | -16.0 | -1.6 | all | `7f478116767f388c5ecd8134ab38bcec5f0ab248aebdaf1c5d30494bba952eee` |
| `find-factor-pair_1.ogg` | `1099` | 2.9 | -16.0 | -2.7 | all | `4eac3d1d2eaff4b9945c196cf5af5b759c56fcc891df294eb178088aca7b98dd` |
| `find-factor-pair_2.ogg` | `1100` | 2.9 | -16.0 | -2.4 | all | `78e897efc542d0d5f5ea8b441008e7fe18c5deaf35ff8ba000255fefdd71902a` |
| `find-gradient_1.ogg` | `1099` | 3.85 | -16.0 | -1.8 | all | `2c1132725f779ff2418d452cc61eea43918c6228a78b2c7672e846528976af82` |
| `find-gradient_2.ogg` | `1100` | 3.85 | -15.9 | -1.8 | all | `f335a46029a7c050c101c9b3b0065afed8ad92c75f208e4c42ffcb7e054e5e93` |
| `find-midpoint_1.ogg` | `1099` | 2.73 | -16.2 | -2.0 | all | `f4e2b04eade2f158ee84346e816791ae2844b167ffd39f59df84303653af8b84` |
| `find-midpoint_2.ogg` | `1100` | 2.59 | -16.2 | -2.4 | all | `4690a91590f6fedcb4089a1c419e3dd8e1b44493543cb397802aaeaf1fbbf223` |
| `gauss-pair_1.ogg` | `1099` | 4.5 | -16.0 | -1.8 | all | `1ed3f2aca29f456215ea9d18e47366212b8d151af9e6e66dd9cfafecfc234429` |
| `gauss-pair_2.ogg` | `1100` | 4.8 | -16.2 | -1.8 | all | `a433009fdef7cc739ae3056876c03f76d7bb51ae6567f9950321b9d0e79422bf` |
| `gdc-graph_1.ogg` | `1099` | 4.1 | -16.1 | -1.8 | all | `4f7b60e889507dce295586460d4bd2542ec1496eb21e1f19208b28086a41abca` |
| `gdc-graph_2.ogg` | `1100` | 4.3 | -16.1 | -1.7 | all | `c5d036f44b6afe0367aad488049664255c097288ad66f0dedb413cdf6facebd4` |
| `gdc-solver_1.ogg` | `1103` | 3.21 | -16.1 | -1.9 | all | `a16535b9b75c8570144f923bc3d811fc199b78361a9d831bdd573807c4691b83` |
| `gdc-solver_2.ogg` | `1103` | 3.21 | -16.1 | -1.9 | all | `069aea89d8e63bf51fb4785489a024f5090a4984db1928578cf74042e98d7813` |
| `gdc-stats_1.ogg` | `1099` | 3.62 | -16.8 | -1.6 | all | `8b2ac8f2a7c6ded52356dcc372537ec05343e7fdf5740efdca50fbfbf1526de3` |
| `gdc-stats_2.ogg` | `1103` | 3.54 | -16.5 | -1.8 | all | `c5c291fca9e730d0cbb0607c1425940dedc4ebb502e080ddc6e0d7a271749772` |
| `integrate_1.ogg` | `1099` | 3.33 | -16.0 | -1.6 | all | `724ec5094dc46060e32bfc6b83ad223f9b718eace7f2ddc989287aad8209b6f5` |
| `integrate_2.ogg` | `1100` | 3.67 | -16.0 | -1.9 | all | `273a6c0b13305313eead39c2c97ea73a5573937ef618cbedcfe276ff92a46ff5` |
| `interpret_1.ogg` | `1099` | 1.93 | -16.0 | -2.4 | all | `2bdcfb20763ff966d0570574c64964cbb36e2e23e98a0b260a8f4c91d1c344f9` |
| `interpret_2.ogg` | `1100` | 2.56 | -16.0 | -2.3 | all | `df0b23fd6dfcb6de27cd8bd346da47f64bff7467712d8a4c498473c6e65b81f2` |
| `introduce-letter_1.ogg` | `1099` | 2.41 | -16.0 | -3.0 | all | `62791d8c76bed01f70e5140b55634fd71f0ce878016f11df6ff621adb45d6791` |
| `introduce-letter_2.ogg` | `1100` | 2.55 | -16.0 | -2.6 | all | `53ea882893c03531aed8971ae7d2aa4576fa55d6acaddcb01745f4d012ff85e5` |
| `isolate_1.ogg` | `1099` | 3.52 | -16.0 | -1.8 | all | `c016f29bd4ad8c6136bda4e47d22aa273096adce6278d6703285770d9eb3c9a5` |
| `isolate_2.ogg` | `1100` | 3.83 | -16.0 | -1.9 | all | `236a2ff918296e0c4a375caccaa7f483831b45acd4938f6b9afccb3e99378e11` |
| `keep-valid-solutions_1.ogg` | `1099` | 4.5 | -16.1 | -1.6 | all | `2bc0f172027a6129d6d8a5194477cea8b1a78e4d65abf7d622c9c2c9e690506b` |
| `keep-valid-solutions_2.ogg` | `1100` | 4.5 | -16.3 | -1.5 | all | `f556150c0b5ce21f8175e6634f52e723e09d88439e7905ae0b651a721b6a308f` |
| `label-diagram_1.ogg` | `1099` | 3.25 | -15.9 | -1.6 | all | `5bb5c049514fb2b470eb64eadea85819dfb11be872ca1c885b5ffdc06faf8f67` |
| `label-diagram_2.ogg` | `1100` | 3.63 | -16.0 | -1.8 | all | `976583cc4677b3a8d7f6c68898d77e908c1323eeb3178e277f37b39762d1a3c2` |
| `list-outcomes_1.ogg` | `1099` | 3.42 | -16.1 | -1.5 | all | `5279e2e0c8ebb5e669078311766fabd67bf4d09906e03ac0ea1c307c32a13d8e` |
| `list-outcomes_2.ogg` | `1100` | 3.52 | -16.0 | -1.9 | all | `76db82db053d8840f4b3c766fae1d0510d4cee7debb11c42a5fa3fc8508edc39` |
| `model-from-context_1.ogg` | `1101` | 2.79 | -16.0 | -2.9 | all | `ce6dc9be03e93cb745314b539f769a579bc57daadab1ccdf3d4570ee9ae01bf9` |
| `model-from-context_2.ogg` | `1101` | 2.79 | -16.0 | -2.9 | all | `78b7fd9d4b0689d1c382bebee5b9e287addb3865eccbe9d6566bf7750e1d8b4a` |
| `percent-multiplier_1.ogg` | `1099` | 4.0 | -16.1 | -1.8 | all | `048b6368c6ffea7d368c431bad4bb3ce691a02dd4c12ee5fdf27a939354aba5a` |
| `percent-multiplier_2.ogg` | `1100` | 4.4 | -16.3 | -1.8 | all | `d05609f39d694fbf859d55ba9ba2fdb10e5581d217bf4b107137e2b9c7eaf50c` |
| `perpendicular-gradient_1.ogg` | `1099` | 4.1 | -16.0 | -1.9 | all | `336e465bff6547c51df7e96029a02f66190fa7ed7e3fe1ea7233fa7c850df277` |
| `perpendicular-gradient_2.ogg` | `1100` | 4.1 | -16.0 | -1.8 | all | `9e087d9042732bf46a4c63ca76a021bfcc76616060b524fa8613e30b8392d450` |
| `pick-region_1.ogg` | `1099` | 4.8 | -16.0 | -1.8 | all | `5cec66e5514d39bde6f0bf30ed6e14159545f50db3e488c6b6dc26fb7fb1fb96` |
| `pick-region_2.ogg` | `1100` | 4.4 | -15.9 | -1.8 | all | `f62019582346481acb2b1eef714357bc3de2d09f43b166c1be6579ecafda5a46` |
| `point-gradient-line_1.ogg` | `1099` | 2.98 | -16.0 | -2.9 | all | `47900a433309b593ae3c26cc9e691cfff3b831af15954cb5f1315003ce9cd465` |
| `point-gradient-line_2.ogg` | `1100` | 2.97 | -16.0 | -2.8 | all | `b1f60f6fd620e1a14964c55b861dbdc433beb3932936e4f8588a253efea4b419` |
| `pythagoras_1.ogg` | `1099` | 3.72 | -16.1 | -1.7 | all | `2bce4504bb454637b682d109dae720e6095ad36fd1656d58618580cfa69d745a` |
| `pythagoras_2.ogg` | `1100` | 3.25 | -16.1 | -1.8 | all | `9904286ba505624ecaab16bdc6b0783ccd7f438459c2c35651baa9b5edc04fd8` |
| `quadratic-formula_1.ogg` | `1099` | 4.1 | -16.3 | -1.7 | all | `9a2fb8d2bf7c5693ca7938e4cb828bc4d6fff2bc883eaa9500ac7dd420adf8e1` |
| `quadratic-formula_2.ogg` | `1100` | 4.4 | -16.2 | -1.7 | all | `c5f2f9c55e701923cc3ec86fa5b460c49f5e4744666b772213440dc573b2df89` |
| `read-givens_1.ogg` | `1099` | 2.5 | -16.0 | -2.7 | all | `bd393c2bc975a318e3561d5e1278b37ab724c2ce5835fb3a5d33387c96604094` |
| `read-givens_2.ogg` | `1100` | 2.61 | -16.0 | -1.7 | all | `83798ebc179cbc736e0dda7c078347a9cf3f52f8bbdad8da9e2ff3d5d82fdca9` |
| `rearrange_1.ogg` | `1099` | 3.68 | -16.1 | -1.8 | all | `69e8a83cc4f7b4093b6863dad0b2779aae0e8d86885e581dff0e7c116e5cbfbc` |
| `rearrange_2.ogg` | `1100` | 3.36 | -16.0 | -1.8 | all | `d87b45bbcb972ec003eb3e182351f3ef6bab5afff13eb866a2b7f9b5bbb904cb` |
| `reason-from-shape_1.ogg` | `1099` | 3.72 | -15.9 | -1.8 | all | `98f7a58fe3c266cc13df8980b8ec6db92aeebf9ef26f688d72d7ddee32f45649` |
| `reason-from-shape_2.ogg` | `1100` | 2.94 | -16.0 | -2.6 | all | `1930c0a8454f0c7a387b2458add9627c352a08109edc2aad90f7e3570583b4b4` |
| `recall-fact_1.ogg` | `1099` | 2.36 | -16.1 | -2.2 | all | `ff0e7a3b8b05c34a48294f191ea9b563d6af6fdd2e1f749adb6da16afb05499a` |
| `recall-fact_2.ogg` | `1100` | 3.17 | -15.9 | -1.9 | all | `0d64d5d90f24431d5fafd2c63e07c36638d3c06a77d2212d8c9340b196a742db` |
| `recall-formula_1.ogg` | `1099` | 3.6 | -16.0 | -1.8 | all | `d6179bcdcd04d134c1b8dbe47c229323da57eeb5763051b693963feafbd135ff` |
| `recall-formula_2.ogg` | `1100` | 4.0 | -16.0 | -1.8 | all | `3d355f4394ea8c0aa07d5a51769773d5da84f666aa916b1062a16eec480a1321` |
| `repeat-multiplier_1.ogg` | `1099` | 2.53 | -16.0 | -2.8 | all | `e4a99a1a852a6cbb2b4dd6097ba3ba79982e1e375b31ca3024c3765d051769a5` |
| `repeat-multiplier_2.ogg` | `1100` | 3.47 | -16.0 | -1.6 | all | `bc14b43fe42feb3605c3a2ff9148961de647e2178520fee2b0737260c4447a9b` |
| `reverse-operations_1.ogg` | `1099` | 3.85 | -16.0 | -1.8 | all | `b90c715483c3c8e99997eda8c1ab32820734199e197986c6d2f50059925918ec` |
| `reverse-operations_2.ogg` | `1100` | 3.65 | -16.0 | -2.0 | all | `9a30c4a000da21feda44671d8187a0fe6146521e60846a5c0e588f988dc63a2a` |
| `rewrite-form_1.ogg` | `1099` | 3.32 | -16.2 | -1.8 | all | `161160c407a7c654255cc94fa462b37e1348ae669f303a2bedd780203927ca2d` |
| `rewrite-form_2.ogg` | `1100` | 3.41 | -16.0 | -1.8 | all | `3d86043a9e989c7c12973145a3d6802e755fa82e1ea6e13e83e1b226dace603e` |
| `roots-to-factors_1.ogg` | `1099` | 3.41 | -16.3 | -1.7 | all | `13d198c368eece3405457cfb1c1c9484c2ff3a1b8fd4f35adcf1bc206d383407` |
| `roots-to-factors_2.ogg` | `1100` | 3.59 | -16.3 | -1.8 | all | `a0a04bbbf08524bd99803b1e4de7b5ee3aab28c1b206ed782bbea1554b82f0a7` |
| `round-for-context_1.ogg` | `1099` | 3.75 | -16.1 | -1.6 | all | `13f18d988b19e6758f361ae29f68ea87de321dd5cf912fc58e81e6f859b4c8e2` |
| `round-for-context_2.ogg` | `1100` | 4.1 | -16.3 | -1.7 | all | `91f23aa1290e6f9c026d68e8356b47522737234e01ea42f4c62b51e5f1fb9ede` |
| `sign-table_1.ogg` | `1099` | 3.24 | -16.2 | -1.7 | all | `cb3d81f55cd0e51e5bf2f64cf487acc850e035d814d9e12e5452e80d47447fce` |
| `sign-table_2.ogg` | `1100` | 2.7 | -16.0 | -2.5 | all | `d26ce8a66105f3e1c16a512baee91930b4bc2694185d4dd9539b44ea59de651f` |
| `simplify-surd_1.ogg` | `1099` | 4.5 | -16.1 | -1.8 | accepted on review | `05509a6f053c1dbdbe09a1e0877672425b756f4405a592b43f47550829732942` |
| `simplify-surd_2.ogg` | `1100` | 3.88 | -16.1 | -1.7 | accepted on review | `29b73f0ca1c1e395582d0b79b6d617c0b31b170a204bfcdf898e5f5509d7dee0` |
| `simplify_1.ogg` | `1099` | 2.57 | -16.0 | -1.8 | all | `a701261b33dcb3d5eba5340cf12ed71b3d77e5689f842fafcc47526c8f6da9f6` |
| `simplify_2.ogg` | `1100` | 2.62 | -16.1 | -2.3 | all | `20e8cc44ce7d05ba28f19317cc2070188e5efb866bb3ae0b1d6cb8abfa8bd9fa` |
| `solve-equation_1.ogg` | `1099` | 3.65 | -16.0 | -1.6 | all | `a538e0cf2b343a8129f0e5ae6fca6deff81d644f8b038fb6868ddcbd8c0d7c71` |
| `solve-equation_2.ogg` | `1102` | 4.0 | -16.2 | -1.7 | all | `f641f1d822faacaa891db4aa72ac9053cdc9159dbe1afbc9a6e1b3d08ccac77a` |
| `square-root-both-sides_1.ogg` | `1099` | 4.4 | -16.0 | -1.8 | all | `748c3a31234e3a8f2e33af0a6d24e7f1bbfe9d4635f5f0b174d9da83e9bf8647` |
| `square-root-both-sides_2.ogg` | `1100` | 4.3 | -16.1 | -1.1 | all | `81e1232ee616aad8cc93b33828e76425eae8b0922f82876723fed688168d53cf` |
| `standardise_1.ogg` | `1099` | 3.13 | -16.0 | -1.9 | all | `043ab63beeff26a91f03330336b0e410c431a9b691ba3e9eae1a9c7b83a34f98` |
| `standardise_2.ogg` | `1100` | 2.9 | -16.7 | -2.1 | all | `34f1916ff55e80b0d9b766a00eb48627420cb71f9fb154a193d56e74a1a7bd5d` |
| `state-answer_1.ogg` | `1099` | 3.62 | -16.2 | -1.7 | all | `eb99665dc087ae64ee2c095f3fef14ba5833b254fb7dbc422bf9015c0bf41da4` |
| `state-answer_2.ogg` | `1100` | 3.62 | -16.1 | -1.6 | all | `424f8590ab38c1a3269fcb3da5d369165b79d02ae31ca55e8d9f5e7193abc2ea` |
| `substitute-back_1.ogg` | `1099` | 2.87 | -16.0 | -2.7 | all | `03527d52b90a5a522b0500524908103d03616a9ce5a270af759c9a70290bcba3` |
| `substitute-back_2.ogg` | `1100` | 2.28 | -16.1 | -2.1 | all | `e080cddcad443bdca167faa0cc9884739730a11af19747cb499200bef70c4433` |
| `substitute_1.ogg` | `1099` | 2.69 | -16.0 | -2.4 | all | `bf0fd94d02529494238a85d73737cee5e18af84b0c6d66fdf523cf58ad31c6b1` |
| `substitute_2.ogg` | `1100` | 2.66 | -16.6 | -2.1 | all | `ac0a20b20847bdbbae72f1c5e526a9e3d750e091f1b2637c119b903a154c171b` |
| `swap-x-and-y_1.ogg` | `1099` | 3.27 | -16.4 | -1.8 | all | `aab3ed1dd9d5f16cb975d80c15380b526824f749eca5b156f5db4787b263e307` |
| `swap-x-and-y_2.ogg` | `1100` | 3.15 | -16.7 | -1.7 | all | `2d0d29712b1a1a4bd47435de22c893f5f017c9d2b83610a0963f1f45a909fded` |
| `take-logs_1.ogg` | `1099` | 3.44 | -16.0 | -1.5 | all | `2a3861d76be117a4de7da9fcc9c6b88f56de0860baaa39c72ff81bc004110c9c` |
| `take-logs_2.ogg` | `1100` | 3.12 | -16.0 | -1.9 | all | `8ba12d7ee9f6c209d538c6b65e909fd88e037204a732dd22ac966855c0061cd8` |
| `test-point_1.ogg` | `1099` | 3.09 | -16.1 | -1.8 | all | `e3fa15e8b2e8a3c352f613dff160cc7ffac7ca6a22aff0a72b5ef9cf4c5c43c6` |
| `test-point_2.ogg` | `1100` | 3.06 | -16.1 | -1.6 | all | `71e81093e7c86c25da443672d92d60c2bb433554998e1489ae60b013d34847ff` |
| `transform-point_1.ogg` | `1099` | 3.18 | -16.2 | -2.0 | all | `566bbda3345961d966fd5ad158613917207aff1291c2825b6fd85893e0a34091` |
| `transform-point_2.ogg` | `1101` | 3.2 | -16.2 | -1.8 | all | `2fc700d2a6cb98f8eade02d8f3970afeb02cc458ca577e3b51f894319d6d8007` |
| `use-complement_1.ogg` | `1099` | 3.64 | -16.5 | -1.8 | accepted on review | `4bdaf69e001b027677ac8ae522a89d51d3a53c3ef68fd8aadd1e3e97fc70f9f6` |
| `use-complement_2.ogg` | `1100` | 3.12 | -16.0 | -1.8 | accepted on review | `f60f5fd60a60f83421b8efe93484642edc02dc98a20f2e27f540034612ae9589` |
| `use-identity_1.ogg` | `1099` | 4.4 | -15.9 | -1.9 | all | `8da348111924036564801e254a0815429c396e6d5d40539feeed3917b4a5acf3` |
| `use-identity_2.ogg` | `1100` | 4.1 | -15.9 | -1.9 | all | `13b9778ad95af6e60359c1a9445b91604e47dc633942c675ff06b55c7b9b3680` |
| `use-log-law_1.ogg` | `1099` | 3.46 | -16.0 | -1.9 | all | `a8b25e4c603c278ff50d7ae3fec3155ada261a053254d3d0fa93c5df9b8e6ac0` |
| `use-log-law_2.ogg` | `1100` | 4.0 | -16.0 | -1.8 | all | `2fc7b3c083f62f2823528070b6edec216596ff0d0be1dd8daf78df8afb8eb32e` |
| `use-right-triangle_1.ogg` | `1101` | 4.6 | -16.1 | -1.9 | all | `2993e69626c6e2c0986157e9bbda6944b752f84cfc9676b51f519fba2050a282` |
| `use-right-triangle_2.ogg` | `1101` | 4.6 | -16.1 | -1.9 | all | `2cdc0585a10d0f0c82f69e1c1c0a56cffac79ec500dc4a992948046787313d0d` |
| `use-symmetry_1.ogg` | `1099` | 4.3 | -16.3 | -1.8 | all | `de01194485bf73a1722121e1eaadde97c44bdca03e2be189bea4cfefef8fbaba` |
| `use-symmetry_2.ogg` | `1100` | 4.4 | -15.9 | -1.8 | all | `90312dcc7a2411cf5cc0bdeca1a419cc780b09344baa493e67d7de2abd2de35f` |
| `zero-product_1.ogg` | `1099` | 3.27 | -16.1 | -1.7 | all | `ff7f9a1164ec0537a22b8542d89d83b6a641eb0b547e38c452e7a0233558808e` |
| `zero-product_2.ogg` | `1100` | 3.12 | -16.3 | -1.6 | all | `d9e7ed4d9b9ce4ea34317faa49361576a3a3a00fdcf11e1bc788373a8025a4e5` |

## FAL-1110 — explainer lines, local voice clones (voice)

151 voice files in `game/assets/audio/voice/explainers/`, where the lesson player looks for them (`<script id>/<line id>.ogg`): every spoken line of One In, One Out (`ex.functions.function-machine/`, 59 lines, Rook Dead-Air), Rook's stock reactions (`reactions/`, 8) and the callback lines of all six tutors (`callbacks/`, 84). The words are each line's `say` text exactly, from `writing/explainers/`. Each take is also recorded in `writing/explainers/manifest.json`. Generated locally with VoxCPM2 on 2026-11-17. No recordings of any real person went in.

Rights basis: VoxCPM2 (OpenBMB) code and weights are released under the [Apache License 2.0](https://github.com/OpenBMB/VoxCPM/blob/main/LICENSE), which allows commercial use; model card https://huggingface.co/openbmb/VoxCPM2. Package `voxcpm` 2.0.3, weights `openbmb/VoxCPM2` from the local Hugging Face cache. Each voice is cloned from one reference take: that voice reading the same template paragraph, generated with Gemini text-to-speech (`gemini-3.8-flash-tts`) via the Gemini API on 2026-11-17 (FAL-1099), with the voice and direction the board approved on FAL-927. FAL-1035 confirmed Gemini output may ship in paid releases. FAL-1099 read Google's terms on using it as a clone reference, and no clause forbids it (report on FAL-1099). The references stay in the local falcon-voice repo (`voices/wasteland-academy/`) and don't ship. No model was trained or fine-tuned.

Matt chose the clones, in "ultimate" mode, on FAL-1110 after hearing them side by side with Gemini.

| Voice | Reference: Gemini voice | Reference SHA-256 |
|---|---|---|
| C.A.L.C. (`calc`) | `charon` | `f9ac204277eaef2023d892f408f3f7b8bf8e9add7666061e5692b3e9f6f94475` |
| Kara Meridian (`kara-meridian`) | `gacrux` | `7a0d95e26f05ede81516a2fdbf223fee1fcad006cc7df7dfa3d1276807291c8f` |
| Lucien "Lucky" Lenoir (`lucky-lenoir`) | `fr-fr-podcaster-8` | `34170409f48d168d16076ce05ff8ac3784eef7ad1f0f99b6f66d0da095e927bd` |
| Mags the Ledger (`mags-the-ledger`) | `en-au-tutor-3` | `86e05455afd9e60c211e88464fadc3dc0e6c21c46bbb20f901286d26eb7ce9a1` |
| Rook Dead-Air (`rook-dead-air`) | `en-za-storyteller-1` | `9025fd9f9e86a863f5939b8063002875eb0bc7cb40ff65bc14b03e0f1cf489c6` |
| Tin-Can Tess (`tin-can-tess`) | `en-nz-commercial-3` | `dde85ad76bb4ceae6bd5f6eae379fb4afbea786778d8762da051c19080cb6b7f` |

- **Cloning:** VoxCPM2 "ultimate" mode: the reference is both `reference_wav_path` and `prompt_wav_path`, and its words are `prompt_text`. cfg 2.0, 10 inference timesteps, denoiser off, text normalisation off. Seed per file below (`torch.manual_seed`): 1099 first, then 1100 to 1102 for a line whose words didn't match. `reactions/ml2cxq` ("Sent.") needed a fifth seed, 1103, because the first four added sound after the word.
- **Text fed to the model** is the `say` line. Delivery cues (`chuckles`, `glitch`) are not sent: VoxCPM2 has no cue control, and the script format says a voice that can't perform a cue skips it. C.A.L.C.'s glitch is in its effect chain anyway.
- **Changes, every file** (falcon-voice `clone/post.sh`): resample the 48 kHz clone to 24 kHz mono; trim silence below −50 dB at both ends; 10 ms fade-in and 40 ms fade-out; 30 ms lead-in and 60 ms tail; then the voice's approved chain from `teachers.json`: the 2% tape slowdown (`asetrate=23520,aresample=24000`), plus C.A.L.C.'s glitch filters; then falcon-voice `master.sh` (two-pass loudnorm to −16 LUFS, true peak at or below −1 dBTP, 44.1 kHz mono OGG Vorbis q5). Takes that `master.sh` left below −17 LUFS (sharp peaks) first went through a 4× oversampled `alimiter` (`clone/prelimit.sh`, from FAL-992). `reactions/ml2cxq` then had +0.7 dB of static gain.
- **Checks:** every take transcribed with faster-whisper small (CPU) and compared word by word with `say`, numbers included. 144 matched ("Sent." on seed 1103, with a second of silence either side, since a 0.8 s clip is too short for the transcriber alone). These 7 differ only where the transcriber can't follow, and were accepted on reading the diff: `callbacks/c04b7s` (what stuck heard as what's stuck); `callbacks/ut8s7q` (signal's still heard as signal still); `ex.functions.function-machine/25tykc` (Lekker (Afrikaans) heard as Licker); `ex.functions.function-machine/b7n1cv` (oupa (Afrikaans) heard as Oopah); `ex.functions.function-machine/j7nxs0` (Ja (Afrikaans) heard as Yeah); `ex.functions.function-machine/k4e8xl` (channel's heard as channels); `ex.functions.function-machine/vnrkur` (a times heard as at times on all four seeds).
- **Measured across all 151** (music-tools `bin/check`, 4× oversampled true peak): -17.10 to -15.37 LUFS-I, -3.18 to -1.44 dBTP, 0.78 to 12.26 s long, 12.8 minutes in all. The first and last 20 ms of every file are at least 76 dB below its peak.

| File (`game/assets/audio/voice/explainers/`) | Seed | Seconds | LUFS-I | dBTP | Words heard | SHA-256 |
|---|---|---|---|---|---|---|
| `callbacks/a3zmuk.ogg` | `1099` | 7.7 | -16.2 | -1.5 | all | `3189f8e09997a2eb788e66f51903a6e864410e31c13cc63bdd2b068bdfec0a7a` |
| `callbacks/a5xac8.ogg` | `1099` | 3.52 | -16.4 | -1.6 | all | `46e3bb19312f666418a8b09e138b2a58ee24e30a047c4a38f4dea4915aa5cfd4` |
| `callbacks/a8a6uc.ogg` | `1099` | 5.2 | -16.5 | -1.7 | all | `bdd8f0c6a2b87475186932c0c973484cd1f4a337e7cf6b144c2fdf1903e5fb3a` |
| `callbacks/aaqxxd.ogg` | `1099` | 6.9 | -16.4 | -1.7 | all | `024697628b5715db8a79af77736256a738b270a98e77324235b57222fd74f4d4` |
| `callbacks/ah2ux1.ogg` | `1099` | 5.2 | -16.2 | -1.8 | all | `d195036c301249686039925abbd185a846c82e29f91414207eba65060741acb6` |
| `callbacks/ai7rkl.ogg` | `1099` | 6.2 | -16.5 | -1.8 | all | `8d2e35f8bb75405546ead5d0d3f4cb3feb48408a4b375e47256b0cde0e0dbc38` |
| `callbacks/am0al9.ogg` | `1099` | 5.3 | -16.2 | -1.5 | all | `a5ff07448810e572383727a06faa6d68d3cf831e2e31166a89cacb614ae94083` |
| `callbacks/b59dm4.ogg` | `1099` | 5.6 | -16.9 | -1.6 | all | `54d0a9018353608baf67e1f1030077ce73bca24c4963cb85559bf996d761af87` |
| `callbacks/b7e2jc.ogg` | `1099` | 5.3 | -16.4 | -1.6 | all | `f8c3039177e25f7a930f218f0f0f02aded8bcfb77b0ff0acba9772ca7597f9b3` |
| `callbacks/b80hrn.ogg` | `1100` | 2.45 | -16.0 | -2.6 | all | `731c933360444d42071641f1698c2ab47533db980f99ea9e676a37d4e6f65074` |
| `callbacks/ba66t1.ogg` | `1099` | 4.3 | -16.2 | -1.8 | all | `ea392f3b52113bca42e042320ca1641f40ff51d4823d2f1b274357ad1bbae80f` |
| `callbacks/bf9sg3.ogg` | `1099` | 6.2 | -16.2 | -1.8 | all | `0f43c4ef0e977d80f05d417ded2d6aac5299656712731a267d8cb170ae84593b` |
| `callbacks/bheneg.ogg` | `1099` | 4.0 | -16.7 | -1.7 | all | `f38bd5b8bf5ae11bb1ef066945a160e9c62a87da49a1e2e217ee7d9174854057` |
| `callbacks/bmokj5.ogg` | `1099` | 4.9 | -16.6 | -1.7 | all | `a0c6ca120e0c60310b9715d7a668786b32f156d0012507186d725731a83341d7` |
| `callbacks/c04b7s.ogg` | `1099` | 2.56 | -16.3 | -1.6 | accepted on review | `697b7e198e13ab92e276ea7dcafc9109dc655fb2a732460cebb7b372892e9cc1` |
| `callbacks/cancww.ogg` | `1099` | 4.3 | -16.2 | -1.8 | all | `c4b648a4d57e6ac05ce60e4d3ff90241ffe2a5e519800233a4137952763ece2d` |
| `callbacks/damnxl.ogg` | `1099` | 6.2 | -16.8 | -1.8 | all | `8a4a1967c24fcf056e1f72d6d1818ddb4fcf4c0667707d16852a780559e2e171` |
| `callbacks/divgo1.ogg` | `1099` | 5.2 | -16.9 | -1.4 | all | `b33594a32cf889b1fa36c6baaa883b4685465abfae70a460182614adf8992ad0` |
| `callbacks/do9yfj.ogg` | `1099` | 3.81 | -16.0 | -1.9 | all | `3f95450d9f49ac94ebb57c3f3be7ee13f93316a5266a37a38946bd7b90a834f8` |
| `callbacks/e9z8a6.ogg` | `1099` | 4.3 | -16.2 | -1.6 | all | `f49585a5bac5c10f62c016d002d72fc777bd2a1bd54baef92c84fa1dd9804db3` |
| `callbacks/efxyqj.ogg` | `1099` | 5.9 | -16.1 | -1.9 | all | `68315aa7f14ef9f15304856840b85f00c66648220ad1642aeaad35af3a8dc512` |
| `callbacks/egerp4.ogg` | `1099` | 2.02 | -16.0 | -1.7 | all | `6aed0856b5f34edf4fc79b98dd7fef2c89236f2df0e5ba639dc75f08826a4fb7` |
| `callbacks/ektz83.ogg` | `1099` | 4.9 | -16.5 | -1.7 | all | `941eb6bcc576e572b703164c7280672c0b10bd1c07f0425fdc001e71457db761` |
| `callbacks/fdovjn.ogg` | `1099` | 5.0 | -16.0 | -2.0 | all | `84b9da62e8d4bbeac2021a289ad34b31f1897c3393cc3f0ec7f31d16a0518451` |
| `callbacks/g8o2ay.ogg` | `1099` | 3.62 | -16.5 | -1.7 | all | `fe49611e99491de91469253e7205d4263c00539d2701d25e3bdbd93efd6e0070` |
| `callbacks/gl7dtl.ogg` | `1099` | 1.74 | -16.0 | -1.8 | all | `d9d3f5301415d1e15a24335d1ae7f9b65de7d4824b15307c79b5af149465860f` |
| `callbacks/gu8esa.ogg` | `1100` | 3.22 | -16.8 | -1.8 | all | `8e155e943c572a6ccc5fe04fb8cd8dfc996524c8a79b7a9aac2c514b0af04610` |
| `callbacks/h4qm7n.ogg` | `1099` | 4.4 | -15.9 | -1.6 | all | `308c0e7e2b8f026a84a640d7672ce78e358a4406754e5a9c0093500ab9364b99` |
| `callbacks/h5bvsg.ogg` | `1099` | 4.7 | -16.4 | -1.7 | all | `3612dc2a4abdabbdfda981b69be31ffb8d2b72ed20674b4e849dca7efde507fa` |
| `callbacks/ib8twp.ogg` | `1099` | 5.1 | -16.5 | -1.8 | all | `4fad5aca184e2bb15d9e18c738045976c6b4624dc843ac0884205b619214cb83` |
| `callbacks/ibi7nd.ogg` | `1099` | 5.4 | -16.4 | -1.7 | all | `7c4285f5fb54b33a403a0f0bd3aa044f0616c0ea7a9e9f7dd2e924c5ff883162` |
| `callbacks/iqtbyc.ogg` | `1099` | 2.68 | -16.0 | -2.5 | all | `8b0808fdcfc7e5c342ca124c9ee6259fe360729bc37e997cf9502bf07ee30a71` |
| `callbacks/irkd4i.ogg` | `1099` | 4.7 | -16.4 | -1.8 | all | `9930732ba4528bb117904878c941803bb1a8bf0b4e48fdcdbab3de7f2b5e5c74` |
| `callbacks/iuc4by.ogg` | `1099` | 6.3 | -17.0 | -1.7 | all | `29bdfa1d550b6cfd5bf43d99e3055f0653eb9e58fbc04347e55356649b41a177` |
| `callbacks/iumjzl.ogg` | `1099` | 4.8 | -16.0 | -1.9 | all | `255c209b401d36fd91d3b8fd63bdb1369afcb728a2ffd8ab07e52946bb967d1b` |
| `callbacks/iyzz2i.ogg` | `1099` | 3.42 | -15.9 | -1.8 | all | `0cdb34f6493cfbef13d61bb9dd155523acb1782a3d4030a8bb59311153b489a1` |
| `callbacks/j15an9.ogg` | `1099` | 5.9 | -16.3 | -1.7 | all | `e234e196ccccfe62968cad94bc3213cd723015afe860fedf02df0fad8bdaf070` |
| `callbacks/jwrf1g.ogg` | `1099` | 4.4 | -16.8 | -1.8 | all | `91c770eb4d56c173a85ca749bf4a6f653ae593ffb0a973279e06777a0bce7bb7` |
| `callbacks/jwrnyp.ogg` | `1099` | 7.6 | -16.3 | -1.7 | all | `9ea2b00a1b1876b49cb6039475bd2e1260bd2493e0da9d8762b13898dc680907` |
| `callbacks/k6l33d.ogg` | `1100` | 5.1 | -15.9 | -1.8 | all | `111d2a33669eb6629164bf3483954dfe4c1caa4b095ddec0a98382c671d367b6` |
| `callbacks/l06ng5.ogg` | `1099` | 4.1 | -16.4 | -1.6 | all | `dd363be845bda9137fc50a29241b4d1a778a38489d01bfb4a8c37d372642b9db` |
| `callbacks/l16wmu.ogg` | `1099` | 3.29 | -15.9 | -1.9 | all | `7a6869c13267835ccb86abc83132e29ea1203872aa7267040c1f384bad30b3bb` |
| `callbacks/la4942.ogg` | `1100` | 5.0 | -16.4 | -1.7 | all | `20ba179e7921463c36017229655181149a69651d657f7a49890ba9fd7f79d942` |
| `callbacks/ln0w32.ogg` | `1100` | 5.6 | -16.0 | -1.8 | all | `b0a06dc86ed313bb35eb42f64279a61a1d4e5cfae265ef12c2447f2669d0b220` |
| `callbacks/m8nchx.ogg` | `1100` | 6.2 | -17.0 | -1.7 | all | `76680796a8bbfafd3bb08f0315c50dc6d3c8bec929bf1c599b1066889dadf238` |
| `callbacks/mx9tnl.ogg` | `1099` | 2.99 | -16.1 | -1.8 | all | `102c7201cd668cf3025e62121cba96ab1b7cea9d7d8a185613b695118f123d8a` |
| `callbacks/n2gvfk.ogg` | `1099` | 5.9 | -15.9 | -1.8 | all | `e068b1bacabc332bfe2d34f09defefd93eeb47ac457aa580c60f37be870c10eb` |
| `callbacks/njgjnl.ogg` | `1100` | 4.8 | -16.3 | -1.7 | all | `dec22f797330627045e0a4a02cb03a404ea48a3fda69ce953b9a322f4f65381c` |
| `callbacks/oahrim.ogg` | `1099` | 4.1 | -15.6 | -1.8 | all | `4c01ba4dca12858904ae6570396ce8a5de6f48966c65bfdfa620c952f5c3ea2a` |
| `callbacks/ocvbwv.ogg` | `1099` | 6.2 | -16.9 | -1.8 | all | `c1960a4b6c14a43d2e6a2a063314a7209a22f54947e4237f86ec06feff22a7c7` |
| `callbacks/ogqj02.ogg` | `1099` | 2.06 | -15.9 | -2.7 | all | `55aa60d3ad63ce3672cad34f013afbcac7c2a20f209572faa4edb82c523e3e57` |
| `callbacks/okt7kg.ogg` | `1099` | 3.09 | -16.1 | -1.5 | all | `c0e89c752b82abcec9d4d8b8276697fac0ada62e196e896ed9f419b0f70ea26a` |
| `callbacks/ow9ffb.ogg` | `1099` | 6.6 | -16.3 | -1.6 | all | `9052f556c9ad3b4a482ea91295f74c79753f734cb03cad87fd32be03588b74fd` |
| `callbacks/r15qbx.ogg` | `1101` | 6.0 | -16.1 | -1.8 | all | `6db0ab44d6dfff065d8fb2caae5d1e6e05277e897e9a2274b0cb03b9c783c079` |
| `callbacks/rtuuw3.ogg` | `1099` | 4.9 | -16.3 | -1.5 | all | `e011aa7b88c3bffb9e5f24da6a4a8401fa31e6a2122ee3f12225f9d6bfc0417a` |
| `callbacks/sw2aoy.ogg` | `1101` | 5.6 | -16.0 | -1.9 | all | `97cf3938aabb24551ea0a44f0f27f7ef3d24e8c12bfdb094af3fa259540fce37` |
| `callbacks/teu16s.ogg` | `1099` | 2.95 | -16.0 | -2.7 | all | `f843d5fd9144f8bbee4134dc0016a74cac0e51c6f4e821b7431c2aa21a5a1c94` |
| `callbacks/u43pd0.ogg` | `1099` | 2.62 | -16.4 | -1.7 | all | `63eac96c3f51151b92dfc8f40d056c6c47eaa1e3ed66089692416afcbb3047e3` |
| `callbacks/u60y2n.ogg` | `1099` | 3.03 | -16.3 | -1.8 | all | `83c54a2485e98821a143af8d57d6424733bddbcf7c2dafb919f87bc674b43ab7` |
| `callbacks/ufxmro.ogg` | `1099` | 3.55 | -15.6 | -1.8 | all | `eaa795d30f27f4954db38c3685e400f80bf9ad22a1822472938a57fbe4b41c9a` |
| `callbacks/uo4qot.ogg` | `1099` | 4.0 | -16.3 | -1.8 | all | `29657a871e9171f29a3cb16f4221b78a32541472ac46284e395c02c0ced41b2d` |
| `callbacks/ut8s7q.ogg` | `1099` | 3.73 | -16.0 | -2.1 | accepted on review | `855fcbeca761ac9176c6a218c780061a250a5f339f73555425b6941e7ae08882` |
| `callbacks/va53qs.ogg` | `1099` | 3.28 | -17.0 | -1.6 | all | `b0875af19eaabaccfc0bd68938d059ab26215c89b7c06a9b1624b66fad288bda` |
| `callbacks/wg201a.ogg` | `1099` | 4.2 | -16.8 | -1.7 | all | `94502cddd4f19e5fe2f0ca5fbe5b2081a8a723b77db807b412c2e2163740862d` |
| `callbacks/wgf1er.ogg` | `1102` | 4.5 | -16.0 | -1.9 | all | `82f3acf916d96c2f395b5fcea0e28044a8e8326934476e554b1ee73af565e1ec` |
| `callbacks/xd8iw1.ogg` | `1099` | 5.3 | -16.1 | -1.8 | all | `019123675b7f136e7036d73a8df2ffc517bcc1038613c01d533fda48fc7719ab` |
| `callbacks/xmcam8.ogg` | `1099` | 5.4 | -16.3 | -1.7 | all | `a686c01d91ab61c2d28090922467b9c908d8b5f82f31efed58cbb3081252fcd4` |
| `callbacks/xtokhe.ogg` | `1099` | 2.62 | -16.1 | -1.7 | all | `3e5be294c8fbe6530c5a5b73fdb86df56af63a3cdda4733d48fccdeddde78a4e` |
| `callbacks/xxkpsr.ogg` | `1099` | 7.3 | -16.2 | -1.7 | all | `3874a7cb81c3fa11f398cd1c896e70aacf7f249ac053901e4bb41444bee4a591` |
| `callbacks/y1spef.ogg` | `1099` | 3.54 | -16.2 | -1.8 | all | `d7769725b0877b327cfdd2f3147fafcf8ace76f41d254909b24fc43349c26cd0` |
| `callbacks/y2pesi.ogg` | `1099` | 2.43 | -16.0 | -2.0 | all | `7e3cf25099600265d79f231e1d1e4adce3d5dc2ccec85173b4dc17458fcb62a6` |
| `callbacks/y9dawk.ogg` | `1099` | 3.58 | -16.3 | -1.8 | all | `f56dc85d3c4cbf728aa2199d1c8be8133c4bc897a482c919dd7e998efee2f1a9` |
| `callbacks/yl1cu9.ogg` | `1099` | 7.5 | -16.2 | -1.7 | all | `181e5a9d8f00cdef6133a76a73d14c927aa4d6ee6bf932622c7c85d1292eb5d9` |
| `callbacks/yyfiz5.ogg` | `1099` | 5.5 | -16.6 | -1.7 | all | `0b25a1894d5834d508f5e1e22d1ee9b1e7a9c68eab46223eee06a89655e2627f` |
| `callbacks/yz66km.ogg` | `1099` | 5.4 | -16.3 | -1.7 | all | `e70af075e522960bf909138b1efc3603d9877de289ba780c6a0058a35f07c4a0` |
| `callbacks/z7nx3b.ogg` | `1099` | 4.4 | -15.9 | -2.0 | all | `95282f2f6c455ff318f18398cca49dc5269d1f6eb9f8a9788f90b1ba49085240` |
| `callbacks/z9ank5.ogg` | `1099` | 6.3 | -16.0 | -1.7 | all | `3a8e807228cbbbfd2647209196c9beada5cd8021be5b6e490222e2d6d3d16ea8` |
| `callbacks/zd08l4.ogg` | `1099` | 2.51 | -16.0 | -1.9 | all | `b7c0ee597720376cfdb62294ee9ca3a5af654b7898fc7b1eb7efe4e197cd9ceb` |
| `callbacks/zf3b4q.ogg` | `1099` | 4.5 | -16.4 | -1.7 | all | `a9e2d291310c6951e8b57c35f94411872cce86ef454be1f6fed390633a545496` |
| `callbacks/zj8b8j.ogg` | `1099` | 6.2 | -17.0 | -1.8 | all | `eaef03d460f283074132ce66f8a4c30650ce6d9399a93837e7a2f59e0be42654` |
| `callbacks/zp1z2g.ogg` | `1099` | 4.9 | -16.7 | -1.6 | all | `3d88b518611313f710598dfc577315c1342f2a0c06176f1ac66c9a1fc36cbe25` |
| `callbacks/zp7a9a.ogg` | `1099` | 2.31 | -16.4 | -1.8 | all | `45b833d70bc8d57e7abd14dc7ff6334bc25100d5c7be9f5b8d6858fee6e5c8d8` |
| `callbacks/zwbeac.ogg` | `1099` | 5.7 | -16.6 | -1.7 | all | `66b0135eb032086a2eeee77d9dbc4ef98059c29453b23561dad0a1b6697ef9b4` |
| `callbacks/zzl6am.ogg` | `1099` | 5.5 | -16.0 | -1.8 | all | `08f5f6b67ccf8dccdb21aacac4fcd178985f1d75bf1020badff274ff31c23c2d` |
| `ex.functions.function-machine/25tykc.ogg` | `1102` | 8.8 | -16.4 | -1.9 | accepted on review | `aa7038f3f5cf68e079fdea470a429409ff618d56ae0f29c842da6b86815cd460` |
| `ex.functions.function-machine/32gfjc.ogg` | `1099` | 5.2 | -16.0 | -2.0 | all | `5cdf63e9b7806a70bbd5edc20bc11bc5b6b4601f5f9c5ac8e72666414ec3aa6f` |
| `ex.functions.function-machine/3lrx6r.ogg` | `1099` | 6.6 | -16.2 | -1.8 | all | `9d88b16adb979a0fe54be72faeb134ccb4de9439dd24a4654d8b3288552cf299` |
| `ex.functions.function-machine/4xrt6n.ogg` | `1099` | 6.1 | -16.1 | -1.9 | all | `0de7515adde68d2c82d4640528f178a71c62317f5edf8e944666a2e1505fcac6` |
| `ex.functions.function-machine/600tj9.ogg` | `1099` | 9.6 | -16.2 | -1.7 | all | `a1c6c63ac8c0876423631f8e6f446d7ef6a64bf4318025b3ba2e5c1c3559e281` |
| `ex.functions.function-machine/6y6unb.ogg` | `1102` | 10.1 | -16.1 | -1.7 | all | `c7c0a6161d21b94d7cc3470d498c519c4fa3ce9efe393df3cd3ee4e9b45d6eb5` |
| `ex.functions.function-machine/814c8q.ogg` | `1102` | 4.4 | -15.7 | -1.8 | all | `3f1d69b30ca7d710486826236c21015ed18fb2d8c50c819017471ab147708cf7` |
| `ex.functions.function-machine/8n3avo.ogg` | `1099` | 6.6 | -16.0 | -1.8 | all | `20827b7965bfa01e75ed81d8610a8c0b62d673560cde3acf0ad53f9fc66225c4` |
| `ex.functions.function-machine/8pg7zc.ogg` | `1099` | 10.3 | -16.1 | -1.9 | all | `cea6722fdd04043dc020e02ac629d2b0b01472e377349344f2422211f94d1333` |
| `ex.functions.function-machine/9mnd1e.ogg` | `1099` | 10.6 | -16.0 | -1.7 | all | `f6eb9d42f529619b328d36eec0123b562ad75daeca5e909672f8179c2f37b008` |
| `ex.functions.function-machine/9ns3id.ogg` | `1099` | 2.54 | -16.9 | -1.9 | all | `0d066ce5f12267aa9be9fb48f9b224b699f7c5dd07e8090465049ce38e209260` |
| `ex.functions.function-machine/9yz3t9.ogg` | `1099` | 7.8 | -16.1 | -1.7 | all | `a5e5b6dbba0546f8434d4ce86c55c380ab1fab9304438b69021fb35b8eaea32f` |
| `ex.functions.function-machine/a13oav.ogg` | `1100` | 11.2 | -16.1 | -1.7 | all | `b07c38ad24cbae3cb4f8a9d03c22a554bb67b02ffd067df58d8e55c8ce0bcbf3` |
| `ex.functions.function-machine/ae40hw.ogg` | `1099` | 4.3 | -16.3 | -1.7 | all | `c0f47157f75fc422441b6daef032c3f9e8b72c7132b6c8a21f38df5c2bad5855` |
| `ex.functions.function-machine/b7n1cv.ogg` | `1101` | 9.3 | -16.0 | -1.9 | accepted on review | `d433f8050e3b2fa3ab7fbfed06633a0bbca5482d7943a561375c2ebd86339127` |
| `ex.functions.function-machine/cuomiv.ogg` | `1099` | 12.3 | -16.0 | -1.9 | all | `5dd79ec7af0a21b76d15b9c2a8071f2a9dcceb844e6b9f79bcaef54b9d5da6f1` |
| `ex.functions.function-machine/d1ax0c.ogg` | `1099` | 4.9 | -15.9 | -2.1 | all | `49dcfe6d10164bd0156d0682ce260fb264a6e767d145f5c70bc8c1a6b4a568fd` |
| `ex.functions.function-machine/dpsdof.ogg` | `1099` | 8.9 | -16.2 | -1.9 | all | `f326c3e617fe43c441427603da7a6f2ed24dc57d51035c20429d8829f9dc6bab` |
| `ex.functions.function-machine/exxlak.ogg` | `1099` | 5.9 | -16.2 | -1.9 | all | `7f565465f8c6096cc110e692d1ca72670b08e0d7da6d0743abfe74dd524fdfad` |
| `ex.functions.function-machine/fqalba.ogg` | `1099` | 2.95 | -16.4 | -1.5 | all | `e7bc7a0ee35792df011886cbd1ea2cb04f03eaf62e7bd0b38a5cde7ab422573a` |
| `ex.functions.function-machine/fuqb8v.ogg` | `1099` | 4.5 | -15.8 | -1.7 | all | `76707f8c94fce0a3bdb0f2cc1edcb7c25f5393063df65d69eb0ffa47c86ff067` |
| `ex.functions.function-machine/gdomnv.ogg` | `1099` | 5.2 | -16.1 | -2.0 | all | `3f79db1a6d25c88ab055df4f72beee5dc019ec5389f696c4df88173f007a2327` |
| `ex.functions.function-machine/h0quul.ogg` | `1100` | 4.6 | -15.9 | -1.9 | all | `efae5c7c2cb345c1d264e66f9d5019c4d101fe9f66fe032bf8840b2993094400` |
| `ex.functions.function-machine/h2fzl4.ogg` | `1100` | 5.9 | -15.9 | -1.8 | all | `93987aac1356c7c57ae52ef6303f4dd4fb70d6464836f6eff48efbea2b42e417` |
| `ex.functions.function-machine/i461et.ogg` | `1099` | 5.1 | -16.1 | -1.9 | all | `c7c5317d7a75e93f2b2d61a3dd85f0139b00c6aae2ffafc758f4341ff3366580` |
| `ex.functions.function-machine/iyz9tu.ogg` | `1099` | 5.7 | -16.4 | -1.7 | all | `e7d94446a32d01d2b581635ce7cd5a1bd63cb9ef2a65bd76ebe9c80bc20ac9ba` |
| `ex.functions.function-machine/j7nxs0.ogg` | `1099` | 3.31 | -15.9 | -2.0 | accepted on review | `273f251307533b2f853d6074a7e1d1867586dd86ae719918280ebcba8959244b` |
| `ex.functions.function-machine/k4e8xl.ogg` | `1102` | 6.5 | -16.2 | -1.8 | accepted on review | `4c0f31f080e0f320c897ecf545dd766aaf1055d20909d9e470543e06961bec50` |
| `ex.functions.function-machine/kpmso6.ogg` | `1099` | 4.9 | -16.3 | -1.8 | all | `fddbf0f0e84dafb7f08049fb3da383542831f1914b6996c2bad55818d8883d5a` |
| `ex.functions.function-machine/m3jh3m.ogg` | `1099` | 10.7 | -16.2 | -1.8 | all | `42a0bfa343a4ce2c1afa6545f884c9c9f64fe1516efbdfb6ff0ef79b1dd81506` |
| `ex.functions.function-machine/m9zwlf.ogg` | `1099` | 6.9 | -16.0 | -1.8 | all | `9690994e63010bd5a38325769ae4afef4c71506ddd8bebb67824711d14bac021` |
| `ex.functions.function-machine/mnghoh.ogg` | `1099` | 3.72 | -15.9 | -1.9 | all | `56929b2466b615e880d98161dea53ab17e076ec4ece4ef6b1051f0316bad4813` |
| `ex.functions.function-machine/nr0gxp.ogg` | `1099` | 3.87 | -15.7 | -1.7 | all | `887e71e0f549374c8bad9cd3cbaf847f65855c95010bd4b843da9cc7d13c1131` |
| `ex.functions.function-machine/nz3crl.ogg` | `1099` | 6.8 | -16.0 | -1.8 | all | `e31f9a892109080aeedbfb04b4d20ea9ff81b6fe66ffe872c1e44b9a2d440741` |
| `ex.functions.function-machine/olmxem.ogg` | `1099` | 1.92 | -16.1 | -1.9 | all | `620ac5823bda883d6449afeb72b43064a86ea55e9ec4425e1667064747745788` |
| `ex.functions.function-machine/ozpwe8.ogg` | `1100` | 4.6 | -16.0 | -1.9 | all | `05f319859c424eae6ef8ddf23757d460894532b9ce07aaeac07ad831454d47df` |
| `ex.functions.function-machine/p1wrwn.ogg` | `1099` | 3.89 | -15.9 | -1.9 | all | `48e94990eb3bf715bdcea048a7df8cb007560b19b18db444cbce2103667fa813` |
| `ex.functions.function-machine/pcw8sz.ogg` | `1099` | 8.0 | -16.3 | -1.9 | all | `636c901dc6a17c74d5d8f9671da1ee583f925bf6d74b18ac1f8c45dbdf77af3e` |
| `ex.functions.function-machine/pp94wv.ogg` | `1099` | 2.67 | -16.0 | -3.2 | all | `966e24e96fe5c9cfda319354c89f3df9e18a3f531e17b90846285cdf8f3be76f` |
| `ex.functions.function-machine/pqbbvg.ogg` | `1099` | 2.54 | -16.0 | -1.8 | all | `c002c66bc8f37296a197cef486c103cc6896f49bd33dbd589d3a6c000094d52a` |
| `ex.functions.function-machine/q1vsxs.ogg` | `1101` | 4.5 | -16.0 | -2.0 | all | `7c8847bf239369b26e1f5c3c2a75a75fd13a0b55422ddfb73e003efaeafa0206` |
| `ex.functions.function-machine/r8sxff.ogg` | `1099` | 6.5 | -16.0 | -1.9 | all | `b547298d395b2279d4c373afb9fe2b007ba9ac34f1a41d134640f3fb6a024255` |
| `ex.functions.function-machine/rkgn8h.ogg` | `1099` | 2.13 | -16.6 | -2.0 | all | `de813fd27a5449f05ccb239b2a39789320e6da25ff3754e9619ddb10c5ca2ea5` |
| `ex.functions.function-machine/rwww0h.ogg` | `1099` | 5.1 | -16.0 | -1.8 | all | `64f0d15ef58caca3fdb5d0a12af2694c6619bc012aeff6428bce0bbc722d04d9` |
| `ex.functions.function-machine/shxoyu.ogg` | `1099` | 11.6 | -16.1 | -1.7 | all | `1db81324354133a8d10bf86dd58230d886a8489b40f980771d0ae6fa615acc4c` |
| `ex.functions.function-machine/st498u.ogg` | `1099` | 3.88 | -16.2 | -1.8 | all | `53b75a6b615ed94c3e4183ff20d65537110ae87cc718cdb850ac5dc7ae78e163` |
| `ex.functions.function-machine/taxdom.ogg` | `1099` | 8.0 | -16.1 | -1.7 | all | `9dc4a999a9d28ca33bdc23f074c24bb34a237ef7fd1f8ca528ae4252c2b94f60` |
| `ex.functions.function-machine/tdtylw.ogg` | `1099` | 8.7 | -16.4 | -1.8 | all | `2b4ad015a4289741023421a5fd07b2337c2cc5e3d865b3489ca535ee08aad2a9` |
| `ex.functions.function-machine/u6isa0.ogg` | `1099` | 4.2 | -15.9 | -2.0 | all | `8ba03f16f5cbd971f91e789665a17cd77425a3e3280567577fc4249aab44e571` |
| `ex.functions.function-machine/ug8rex.ogg` | `1099` | 4.3 | -16.6 | -1.8 | all | `13e406134483940d90c6faa0e25d19ed68ac87731bc48a00ca641e9c6be87268` |
| `ex.functions.function-machine/upaeqh.ogg` | `1100` | 3.87 | -15.8 | -1.9 | all | `8d3ea3adbfd78f9190b82053035c979aad5207a2534eec58a8c6484f0a7ee221` |
| `ex.functions.function-machine/utbhru.ogg` | `1099` | 3.15 | -15.8 | -1.6 | all | `81ee088971513ce2c051d16a85fba0fdfb3b8ff60a95ce92f681381340708fd3` |
| `ex.functions.function-machine/uxmvt8.ogg` | `1099` | 6.2 | -16.0 | -1.9 | all | `f65b137772d264ef4c5cf8ef1b17c75760addcd9612f192a8ae120359b97d8b7` |
| `ex.functions.function-machine/vcsdru.ogg` | `1099` | 9.7 | -16.1 | -1.8 | all | `b86c7565538d0292f8d55f74b962da2e89cfe0b915c9ff2204ccd0b4ebdb6906` |
| `ex.functions.function-machine/vnrkur.ogg` | `1099` | 5.3 | -16.3 | -1.9 | accepted on review | `6aed7e6a1bb5adcae835b0fcb0d1722b1030231e920c7545c37d071876d154bb` |
| `ex.functions.function-machine/wilzpn.ogg` | `1099` | 5.1 | -16.0 | -1.7 | all | `0afdc2d9e4a3a1c6ed33dffdd2e93a3f14836ed07089dcf1a856ff2d73137c69` |
| `ex.functions.function-machine/wjnpvb.ogg` | `1100` | 10.5 | -16.1 | -1.8 | all | `a5cc6cead616d0fdca78229b6f7f02488381712f4d93ee6d38dbe17660994e4a` |
| `ex.functions.function-machine/xquulc.ogg` | `1099` | 3.85 | -15.8 | -1.8 | all | `4356fd7c00562a557c0c7c4899de45bf2e1bde399c7f715bb9412e583432fcd2` |
| `ex.functions.function-machine/xqw813.ogg` | `1099` | 7.1 | -16.0 | -1.9 | all | `72ad5618a056751ee8ff1e9ef355485bb1c12bb3b98bf610787a763c0423be6b` |
| `reactions/1c8kk4.ogg` | `1099` | 0.85 | -16.2 | -2.9 | all | `045cb68ff88dcd0967f1193929b8240d8367800d632ca7efbfb7fa1633a75398` |
| `reactions/5ena6n.ogg` | `1100` | 3.36 | -15.8 | -2.0 | all | `fd01ce5a3a463c48259cc0992c94b787b0726a9d5a13f47088443775ed2c6bab` |
| `reactions/8oguve.ogg` | `1100` | 4.3 | -15.8 | -1.8 | all | `a4c1d7c306fa087f03d3d92b90f9d5fce1c491db6ba5bb9b0b60b1ea6a901dcb` |
| `reactions/9rzsaa.ogg` | `1099` | 0.78 | -15.9 | -2.1 | all | `68ee2492008a772592d18f389e1c465c39b00a13e62e3fb1e672968e8d905c03` |
| `reactions/daxuz2.ogg` | `1099` | 2.22 | -16.0 | -1.9 | all | `c883beff8ecb7ef7e5b41812693589446147166ac72b952ed188361420e96236` |
| `reactions/i2jaqx.ogg` | `1099` | 2.38 | -16.0 | -2.3 | all | `07222365b5ad878ae47c8ffa3855d67d102fbe886fb11f01fabe0e2b033fc023` |
| `reactions/ml2cxq.ogg` | `1103` | 0.81 | -16.6 | -1.6 | all | `b9cbb034a51cf60b795753400e2316cc4747ff963444d67fdc673bfa51e9e36c` |
| `reactions/z1xu8j.ogg` | `1099` | 3.84 | -15.3 | -1.9 | all | `484efebf4719cbad4a91b383a7e8ef6634a4d773be898c2a265210886b76feb5` |


## FAL-1137 — every tutor's new reaction lines, local voice clones (voice)

136 voice files in `game/assets/audio/voice/explainers/reactions/`: the new `ack` and `slip` lines of `writing/explainers/reactions.json` (FAL-1136), 24 each for Tin-Can Tess, Mags the Ledger, Kara Meridian, Lucky Lenoir and C.A.L.C., and 16 for Rook Dead-Air on top of his 8 from FAL-1110. The words are each line's `say` text exactly. Each take is also recorded in `writing/explainers/manifest.json`. Generated locally with VoxCPM2 on 2026-11-18. No recordings of any real person went in.

Rights basis, voices, references, cloning settings, text fed to the model and processing chain: all as in the FAL-1110 section above, unchanged (falcon-voice `clone/record.py`, `clone/post.sh`, `clone/wa-explainers.py`).

- **Seeds:** 1099 first, then 1100 and 1101 for a line whose words didn't match (3 rounds). 102 lines matched on 1099, 10 on 1100. The other 24 kept their closest take and were read by hand (below). Chosen seeds: 1099 for 119 files, 1100 for 13, 1101 for 4.
- **Checks:** every take transcribed with faster-whisper small (CPU) and compared word by word with `say`. 112 matched. These 24 differ only where the transcriber can't follow, and were accepted on reading the diff: `reactions/2pqmuf` (roll -> role; roll -> role: homophone (roll, role); the seed that dropped off was not used); `reactions/8d9bwx` ((extra) -> should; should've -> have: should've and should have are the same words); `reactions/8v4i1s` (gauges -> gages: spelling); `reactions/aiq394` (mm -> hmm: the transcriber writes Mm as Hmm); `reactions/au1j35` (can's -> cans: homophone); `reactions/d50vxt` (reached -> reach: the ed of Reached runs into them; Lekker heard right on this seed); `reactions/dvogx3` (pin's -> pins: homophone); `reactions/dzgzfk` (pencil's -> pencil: the s of Pencil's runs into snapped); `reactions/gf32w7` (treat -> trade: Tess's New Zealand vowel in treat; the seed that said that's for fits was not used); `reactions/hnpdxz` (chilly -> chilli: spelling); `reactions/j4rn9g` (ink's -> inks: homophone); `reactions/l4qesy` (sight -> site: homophone (sight, site)); `reactions/ldaaey` (tape's -> tapes: homophone); `reactions/ltidxg` (bolt's -> bolt: the s of Bolt's runs into stripped); `reactions/ne39vm` (off -> of: off and of run together before the); `reactions/ppg08k` (quel -> quelle: quel and quelle sound the same in French); `reactions/rg2dql` (change -> changed: change today and changed today sound the same); `reactions/tdbhq1` (ja -> yeah; through -> true: Ja heard as Yeah, as on FAL-1110; through heard as true on all three seeds, Rook's South African th (the closest a transcriber gets); listen first); `reactions/tgp5x1` (battery's -> batteries: homophone); `reactions/vbbab9` (that'd -> that: the d of that'd runs into hold); `reactions/wyhvd5` (non -> no; non -> no: the transcriber writes French non as no); `reactions/xle2z6` (ehen -> ehem: Ehen (Kara's interjection) is not an English word; this seed is the closest); `reactions/y7w6mr` (pff -> (missing): the transcriber drops the Pff breath on every seed); `reactions/y97n4o` (alors -> so: the transcriber translated the French alors as so).
- **After the last word:** every take was split into sound islands (20 ms frames within 35 dB of the peak) and lined up with the transcriber's word timings; the 39 takes under 1.5 s were also read on spectrograms. No take has sound after its last word.
- **Measured across all 136** (music-tools `bin/check`, 4× oversampled true peak): -19.81 to -15.76 LUFS-I, -3.70 to -1.29 dBTP, 0.57 to 6.22 s long, 5.9 minutes in all. 24 short takes are below -17 LUFS-I even after `clone/prelimit.sh` (ffmpeg's loudnorm can't level a clip under 3 s linearly); their loudest 400 ms is -17.7 to -13.5 LUFS against -16.3 to -10.9 for the rest. The first and last 20 ms of every file are at least 86 dB below its peak.

| File (`game/assets/audio/voice/explainers/`) | Seed | Seconds | LUFS-I | dBTP | Words heard | SHA-256 |
|---|---|---|---|---|---|---|
| `reactions/04yoat.ogg` | `1099` | 3.88 | -16.1 | -1.8 | all | `0978b2356ce8738a8d6cb4cb2fcbab779cdec25ba7dca1e7c53cd0fa6d213ce8` |
| `reactions/06yedo.ogg` | `1099` | 0.86 | -17.5 | -1.7 | all | `28d411d2677942f5fb549ccf1b24e0a542d7c2150d138925316545db48bcf263` |
| `reactions/09hbpf.ogg` | `1099` | 3.37 | -16.2 | -2.8 | all | `27ad43de291b76315d2ae8ffb2e9e44b5282f3434893fad521d4271ad6026a96` |
| `reactions/0woojc.ogg` | `1099` | 1.34 | -17.1 | -1.8 | all | `ba4c504f8efa0117b0427cf0352ac3f4ba737116c39082434225dc1a6f5c1e2f` |
| `reactions/11axk3.ogg` | `1099` | 0.57 | -16.4 | -1.8 | all | `30107be3ffd0461ee2596dbb5ee56814c2b7def03ca240d69aafe3ecef23d8bf` |
| `reactions/1h3qvn.ogg` | `1099` | 0.64 | -17.2 | -1.8 | all | `0c98ccf32af565116541f6da94eaf235e61d9f6f6eddeecb33dcba22b1843c4c` |
| `reactions/2cc4fo.ogg` | `1099` | 3.13 | -16.4 | -1.8 | all | `5513d43c9094a2fde398130ffe802b9ddeb04273191c80fc6c5e54f12dd2ba9b` |
| `reactions/2gi7wy.ogg` | `1099` | 4.4 | -16.3 | -1.8 | all | `57c94ae51bdbdd41bd656f6c814d67791cf09ca0d4e6eb386d7c5c25f679f9e7` |
| `reactions/2pqmuf.ogg` | `1099` | 4.2 | -16.3 | -1.7 | What a role. Off the table. But what a role. | `1a1794bbbacca44d4962f1c7d167207236930a332eded90407f1c3600d3b77ae` |
| `reactions/37lk5e.ogg` | `1099` | 2.37 | -16.0 | -1.9 | all | `c319a29c78a90b30b0be7f3bec9fe7966b4197d8adaad3e686efd8813b0f6f25` |
| `reactions/3z93sg.ogg` | `1099` | 2.01 | -16.0 | -2.0 | all | `79170b7095349a43ac55af35a1796e00f6a20f780488ddc0efec9423b13e17df` |
| `reactions/41t8vc.ogg` | `1099` | 2.75 | -16.0 | -1.8 | all | `d7aa49ac448f9dbae70ad30afdd639c42498bb446de1fd20702cdc2bf3560e66` |
| `reactions/4ivq3e.ogg` | `1099` | 2.88 | -16.0 | -2.0 | all | `cd88010ecf59e3a132e3a81afee84b267ea276f0fb04ffc246702fb195571108` |
| `reactions/4q7pz6.ogg` | `1100` | 2.76 | -15.7 | -2.1 | all | `cbd886ebd72a32852eea000ca22b71459b62ab565426884b49f8ccf102caab7b` |
| `reactions/5jcjln.ogg` | `1099` | 4.9 | -16.8 | -1.3 | all | `3f9a89af7195802cac025103fec9ef834a96c7a6a3b363c4ea675433b17ad0c3` |
| `reactions/5rzrn8.ogg` | `1099` | 1.93 | -17.2 | -1.9 | all | `81c7076c6dddab31304bccfe7a720513cb1b22bc9a2d21a588dd54f32a070b64` |
| `reactions/6f3a7e.ogg` | `1099` | 3.4 | -16.1 | -1.9 | all | `5ccb6bb55aca925bd041511120ea4e875424bbc4ae041c4067e2e42ebe38d171` |
| `reactions/6xpivq.ogg` | `1099` | 6.0 | -16.3 | -1.8 | all | `d2cd47aa89a3f85d145c649f2796bc5c596988956e1572ab7ae5931c38f75645` |
| `reactions/6ykvu8.ogg` | `1100` | 1.36 | -16.0 | -2.4 | all | `b4e29de2b4f605707e05514748ef9335ec24e56d80eaf2107ef59a09e33bc4d8` |
| `reactions/6z4k6g.ogg` | `1099` | 2.52 | -16.2 | -1.6 | all | `6d873dad0a82c9fe74bbdb2972ca1e759bda8d660af11193e606e9e3df804b28` |
| `reactions/7j3q9n.ogg` | `1099` | 3.01 | -16.2 | -1.7 | all | `c179cede656f3ee99ef729028b2d1c85b7654eb33ffed26a77c33026e59615f2` |
| `reactions/85ycum.ogg` | `1099` | 1.66 | -18.9 | -1.8 | all | `816bb9e4a296a2787bbe43f5c6ca83ad18763a9ce0f9050b7f9794e0e6270a51` |
| `reactions/8d9bwx.ogg` | `1099` | 3.56 | -16.7 | -1.6 | Scales tipped my tea over, should have moved the tea. | `d8c058416d4df1be08cedc16aa72e01f1c61075e99dc65e1a6f7fa78d11acd29` |
| `reactions/8hno54.ogg` | `1099` | 2.67 | -16.0 | -2.8 | all | `8246a3ff1c9626a1530e324d416b41ba68d28c186bb8581551820346dc41a924` |
| `reactions/8jj8yc.ogg` | `1100` | 4.2 | -16.3 | -1.7 | all | `014e6ec5abbcb81f57f8f4fa0ceac1d5db134b74dc3a5e0d3fdf5889e9fcc6c9` |
| `reactions/8v4i1s.ogg` | `1100` | 3.44 | -16.1 | -1.8 | Gages are arguing again. Pay them no mind. | `6baa27d8833cd3122428ce12fbcabbe74ea2d5df9b87c573b977e9ec4f324bbd` |
| `reactions/905zud.ogg` | `1099` | 1.34 | -16.7 | -1.9 | all | `a0e251ce79d5c296708af4f61ea240cd359dd8a0f426e331a00dfc9f70ae8d83` |
| `reactions/9rdsq6.ogg` | `1099` | 0.94 | -18.5 | -2.0 | all | `56926468265e2e6262f9c76d214d26a23d47ce15d95af3fc5f66ba6ded15f4f8` |
| `reactions/9zn6ec.ogg` | `1099` | 1.86 | -17.0 | -2.0 | all | `e251e0a4ed9261f4e3fc23d06e69384c2b1d96ef555259468823d79296c67e4b` |
| `reactions/abz3i7.ogg` | `1099` | 3.38 | -16.2 | -1.8 | all | `28ff3a359bd7ec375f2516d99758ef248422cb3723739692b2580df31c4a441f` |
| `reactions/aeznlk.ogg` | `1099` | 2.65 | -16.8 | -1.7 | all | `aeacb22c2b0fbd9e18a8243a914089bbd819f27c1dd99d07afe5c2da455a2b5b` |
| `reactions/aiq394.ogg` | `1101` | 2.26 | -16.0 | -3.7 | Hmm, smooth as a new deck. | `f4f0a37cdf8e54ca2a28cbed400ea724ada3d2ace3a0a9adbba0cfa15e649c0e` |
| `reactions/ar9syr.ogg` | `1100` | 1.9 | -16.0 | -1.8 | all | `d3bea2dabab6da29fc5d3082e346ec944730b7dff0970e8b1188b3ec74476768` |
| `reactions/au1j35.ogg` | `1099` | 4.0 | -16.9 | -1.7 | Jerry cans glugging all over the floor. Oh well, it's mostly water. | `2f19115ec605aa0243d04fb7c94a930d56249035014070c0766d3f69628e8b6c` |
| `reactions/biuyqz.ogg` | `1099` | 3.67 | -16.4 | -1.8 | all | `e071c07a9e14a8414728d59a3807473c48fb38fe0cd4d071d66d6fd58c3ffc9c` |
| `reactions/bjxljj.ogg` | `1099` | 5.0 | -16.2 | -1.6 | all | `8fe81ecaa9e2ccc1728ed47988dfe667a93f681683c2c4d16d3bf207ce9d8a45` |
| `reactions/bn4te4.ogg` | `1099` | 2.15 | -18.5 | -1.8 | all | `a1c112cf781325ecba669ece44475a4b2faaa311d0a0171ca66b416f123c27af` |
| `reactions/bypd5d.ogg` | `1099` | 1.14 | -16.0 | -2.3 | all | `d672e7b539f7f662c94c6445f684f41f5bb844e8a634071a7f6021905ee16ae9` |
| `reactions/c58kaq.ogg` | `1099` | 3.17 | -16.3 | -1.6 | all | `cc643222f92d4d226a3078de4a493cd9d106845222cc7c0b14df0dfa07d3e29a` |
| `reactions/ck96df.ogg` | `1099` | 1.31 | -16.5 | -1.7 | all | `f3caa862f62d2c1eaae7771b0be335b8f163b576208d434b610415ae4efbb0be` |
| `reactions/crf4e2.ogg` | `1099` | 2.9 | -16.6 | -1.8 | all | `eb0daa0f8aed8c68c9cc405ab4f63516ad200692e7a8af3f84d303fcf7fe70ef` |
| `reactions/crnd4i.ogg` | `1099` | 2.87 | -16.0 | -2.2 | all | `2255f3d08ab1cbb3b602cf37c5c3a61a47533cfa53348d3887269e04995de11c` |
| `reactions/cv25sv.ogg` | `1099` | 2.36 | -16.3 | -1.9 | all | `34450903837343e25fca07591c69b10ddd065ffbf328e564d974ac5aebe81e56` |
| `reactions/d50vxt.ogg` | `1101` | 1.38 | -16.4 | -1.9 | Reach them. Lekker. | `b1dbb0791060366b453be267daff992548e261960ac910ca21f12b07bb632e7a` |
| `reactions/dvogx3.ogg` | `1099` | 1.15 | -15.9 | -2.0 | Pins on the map. | `aeaf4a39d5acdc26acc250d847b1c7c28c939c79473e1150739b46fd33c266ba` |
| `reactions/dzgzfk.ogg` | `1099` | 2.38 | -17.3 | -1.7 | Pencil snapped. I've got another. | `2c360a8dd98371544b96ccbf6ecc4f2742c0d664073fc63415576292073cd015` |
| `reactions/emszvz.ogg` | `1099` | 2.04 | -16.1 | -1.9 | all | `5179c06b75bc543b493eb7730372668a400037daa23c1164dd287d532ff2a23d` |
| `reactions/f902ih.ogg` | `1099` | 1.64 | -16.8 | -1.9 | all | `e4222a293f0f7813e56232a8486876d06b01e087b9fb23f155f722a751121947` |
| `reactions/fig6cg.ogg` | `1099` | 0.58 | -16.3 | -2.2 | all | `00d76a222fd109bda49311401c6035ba2b8939ad41546e66235815eb80226e52` |
| `reactions/fmm4mj.ogg` | `1099` | 1.86 | -16.0 | -2.2 | all | `78fec1492f6942ff47659a0fbe53862c3d9e491afda546dd50be2322cd438f21` |
| `reactions/fmzhqp.ogg` | `1100` | 2.8 | -16.0 | -2.3 | all | `af97958584f6439f979e83298e2a1c85729ec15e518491472d8fb661370db90b` |
| `reactions/fxckgg.ogg` | `1099` | 1.34 | -18.4 | -1.8 | all | `af7b1c247fbe2409dd9e673b75675c7525094bd69dce0ec48cc465e0d73b64d9` |
| `reactions/gf32w7.ogg` | `1099` | 1.27 | -18.7 | -1.6 | Lovely, fits a trade. | `fd4b3912b717d268f49a4129779aa8ae596344285a1440235d45765f89e04cf4` |
| `reactions/grecwf.ogg` | `1099` | 4.5 | -16.2 | -1.7 | all | `8557391fde5595c50233d6774544d27c4542d14ba0ed414b9d161e9b9cbacd45` |
| `reactions/gun14r.ogg` | `1099` | 4.1 | -16.4 | -1.7 | all | `3bf56b3873d41b872f93bfedb492f5e5a114ec8ec7e0e84ab3025ec4fb11d090` |
| `reactions/gxljs1.ogg` | `1100` | 1.93 | -15.9 | -2.8 | all | `d75277ae60351d8fccaf8cb6b8f216a75cf535b252873d4a73d2ccb9abf24390` |
| `reactions/h6pw3p.ogg` | `1099` | 1.09 | -16.9 | -2.1 | all | `8cd9a39752a52acf9705483655c33ad99de42852917630e8f3798fc9b2f8dd74` |
| `reactions/h8p9gu.ogg` | `1099` | 3.02 | -16.2 | -1.5 | all | `ad4c845235510f50207a45626b83d209634b5c535af8719167cbed489b63b247` |
| `reactions/h9at64.ogg` | `1099` | 1.93 | -16.2 | -1.8 | all | `4da98febf073c714d5b4780c569af8927c6a88ddb6ad3a154948fc5809410387` |
| `reactions/hnpdxz.ogg` | `1099` | 4.2 | -16.5 | -1.5 | Whoops, there goes a washer. Straight into the chilli bin. That one. | `247f3d1104590b88f8772125b18bfd4dac7ffba0498b5bea75f24b88b20e108c` |
| `reactions/ho0c5v.ogg` | `1099` | 1.52 | -18.1 | -1.8 | all | `0eca88d9f120134ab3ad0253c4eea3f5e30ad6d1ed7542b04bd6b523e0214930` |
| `reactions/ie6sd2.ogg` | `1099` | 1.5 | -16.5 | -1.9 | all | `35c598c24bc1af9d088a0b2ca4882825d4205993899471964b21a10cc0c8793e` |
| `reactions/isd89o.ogg` | `1099` | 4.4 | -16.3 | -1.8 | all | `1e7ce08c07a362ea9cb17cb54bf505efe50dbcb92ab5560dfc75cf076be488e5` |
| `reactions/j4rn9g.ogg` | `1099` | 1.37 | -16.0 | -2.4 | Inks dry on that one. | `def9449d5d5c1520694c9c101f7924a8e3477038cc936992d18ec59cdf73363b` |
| `reactions/j62ugc.ogg` | `1099` | 3.85 | -16.7 | -1.7 | all | `de6fcf2a9e1a1181e425e8812eb1b7044c8d9130733ce641e6b1f5dada3e9ac3` |
| `reactions/jf7rbt.ogg` | `1100` | 4.8 | -16.0 | -1.9 | all | `19203018b0d02297a2a888c1387fc9b693615c7199ff20c47ef654b299d30d8a` |
| `reactions/jfdiih.ogg` | `1099` | 1.43 | -17.7 | -1.8 | all | `f480198046276e390b0501fec7a0efce373a9b7a39b752a7542734f68317436b` |
| `reactions/jmscyv.ogg` | `1099` | 2.68 | -16.1 | -1.9 | all | `ba796d6c6d7a0002cc5dcabcfc468f814b9c53a7c25c50e8395a7efe7254be1f` |
| `reactions/ju6blx.ogg` | `1099` | 0.68 | -17.9 | -2.0 | all | `7f5fc326a886194095eac5b326a10cd5e9724c8413ca74547569c64e0d945023` |
| `reactions/ko5bd3.ogg` | `1099` | 1.85 | -17.0 | -1.9 | all | `ff6b7b18e8420adeb600b7c911a71355fdc0df4aafd6d1d4bacf9b446e236a71` |
| `reactions/kvkgjo.ogg` | `1099` | 2.09 | -16.1 | -1.8 | all | `3f22620fd8eb0613a03bb66e3e8fe0469b38b5fcb73a6610033ff07c0d35c359` |
| `reactions/l4qesy.ogg` | `1100` | 0.9 | -17.0 | -1.9 | Site taken. | `8b0ab2fa11f6853e0dc374ff796bea6d2af95b658edf25e94cdc2fe9034ad0e1` |
| `reactions/l9ncs3.ogg` | `1099` | 1.02 | -18.1 | -1.9 | all | `89ce87209461f68bad4f915aef4ce3d8b6ad39477be8b12045d1c445cd779c21` |
| `reactions/ldaaey.ogg` | `1099` | 2.32 | -16.0 | -1.9 | page torn, tapes in the drawer. | `b192951455d0ee7965291227a0c49e97dfc983fc1163e725504322d3bb145986` |
| `reactions/ledk03.ogg` | `1099` | 3.4 | -15.8 | -1.8 | all | `5d6e70e1a6f74cb9c8f2eb32daf6282168c4993fa6d1ee66db1ea8e922d51de4` |
| `reactions/lhnthf.ogg` | `1099` | 1.53 | -16.1 | -1.6 | all | `bc116d1f510e2d28a096c7b8392ba08c14a2d274b7eada5111a55631af11cd48` |
| `reactions/lpemtf.ogg` | `1099` | 4.6 | -16.1 | -1.8 | all | `0e301d988dedf15e316903ef84555064a89bd3be20c9fdb2e3f5540a4a52b636` |
| `reactions/ltidxg.ogg` | `1101` | 4.0 | -16.2 | -1.7 | Bolt stripped, another one for my tin, and the tin's nearly full. | `67fdbebe05e02f8f0bce4549293d8fd44bdc26c4e7ea6236092bbb8b073cdcee` |
| `reactions/m8lddf.ogg` | `1100` | 0.78 | -16.9 | -1.9 | all | `c0b778b30667279b47c2716cde4a07ae4fa71b66ca7cdd8323afc5468053c674` |
| `reactions/mc6s50.ogg` | `1099` | 2.62 | -16.0 | -2.0 | all | `09ac0318db7c262cb8b1bd7490987ac398145cbd3e79bf90f30997e0f1855fd6` |
| `reactions/mwjojt.ogg` | `1099` | 3.88 | -16.3 | -1.7 | all | `6ee979db74d07cb02f3ca15b6c0450177a2e4cb0a339d991a88a36461f500c69` |
| `reactions/nc5zhd.ogg` | `1099` | 3.63 | -16.8 | -1.6 | all | `de612cfddc6c78129ba7e61f1c8e6fff80c21e4435101a24a2cf6689c47525f3` |
| `reactions/ne39vm.ogg` | `1099` | 3.18 | -15.8 | -1.9 | Glare of the salt, nobody could read that. | `e92891f9c7a1cf28662172a7780c3a51f1e3430edcd6a813a713dae5f1fc3803` |
| `reactions/nm0fuf.ogg` | `1099` | 1.43 | -16.6 | -1.7 | all | `167b402c18338a956f6321e520818cc2701223cf01f6368fe328546846d7ddc0` |
| `reactions/o7hg9n.ogg` | `1099` | 3.43 | -16.2 | -1.7 | all | `53041998f3f224223cb3a53d332f25fb8e6fff0ad3d848bae821f73f59051faf` |
| `reactions/obn01d.ogg` | `1099` | 1.43 | -16.5 | -1.8 | all | `c3d937a1cf1e199652094c590489c7832d72df754c1ea5ac951ce567a5072673` |
| `reactions/oc853p.ogg` | `1099` | 4.2 | -16.0 | -1.8 | all | `f138167734fc89460200b6a68aa83b7a179646dbbe5335df11cb112953d0f88a` |
| `reactions/ondobk.ogg` | `1099` | 1.77 | -16.0 | -2.5 | all | `05a80255f32472fcb2c3eaacae148db82099e0077b3e64b043fe80c4f99673e4` |
| `reactions/osys6q.ogg` | `1099` | 4.4 | -16.4 | -1.8 | all | `c905b4dd599505dfbc6dba1405f8170ae9ca0717ea9e3547647b982a1982098a` |
| `reactions/pga4ks.ogg` | `1099` | 2.79 | -16.4 | -1.7 | all | `6d1415f0ad11555881640ff56b6f3554f0234ff50555283a85259c9fe097ff06` |
| `reactions/ppg08k.ogg` | `1099` | 1.32 | -16.0 | -2.1 | Quelle dommage! | `afa261fed7d247ba2907077aee83b60b72947603853b9ea0f5285d505c06713b` |
| `reactions/pv0yzw.ogg` | `1099` | 2.14 | -16.9 | -1.7 | all | `a265fd6a142ff89eb12eaa39f984879df4c7055cca0db4b1ef20195063deb651` |
| `reactions/py9ozl.ogg` | `1099` | 5.3 | -16.5 | -1.8 | all | `461732a5d386f3d8015ac4152f29cdeafc3e369055ca37ea93ccb0f0aee9d9cf` |
| `reactions/pz2yqj.ogg` | `1099` | 3.41 | -16.5 | -1.6 | all | `a6c2aade80012988a794fe95a732fa19af2a473c084b52b35b270f77ab391d13` |
| `reactions/qtf09l.ogg` | `1099` | 4.2 | -15.6 | -1.8 | all | `b95f3ea1497e7db4ae2bbf678c523a8c9f051c72991b50da3ba3a2f0e3aff7e2` |
| `reactions/r74c14.ogg` | `1099` | 4.3 | -17.2 | -1.7 | all | `750e2e335bc0ec8904a4814fd92ceb94a3628ce8575665bd86d5a2f0c4344fea` |
| `reactions/rd7iv6.ogg` | `1099` | 4.2 | -16.1 | -1.8 | all | `af6b52bafe3ebaa1e4779fcd7397c910d12d63a665faecf3e46d05dc14906e2a` |
| `reactions/rg2dql.ogg` | `1099` | 3.8 | -16.7 | -1.8 | Till's jammed again. Nobody's getting changed today. | `c224778520753534052f6d8bf7d32a8d75de7d40760c3196042ee2033980541e` |
| `reactions/rifq2s.ogg` | `1099` | 2.29 | -16.0 | -2.8 | all | `1c9348c95ddeef299f5e943b339b502a069dcf34279dee633a605cefad9849f3` |
| `reactions/rpvnvj.ogg` | `1099` | 4.5 | -15.7 | -2.0 | all | `b246138766c97c638f3deca5005d745d91f3ae89833e46bd7096559e8598ee32` |
| `reactions/rvmc9s.ogg` | `1099` | 3.48 | -16.7 | -1.5 | all | `63f1533d5e49f3d6bbebdc71527b2d6c70a254b1792dcf2fe0cbc73df2b79204` |
| `reactions/scetji.ogg` | `1099` | 1.13 | -16.1 | -2.1 | all | `4de5cc7c9cac88be9235f65ea3eba964410eb4da8aca3f016e4adf3e051934e2` |
| `reactions/sgkkrx.ogg` | `1099` | 3.7 | -16.4 | -1.9 | all | `2e7b4fc6c53eb9590afe375f454ce523570dd81bf7496b7692888adbf57914cd` |
| `reactions/sqx1py.ogg` | `1099` | 6.1 | -16.9 | -1.7 | all | `e3bf36d24b3ec9dad748356855026803f50fe22bc2047d9cbc02560c3b02b361` |
| `reactions/ssokhc.ogg` | `1099` | 6.3 | -16.4 | -1.8 | all | `8ead43d29a87fb560210526abf06212fed46bf0692475e54cf03cbe262a529ff` |
| `reactions/sy45uo.ogg` | `1099` | 4.5 | -16.8 | -1.8 | all | `f8aea0e1ed89c9c16e6c6de1369947b7a3211b95db5d11a13d7d81a33741706b` |
| `reactions/szq8sb.ogg` | `1099` | 1.45 | -15.9 | -2.6 | all | `11307c9f80e21456b8742e1d97cb907ecffe7341342ef52358bb4f57997ec6a1` |
| `reactions/td1cfs.ogg` | `1099` | 1.38 | -19.8 | -1.9 | all | `e31db6e238c021b3d99a5491c228cdf58ae44a8be7822db09c0d57453175ea91` |
| `reactions/tdbhq1.ogg` | `1099` | 1.71 | -17.1 | -1.9 | Yeah, that's true. | `bde65e45e92c326c1f482605c10ef7afcaca65b829869db803299152f105d831` |
| `reactions/tgp5x1.ogg` | `1099` | 2.53 | -16.0 | -2.2 | Backup batteries kicked in. That's what it's for. | `0f04d845db1a35b2a4a285be75a13984a7613e6774723961c1359943530cdc64` |
| `reactions/tn7w1y.ogg` | `1099` | 5.6 | -16.0 | -1.7 | all | `04347edc554e25ec98fef365580814d07894c75986a911c516714def81ee1add` |
| `reactions/uqqnkj.ogg` | `1099` | 3.22 | -16.0 | -1.9 | all | `27c5aa1b85e134c8db363077aa18b30970e429cbc3125a8c39e7107c1c9df1fc` |
| `reactions/v10xxr.ogg` | `1099` | 2.45 | -16.5 | -1.7 | all | `996155167325bd475e2c2ce0543263ac15878df9c682969ed8d76d42298e2b10` |
| `reactions/v9wcyf.ogg` | `1099` | 1.43 | -17.4 | -1.8 | all | `5a2654c416e6ef2f5df87dfa71b8c62cf21c2ac40a10c3f65c6a91ec382601f4` |
| `reactions/vbbab9.ogg` | `1100` | 0.98 | -17.3 | -1.8 | that hold. | `fc618a16a9fb80b352632127fe2f6213dc9ec3ef109b3f6bbb8017f21be6f127` |
| `reactions/velmbv.ogg` | `1099` | 3.62 | -16.0 | -1.8 | all | `ae5cd8425588ecabc6725d3f4f8c81e610555db08a1fb0361c44a65fec69752e` |
| `reactions/vgsdvc.ogg` | `1099` | 3.14 | -16.0 | -1.8 | all | `294e7961d90c695fd37ac60906560dfd1da663e1b906124f924e5875761a3605` |
| `reactions/vnxj2u.ogg` | `1099` | 4.1 | -16.7 | -1.8 | all | `b21ac447d7ee0c10863398a2d326c3a8b19f6a4035fedcd321510628565d4570` |
| `reactions/vqzs24.ogg` | `1099` | 1.49 | -17.6 | -1.8 | all | `79a80e4e6de075c410c17b5becaa0217c85a3648c5d331ddc7e1d1dd7e1a4225` |
| `reactions/vvw7h6.ogg` | `1099` | 0.78 | -15.9 | -2.1 | all | `91b8cc877ac9bb2cecaceb1a8322b16f25b1789dbda2fc830eb57b3a149a4a98` |
| `reactions/wyhvd5.ogg` | `1099` | 2.31 | -16.5 | -1.7 | No, no. The cards have blown away. | `49f162bff7c068a2f357dd370ed2672a50bec57914fd72bfa36ebdefcd60e254` |
| `reactions/xakm9f.ogg` | `1099` | 3.15 | -16.5 | -1.8 | all | `d85de017e91e11cec3b302d61e51b47a801eac691e542a8047332daf6a89eb28` |
| `reactions/xbdeh7.ogg` | `1099` | 1.51 | -16.0 | -2.4 | all | `3515984d3f56dd9f6df9d6a122f22310356dd5b720123016e149356044434379` |
| `reactions/xle2z6.ogg` | `1101` | 2.72 | -16.0 | -2.0 | Ehem, that holds. | `09bd21ac03afeb5dbdc785aab77efe9dca15781085fc8ed50f3e595e0214698c` |
| `reactions/y7w6mr.ogg` | `1099` | 2.39 | -17.9 | -1.6 | The house takes this little one. | `b66fcbecfdf9a9079cd551bac0ee06dd44beecd540db7cb8f2f839da22ac088c` |
| `reactions/y97n4o.ogg` | `1099` | 1.84 | -17.1 | -1.8 | So, it lands! | `92d3a070968214b44c53302d00690020cbce0e11687785efef4880d9c74ccd2e` |
| `reactions/y9j4po.ogg` | `1099` | 0.96 | -16.0 | -1.9 | all | `e9b6cd8f039a9e76ca9139597eb0747b4165ed7b409ebf9a5c730390948918f4` |
| `reactions/y9pzq7.ogg` | `1099` | 0.94 | -16.8 | -1.9 | all | `6039915f634786c416b0b1cfe7d239ded2a1f9e32febf90047d94ab198c8047d` |
| `reactions/ys1qap.ogg` | `1099` | 1.42 | -16.3 | -1.8 | all | `a349e94639d0a2ef3323980935cf4a94a8c7388290b3f7186ddb97c12597bcde` |
| `reactions/yvoj2m.ogg` | `1099` | 2.07 | -16.7 | -2.3 | all | `93852e0c98591e97513cad792f858f83f12c0e4ee84259a14b2214554680bce8` |
| `reactions/yzqelc.ogg` | `1099` | 1.48 | -16.4 | -1.8 | all | `416f8b38e9684d8ecde7396695875102bda65e003d92eda09b206c656c4b4007` |
| `reactions/z7tgh4.ogg` | `1099` | 1.44 | -17.4 | -1.9 | all | `1786e92300bc8d05ddaac5b66e2b28d3ac006a7a386ac1f34651fae84ba2d718` |
| `reactions/zgtwm1.ogg` | `1100` | 3.28 | -15.7 | -1.9 | all | `875da02edd6dd9d631f2050cec7e44133fc2df79001d15bfce594b7f238f2397` |
| `reactions/zp973u.ogg` | `1100` | 2.14 | -18.0 | -1.9 | all | `2eae6949a78bb66d087d022ee8a12da101ec1a9587ce23ee3ebfe699936e0552` |
| `reactions/zu63vw.ogg` | `1099` | 1.12 | -15.9 | -2.6 | all | `c3376b61f87c58d81e12a44ca804dd7ac0e3e9345f4f9cc3d49a35c72ab42c53` |
| `reactions/zx6usd.ogg` | `1099` | 2.45 | -16.0 | -2.1 | all | `3fa30fcbea6e36ebd555624d2a83e7b3df95b7baa08879172d172869a1619946` |
