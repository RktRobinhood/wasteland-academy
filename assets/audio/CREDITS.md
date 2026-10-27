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
