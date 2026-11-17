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

## FAL-992 — Spark's explainer move lines (voice, locked Gemini voice)

162 voice files: two takes of every move line in `curriculum/moves.json` (81 moves), re-recorded in Spark's voice as locked on 2026-11-15 (FAL-927). They replace the VoxCPM2 takes recorded on 2026-10-30 for FAL-428, under the same file names; that entry is in this file's git history. The words are each move's `say` text exactly, as confirmed by FAL-991, because the explainer captions show them.

Generated with Gemini text-to-speech (`gemini-3.8-flash-tts`, voice `leda`) via the Gemini API, recorded 2026-11-16 and 2026-11-17 on the paid key with the falcon-voice ledger on. One request per take, so each take is its own performance. Only the scripted lines were sent; no recording of any real person went in, and the direction does not imitate anyone.

- **Direction (word for word from Spark's entry in `tools/explainer-clips/teachers.json`):** "A small robot companion with a bright, light, youthful voice, gender-neutral, quick pace with short sudden pauses, crisp clear consonants, dry amused tone with real warmth underneath, a little mischievous, lively but never shouting. Quick on the jokes, slower and clearer on every maths word. Fond, never mocking. A natural conversational pace, a touch unhurried, with a short natural beat at each comma and full stop."
- **Text sent** is the `say` line, unchanged for every move (including `factorise`, sent with the British spelling).
- **Processing, every file:** edge-silence trim below −50 dB, then a 30 ms lead-in and 60 ms tail (sox); `fx/spark-sheen.sh` (Spark's approved effect: 2% slowdown, +3 semitones with formants shifted, 15% vocoder, 200–7500 Hz band); `master.sh` (−16 LUFS through a true-peak limit, mono 44.1 kHz OGG Vorbis).
- **Added for 15 peaky takes** (marked below): where `master.sh` left a take below −17 LUFS because its true-peak limit capped the gain, a peak limiter ran on the sheen output before `master.sh` ran again (ffmpeg `alimiter`, 4× oversampled, 5 ms attack, 50 ms release, limit set from the take's measured loudness). This is on top of the `processing` recorded in `teachers.json`.
- **Checks:** every take transcribed with faster-whisper small (CPU) and compared word by word. Takes that matched only on a homophone or spelling (weight/wait, whole/hole, by/buy, factorise/factorize, calculator's/calculator, right-angled/right angle, surd) were confirmed by a second pass with the maths vocabulary in the prompt. Five takes were re-recorded after a real miss (`evaluate_1`, `test-point_1`, `perpendicular-gradient_1`, and `introduce-letter_1` twice).
- **Measured on the shipped files (ffmpeg `ebur128`, matching what `master.sh` printed):** -16.6 to -15.5 LUFS-I, -3.1 to -1.3 dBTP, 1.94 to 5.76 s long. The first and last 20 ms of every file are at least 37 dB below its loudest 50 ms.

| File (`game/assets/audio/voice/spark/moves/`) | Recorded | Limiter | Seconds | LUFS-I | dBTP | SHA-256 |
|---|---|---|---|---|---|---|
| `add-probabilities_1.ogg` | 2026-11-17 |  | 3.10 | -16.2 | -1.7 | `64a63fa8955c0fe8df3c0e2fb5ced6cf85a5799cc3369bc68cf76ea89255f46d` |
| `add-probabilities_2.ogg` | 2026-11-17 |  | 3.21 | -16.1 | -1.9 | `cee36441e0885ccf5ea2e73e5326a79b3246b7a74bfa6e5ff94cc759489ffb3e` |
| `angle-sum_1.ogg` | 2026-11-17 |  | 4.51 | -16.1 | -1.8 | `8220307f6afd8f2103ea3bd0391ce97322225e893a2c4b1b65d0776637432589` |
| `angle-sum_2.ogg` | 2026-11-17 |  | 4.61 | -16.0 | -1.7 | `c41bf9585dd20c83a82094e299023cfef7ed92ebee214ddfcf4e57867fd7e58d` |
| `apply-condition_1.ogg` | 2026-11-16 |  | 3.33 | -16.0 | -1.7 | `6c8028657d568d25a5ccdfdb51d0fbdcf919073243a6080e7e5bed5958e441cd` |
| `apply-condition_2.ogg` | 2026-11-16 |  | 3.33 | -16.2 | -1.7 | `637f0196f0ad80ff672f5cc9467e8fe1bd670a10579a7f5c5ddf9eb1124fcc20` |
| `apply-inverse_1.ogg` | 2026-11-16 |  | 4.55 | -16.2 | -1.7 | `4afa870967a90b7706a6da1ba6a17d941b77ef8d2ff45f6d7bccc52c70f88c57` |
| `apply-inverse_2.ogg` | 2026-11-16 |  | 4.35 | -16.1 | -1.6 | `76e762b72feb856f9d339761c502b78a0d91326f56b73927699514f090ae85ab` |
| `ask-what-power_1.ogg` | 2026-11-16 |  | 3.50 | -16.1 | -1.8 | `ac611eb2d472c9e9f7a17a844333e72eb2f555a2360c1c24c2e6619cd0bb79c8` |
| `ask-what-power_2.ogg` | 2026-11-16 |  | 3.24 | -16.3 | -1.7 | `3f81639840aa50e26b6caccb64c6a07d32728ba06fdf8255565cdaa9df2d7712` |
| `change-of-base_1.ogg` | 2026-11-16 |  | 3.17 | -16.1 | -1.8 | `19abfb7603d46ee56e1f898bef3dfb82c4880822f4b5cf6b747e7b9c2c5e05dc` |
| `change-of-base_2.ogg` | 2026-11-16 |  | 3.15 | -16.0 | -1.8 | `8779862148f8e57e6edc8bc67b9a7bd4b608d308384745aa7ec298977b4d07ff` |
| `check_1.ogg` | 2026-11-16 | yes | 2.04 | -16.3 | -1.7 | `a1395f528fb122160e6c995238a8a8b308a549f31c3006f35b9e0d7286a487c4` |
| `check_2.ogg` | 2026-11-16 | yes | 2.34 | -16.0 | -2.5 | `2e190db2518436a28d7e7f09f53948ede9fb366bfea03994a07bc4de9ad8f51d` |
| `choose-rule_1.ogg` | 2026-11-16 |  | 3.83 | -16.1 | -1.8 | `4be793afd41b77f5e48e1abdf6881e2ce16501765f5f5700702cbfd59dea1f9f` |
| `choose-rule_2.ogg` | 2026-11-16 |  | 3.87 | -16.2 | -1.5 | `b4602467b5348de24762f395f11f12c7a56b5c341b65c8a9e68e3380ae95563a` |
| `classify-turning-point_1.ogg` | 2026-11-17 |  | 3.67 | -15.8 | -1.7 | `ffe0e5586342fade5fe5e4c1db75ef133dfb7d77445b5257e785a0a88a005c46` |
| `classify-turning-point_2.ogg` | 2026-11-17 |  | 3.75 | -15.5 | -1.9 | `2f6de228fc43fcb235b43a9b1b421d8160f1a5b021c3eddfed87fa2659393973` |
| `clear-fractions_1.ogg` | 2026-11-16 |  | 3.67 | -16.0 | -2.0 | `e1de275c9d1b2558911ff7fa4daec9364b4a5689bd8f7e903c78d83b3eacd008` |
| `clear-fractions_2.ogg` | 2026-11-16 |  | 3.75 | -16.2 | -1.8 | `6d238cbb536deddacc5a6cc0849da2dc354bf8fac85cb6d1b9a99675bf52dd05` |
| `compare-coefficients_1.ogg` | 2026-11-16 |  | 4.99 | -15.9 | -1.8 | `484db73b9834ce49fa2558774442772d64396f0c180de6982798742f3d5430c2` |
| `compare-coefficients_2.ogg` | 2026-11-16 |  | 4.61 | -16.1 | -1.7 | `f3533043580885d7bbef9f24f289be420761f2ef7637bfb22426965c95cf1738` |
| `compare-neighbours_1.ogg` | 2026-11-17 |  | 4.65 | -16.0 | -1.8 | `85a25a23c686e16f6021f9bf45da9f15c00a1fbd4239e1897b602d5e2c904ecf` |
| `compare-neighbours_2.ogg` | 2026-11-17 |  | 4.64 | -16.1 | -1.8 | `603eb8f4e6348c54968932a7b0ace186b64ce15444998b9cf2ec2bb9612e43ee` |
| `complete-square_1.ogg` | 2026-11-16 | yes | 2.92 | -16.0 | -2.1 | `4eff23c8ae2ab3a674942fc20219cf2340f2009a3ed0ea74a5bb9c4381e1502d` |
| `complete-square_2.ogg` | 2026-11-16 | yes | 2.85 | -16.0 | -2.5 | `36ce992d4fc00c8603c87e6a7f324d9a8af6d2f9eed9435525084478f7ec6022` |
| `compose_1.ogg` | 2026-11-16 |  | 4.06 | -16.0 | -1.9 | `306bffffdd4baffd67c92a65ece89bcfa9b30feed23989b744b6682c3fc6e35e` |
| `compose_2.ogg` | 2026-11-16 |  | 3.50 | -16.0 | -1.9 | `a5be14f441f08b151640b73ddd04c5e1ad30073cbc097b0a7e564c93843afc83` |
| `compute-discriminant_1.ogg` | 2026-11-16 |  | 4.74 | -16.1 | -1.7 | `29e261dbfc7b5210c9a3d167aa06131b7d8c869b71bee0b6fae96382b28219db` |
| `compute-discriminant_2.ogg` | 2026-11-16 |  | 4.46 | -16.2 | -1.7 | `8a4b4263ead3149eb266432b2dfba6008b21352db47da3f6f583811c9b6411c5` |
| `convert-log-exp_1.ogg` | 2026-11-16 |  | 5.07 | -16.2 | -1.9 | `fc808958fd2166ed2c6fa7050cb4d160332d7785f5a563b22950d3d7a35beb97` |
| `convert-log-exp_2.ogg` | 2026-11-16 |  | 4.76 | -16.1 | -1.8 | `7747141c23e45ab231877556af40c3a3132fab58b37909dcfc03884e0550056b` |
| `count-steps_1.ogg` | 2026-11-17 |  | 4.15 | -16.1 | -1.6 | `53dfb24e0055e19e8a921f1e0a54f63e4c01e91c6f1a92648b6cac92686411a8` |
| `count-steps_2.ogg` | 2026-11-17 |  | 4.50 | -16.0 | -2.0 | `cf220425d19b6333a2d2997e8939988a0c993e171f4d436b912f680809490fc3` |
| `definite-integral_1.ogg` | 2026-11-17 |  | 4.87 | -16.2 | -1.6 | `c8ac3a2d437ab16a0f86e8503a3519aa29c98a55f936114743fe954f137afe1d` |
| `definite-integral_2.ogg` | 2026-11-17 |  | 5.30 | -16.4 | -1.7 | `9a038e2cfc3bea8dca50a80a87b71683630617fb6a73930908ae39a1d6f4db15` |
| `describe-transformation_1.ogg` | 2026-11-17 |  | 4.04 | -16.0 | -2.0 | `828405019f9aae8afc6e83d2f6b5dc3ebd745b93cfaf9dee922cb97eb70aec7d` |
| `describe-transformation_2.ogg` | 2026-11-17 |  | 4.23 | -15.9 | -2.3 | `c739eaadc7d7d429d36aa9cc2fdf45247936decf4e579f285ba4382efc3ff161` |
| `differentiate_1.ogg` | 2026-11-17 |  | 3.30 | -16.1 | -1.8 | `5c1e394692c1ecc3bb0db19f592cef162d02c6e26e93538289452af87a30220a` |
| `differentiate_2.ogg` | 2026-11-17 |  | 3.19 | -16.3 | -1.8 | `9a9ec02a05fe931b547568e3d4d9c2e8fc73b4744104729827cf53ee7ef192a4` |
| `draw-construction_1.ogg` | 2026-11-16 |  | 3.32 | -16.2 | -1.8 | `273b5dc2f08d9119991b965da1fca857ae351d58706fb532a62e5dc278091be3` |
| `draw-construction_2.ogg` | 2026-11-16 | yes | 2.97 | -16.0 | -2.4 | `ab3e80f316a9416be24dfa700f611832072cf488d5e06b84dad75052fcca7c52` |
| `eliminate_1.ogg` | 2026-11-16 |  | 3.16 | -16.0 | -2.0 | `4462e1d9176a9c4a58511e9923c4d98ab616f776e988eac4798a1bfd1f31dd04` |
| `eliminate_2.ogg` | 2026-11-16 |  | 3.44 | -16.3 | -2.0 | `c617fc6b579c832e40f7f465a5ce4770169517d445d07a4f7629f7131524b974` |
| `end-behaviour_1.ogg` | 2026-11-16 |  | 4.93 | -16.3 | -1.6 | `91a858652885b4076017cb233be6024b35819f36b28b0e1bc63a8968827b4741` |
| `end-behaviour_2.ogg` | 2026-11-16 |  | 4.58 | -16.0 | -1.8 | `76b37f7e852d5177de75e8cadc81e8d381613949858c3b211a35e87f7a33dfb3` |
| `equate_1.ogg` | 2026-11-16 |  | 3.64 | -16.2 | -1.8 | `3ab88b84f3d5c7bd2f819ebb68a686a31171e8d9495c29ad49c32921d1bc5245` |
| `equate_2.ogg` | 2026-11-16 |  | 3.30 | -16.2 | -1.8 | `e0fdfcfff50a1a3b08d3ca3810a4be401bdc6fbf395ef93d9cce7b2ea8cc38ec` |
| `evaluate_1.ogg` | 2026-11-17 | yes | 2.05 | -16.0 | -2.8 | `53371923a3c1c8e03a8fc7cef2e60d832206933157e9162b2ef0c05361354b05` |
| `evaluate_2.ogg` | 2026-11-16 | yes | 1.94 | -16.0 | -2.2 | `b807b6b8616d286a93723e13e2d6fdd9df282472278bea04975bdb578c3a3e56` |
| `exact-value_1.ogg` | 2026-11-17 |  | 3.82 | -16.2 | -1.8 | `d5851c03bf9a50faf8bff59cdff700d4fea4afd606699a941c6b585625cb9f0c` |
| `exact-value_2.ogg` | 2026-11-17 |  | 4.33 | -16.1 | -1.7 | `1601c7738e95336eae8dcc18d5a9485519e84c281b23dab9743d063c9b2f88dd` |
| `expand_1.ogg` | 2026-11-16 |  | 3.94 | -16.2 | -1.9 | `b41a9e527e48879c9c2a6639b974e647f87a69b3fc63193895642100886b8a37` |
| `expand_2.ogg` | 2026-11-16 |  | 3.53 | -16.2 | -1.8 | `3349dee44c89ce765aa995eb6d49b206208b22ec4cb237331a0d631edbe0150a` |
| `expected-count_1.ogg` | 2026-11-17 |  | 4.05 | -16.0 | -2.2 | `357b739dde4f75c72cea066b769875a922c6f99e22f3e67cc3f178e37a947a31` |
| `expected-count_2.ogg` | 2026-11-17 |  | 3.80 | -16.0 | -2.0 | `70e80e6462e3a6cdb727aea7500c7f40618146c097734dbf11617c954826aa64` |
| `expected-value_1.ogg` | 2026-11-17 |  | 4.65 | -16.2 | -1.7 | `0b41059c07ef48890408fbf5ef05ad846bbb8940cef560dff3272522c4be9558` |
| `expected-value_2.ogg` | 2026-11-17 |  | 4.39 | -16.2 | -1.8 | `814dd80fa541fdab5a64c8301b0c5ec4146b4ab62280ce5e527a94daedfa0072` |
| `factorise_1.ogg` | 2026-11-16 |  | 3.95 | -16.3 | -1.8 | `fdb764401acbf36181f7851c9d461b1bb94e107b64466c8963b72b427c159836` |
| `factorise_2.ogg` | 2026-11-16 |  | 4.47 | -16.0 | -1.3 | `89096f308a51fc7d9102d07045c7888db43f3ceec8cc304310b2fb70638ec825` |
| `find-all-angles_1.ogg` | 2026-11-17 |  | 5.27 | -16.3 | -1.6 | `7c91b5e6cb45564cda6a7f415bc77c96ec749dfcd1ab904aaac4cd7f19b62d15` |
| `find-all-angles_2.ogg` | 2026-11-17 |  | 5.19 | -16.0 | -1.8 | `49790ea70ba23e690d5989c83d1a32373aa8c01b2250a3326609d2b88b21accf` |
| `find-factor-pair_1.ogg` | 2026-11-16 |  | 3.97 | -16.1 | -1.7 | `25ad3e7926e5e689e8552dfb81274ec2d68da9afb94596f75852cc7d0b1bc6ae` |
| `find-factor-pair_2.ogg` | 2026-11-16 |  | 4.12 | -16.1 | -1.8 | `fcf3b1e50a6c86ee60999fb301fb6b28c6e3d7c0e680edf3f7942414a3ffa8d9` |
| `find-gradient_1.ogg` | 2026-11-17 |  | 4.39 | -15.9 | -2.0 | `864ed65482f049e59456b1a5be9bda73aecf43a67ddbfda7af873d41f8d943b3` |
| `find-gradient_2.ogg` | 2026-11-17 |  | 4.92 | -16.1 | -1.8 | `812ab68f695e17d058cbcb718e58ce7620c768d8bb25f7e8b4efb0588c2dee58` |
| `find-midpoint_1.ogg` | 2026-11-16 | yes | 2.77 | -16.0 | -2.9 | `d4c7aa6e3ba2bae093f86df9e08b2dc096efe10441c5d5e139e9948867a5674d` |
| `find-midpoint_2.ogg` | 2026-11-16 |  | 2.83 | -15.9 | -2.7 | `2c5f975c979c12d34e1d11c0179e241bc642ede68329b6c4740bca579b3bff53` |
| `gauss-pair_1.ogg` | 2026-11-17 |  | 5.76 | -16.1 | -1.4 | `12327fdf498aee6f871cfe409963ca35c0fb3370bc37b76625f8572b01ec0775` |
| `gauss-pair_2.ogg` | 2026-11-17 |  | 5.68 | -16.2 | -1.7 | `8c69fb63e8fa25d39d30c5011de37e9bcb10a284942ef916dfd0c859af23e10e` |
| `gdc-graph_1.ogg` | 2026-11-17 |  | 4.65 | -15.9 | -1.7 | `9cb4f900c2990f27187257277fd414a134204a5a23f9623da2b669f69c8d8b0b` |
| `gdc-graph_2.ogg` | 2026-11-17 |  | 4.83 | -16.2 | -1.7 | `fee730b53186efbd0e2fcd72f2eb7b0833409d984c9728011b453964ae28d711` |
| `gdc-solver_1.ogg` | 2026-11-17 |  | 4.09 | -16.1 | -1.9 | `af26da2816c4424bef10a2ffeacb8c6f907c3b2061c4ec4445030ff06b5fe218` |
| `gdc-solver_2.ogg` | 2026-11-17 |  | 3.57 | -16.0 | -1.9 | `8cb5cb3084af51fc68f676c890ce9d4ae95295311852a1f9282af08b2cfaf43b` |
| `gdc-stats_1.ogg` | 2026-11-17 |  | 3.61 | -16.1 | -1.6 | `11319200c14934cc5fd804a9c16e3fc4496da3c4a800511ee035382d824225fc` |
| `gdc-stats_2.ogg` | 2026-11-17 |  | 3.58 | -16.2 | -1.8 | `ce1476bf7edb8c8aa86453e2770b0677210eaf99899f8eb3e8b7c572b3839f12` |
| `integrate_1.ogg` | 2026-11-17 |  | 4.27 | -16.0 | -1.8 | `bb33edb757c7e558d1f32291565d120fd21c26478b274cfacf44d4dc3f81fdd8` |
| `integrate_2.ogg` | 2026-11-17 |  | 4.06 | -15.7 | -1.6 | `001211f0dea13fe07fc4f72c1d49cd05e493e5e1d69c4e2af3e89ad228d6aca1` |
| `interpret_1.ogg` | 2026-11-17 |  | 3.11 | -16.0 | -1.9 | `6cadded4993b88713ce866aa738f532a4ca4b01450d4218ee466f5515e7efbf7` |
| `interpret_2.ogg` | 2026-11-17 |  | 3.14 | -16.6 | -1.7 | `108f8c3755146dfdb5c5068f2ed8becf61c6bb82eeb0766bab38969cbe2f81e8` |
| `introduce-letter_1.ogg` | 2026-11-17 | yes | 2.59 | -16.0 | -3.0 | `2b5a5ee23c50d620d08a87a46fc27a22c00f230facf08e39ce413d9c4f04d667` |
| `introduce-letter_2.ogg` | 2026-11-16 |  | 3.20 | -15.9 | -1.8 | `747d10cc7b47c63b186ca4efa87a65c5a79b6d3b11a18de79b68111e0882ddaf` |
| `isolate_1.ogg` | 2026-11-16 |  | 5.33 | -15.9 | -1.7 | `f245907d1e54aa796918d1a9a0f5d36fac4e9f2a7346a28720f7e3f692bf2bc7` |
| `isolate_2.ogg` | 2026-11-16 |  | 4.65 | -16.1 | -1.9 | `86b33de3d1d88210760b9a1cb1a50a51e1bbbfca028f1a8b51d41c39cb35a8ee` |
| `keep-valid-solutions_1.ogg` | 2026-11-17 |  | 4.70 | -16.4 | -1.8 | `a4683f245ecfd307d6537ec00c65ad11baf0f0b2d446ec9f58f7d2055d7902cf` |
| `keep-valid-solutions_2.ogg` | 2026-11-17 |  | 4.36 | -16.4 | -1.9 | `644c2585d2d82eff356201f700f291c6826f401b9afd823382804989a6bea991` |
| `label-diagram_1.ogg` | 2026-11-16 |  | 3.48 | -16.0 | -2.0 | `8e10808f088bc3e2664ecdbb5e9d4524ca17c975813f58a563c498509ffd29be` |
| `label-diagram_2.ogg` | 2026-11-16 |  | 2.92 | -16.3 | -1.8 | `4f54ba385cd768f3ec7d8cb3cc0c03598c494d4ffc1f32a4678381f05352f4ab` |
| `list-outcomes_1.ogg` | 2026-11-17 |  | 4.33 | -16.2 | -1.7 | `90982327e8f3e135922e48f76fc34189ebf783cfd48b1a309276509691b089b5` |
| `list-outcomes_2.ogg` | 2026-11-17 |  | 4.97 | -16.0 | -1.8 | `a9be8d0ce61313a845dd063e9b8676c302881058c78db5df1b3e86e08f9827ab` |
| `model-from-context_1.ogg` | 2026-11-16 |  | 3.25 | -16.0 | -2.1 | `b564e12fdc8eef9a4cb60876e1602fe73c7b8b84bcd05d8a4227d9493b32afd4` |
| `model-from-context_2.ogg` | 2026-11-16 |  | 3.36 | -16.0 | -1.8 | `febb60e6a79a2ff61b3c58bdfa05cd7a575ab7b69a8b17edb8abda5dbf8ab9d0` |
| `percent-multiplier_1.ogg` | 2026-11-17 |  | 4.83 | -16.3 | -1.6 | `f90ad99095f5a55418089aa39c98aa7558645b32193ef34a7a31c0dc334004b5` |
| `percent-multiplier_2.ogg` | 2026-11-17 |  | 4.54 | -15.8 | -1.4 | `17cea834c09feb0bfb314d5f56b88b5329fb93bddd65dfad6f18fea78d242254` |
| `perpendicular-gradient_1.ogg` | 2026-11-17 |  | 4.28 | -16.1 | -1.7 | `2a6c6d15d3e77ed47960f182f2623cf566edc81ce517844d93d1f6412df9a10d` |
| `perpendicular-gradient_2.ogg` | 2026-11-17 |  | 4.07 | -16.0 | -1.9 | `67d2dce02ac57d407098a70e9f50b16fc253cb245f8e39c1205d0016085c6720` |
| `pick-region_1.ogg` | 2026-11-16 |  | 5.19 | -16.0 | -1.7 | `21cb00852a7cce32ceda6dbf69ab4971b1d980466a34964d0ef1e65c3be592b5` |
| `pick-region_2.ogg` | 2026-11-16 |  | 5.17 | -16.1 | -1.7 | `6f4c427c7d8b85803aa5b570a14fbf812e52bac1b6c846e2658a8d54cdf53aee` |
| `point-gradient-line_1.ogg` | 2026-11-17 |  | 3.11 | -15.9 | -2.1 | `1efcdcc99db10185725db1906f37a29f85ce08e36a7433af9fe09e1b81ccf496` |
| `point-gradient-line_2.ogg` | 2026-11-17 |  | 3.09 | -16.3 | -1.9 | `b779185f16c8f8f33e124820734cd703577a30733615fd3049c4e039b4494867` |
| `pythagoras_1.ogg` | 2026-11-17 |  | 3.82 | -15.9 | -1.8 | `0d2a836864600ed7c25d6c0454b1501225d05d534ac550b991366e861b27e545` |
| `pythagoras_2.ogg` | 2026-11-17 |  | 4.01 | -15.9 | -1.9 | `a29d0a164577aa8b71ca55e850fa060454b885cb1c9039a32cf62dec55960a5d` |
| `quadratic-formula_1.ogg` | 2026-11-16 |  | 4.44 | -16.1 | -1.8 | `f5b1a813ece5393a866bf89b56661ca81cad299903682025b3e98da91f454cf1` |
| `quadratic-formula_2.ogg` | 2026-11-16 |  | 4.65 | -16.1 | -1.8 | `01de4ea56497d3299ef9bd2ce84a83c5f3cab5fe880496ca89e90f268d273cff` |
| `read-givens_1.ogg` | 2026-11-16 |  | 3.54 | -16.3 | -1.6 | `99dc8e290f3a046f16a6961d7dc90c30f3ba3f04ea4eec1417fc9b7d8f10026b` |
| `read-givens_2.ogg` | 2026-11-16 |  | 5.03 | -16.4 | -1.6 | `30345814f0bd17a6253d20e994999fe3831ace3bb20affc7661afc1eda1ea40f` |
| `rearrange_1.ogg` | 2026-11-16 |  | 3.90 | -16.0 | -1.9 | `3651e94ccc4aebe18b23cbfd77aada7a09b98c6d9efbbd3c3dd584240a446fcb` |
| `rearrange_2.ogg` | 2026-11-16 |  | 3.74 | -16.0 | -1.8 | `9c9a59ef6d9b2a4f5cf43f9a03c04e2b59b46ad1a35d77dda9c09d5e5f69d672` |
| `reason-from-shape_1.ogg` | 2026-11-16 |  | 3.92 | -16.1 | -1.6 | `c8adc41e5bcd0c915741fdbdcc057a76de6ee790791410fce143b9ace9f1319c` |
| `reason-from-shape_2.ogg` | 2026-11-16 |  | 3.30 | -16.2 | -1.8 | `848f1c48c053e6df7c4f7505e9864d8eb006d30a823dfe11ad37b6a93f25a948` |
| `recall-fact_1.ogg` | 2026-11-16 | yes | 2.47 | -16.0 | -2.7 | `c505f0d3976689ec457862e8b682729d0cf60b5bfa63da332c4f39e0b5839e4e` |
| `recall-fact_2.ogg` | 2026-11-16 | yes | 2.29 | -16.0 | -2.5 | `8aadc0d06920a223e8707327b853ec156a13752389d254e7cd8bb643676671b6` |
| `recall-formula_1.ogg` | 2026-11-16 |  | 4.31 | -15.8 | -1.9 | `cb9e88b4ed9bfeaa9be552c78417633d87a37e4421bb6afeaf59423e2496afff` |
| `recall-formula_2.ogg` | 2026-11-16 |  | 4.35 | -15.7 | -1.8 | `d3675ebc55852092eab6a2979d1f3f4bd35d3fe838de047e37e348ac695d165e` |
| `repeat-multiplier_1.ogg` | 2026-11-17 |  | 3.25 | -16.1 | -1.8 | `a576524ed41147306b455c826ed87bac8e0df417b655b41c0eb320f8d0b252db` |
| `repeat-multiplier_2.ogg` | 2026-11-17 | yes | 2.87 | -16.0 | -2.7 | `81140b53035c22bc6a85a5e6a726919eaf85c3f63d9e15993345b751853f94c2` |
| `reverse-operations_1.ogg` | 2026-11-16 |  | 4.52 | -15.9 | -1.7 | `a8bc01e8eaab618c8f8ef04ca7c11e276ff8287f4fbe79f7c123f4d3f66e8dca` |
| `reverse-operations_2.ogg` | 2026-11-16 |  | 4.57 | -16.0 | -1.7 | `a434d4c9fa7138cad9eba7d53c52e108a91593873b9419bccf62735d22585226` |
| `rewrite-form_1.ogg` | 2026-11-16 |  | 3.58 | -16.0 | -1.8 | `683433a7101b6a41f88912a9eb95007c3e698052e4e8c8fabf27d60d5753a477` |
| `rewrite-form_2.ogg` | 2026-11-16 |  | 3.64 | -16.0 | -1.9 | `13c7ca7656cfa5e62d6a31b4a68e5f72545541106f11879a58bb0a5116673bfa` |
| `roots-to-factors_1.ogg` | 2026-11-16 |  | 4.29 | -16.0 | -1.4 | `7db65037cf26216fd23ff511bbccb2189bf6a5fde3c787af51e1cfcf6a67ea5b` |
| `roots-to-factors_2.ogg` | 2026-11-16 |  | 3.85 | -16.3 | -1.5 | `f1ce12aff35fc7b54297cd3c2f0011b56cf61dcbca4850720544dacb727e588e` |
| `round-for-context_1.ogg` | 2026-11-17 |  | 4.42 | -16.4 | -1.8 | `4ff68769d769f588feb562e7f9b00f0e7d74f6f0efe73887c03bd6ac29184c7b` |
| `round-for-context_2.ogg` | 2026-11-17 |  | 4.22 | -16.0 | -1.8 | `762b2f422364e56c9b19c449dca8f4c59b62e0dae56e9e8fdcd4e2e5f9e0b851` |
| `sign-table_1.ogg` | 2026-11-16 |  | 3.65 | -16.0 | -1.7 | `4f8cad766322ec32c5bc1360f01341f76477aa6a0d1a13d973214f9916f2b84b` |
| `sign-table_2.ogg` | 2026-11-16 |  | 3.54 | -16.0 | -1.7 | `92e66d3afc7e0adb22036563683181ebda5dbb4767067e5da18010bef01d209c` |
| `simplify-surd_1.ogg` | 2026-11-16 |  | 4.85 | -16.0 | -1.8 | `5282b198a2a5b58b392f7aba1eaaafdcc80d9111c8e5d0a7a182976aea0a650f` |
| `simplify-surd_2.ogg` | 2026-11-16 |  | 5.06 | -16.0 | -1.7 | `580eb7777c843aa78ba7ca4918fc71111d9dcb8247cb040cb935a4410e1b280c` |
| `simplify_1.ogg` | 2026-11-16 | yes | 2.87 | -16.1 | -2.7 | `be4c7c4aec58fb18aabdd9f29d3abb100fad37f1c84cfc54c725a29518318cd7` |
| `simplify_2.ogg` | 2026-11-16 |  | 3.04 | -16.2 | -1.7 | `cfbb05fbfd58d2bcd627b3c8fa004de2de5601df2c6d9d1d02d9bfcef59ed3f0` |
| `solve-equation_1.ogg` | 2026-11-16 |  | 3.34 | -16.1 | -1.6 | `1fbfbb9bdb1187983b987e068db4eaced709ec0958d648712d3859143e9e97fc` |
| `solve-equation_2.ogg` | 2026-11-16 |  | 3.89 | -16.0 | -1.9 | `28fc756e2f217a5c2b3502791714755959a98eeab3f6021bbd1f550b3ee83886` |
| `square-root-both-sides_1.ogg` | 2026-11-16 |  | 4.46 | -16.0 | -1.8 | `3ca177a7b7e4dac5ba3ad145e09a63d4735342c17fa7895f795cfbc420d1b013` |
| `square-root-both-sides_2.ogg` | 2026-11-16 |  | 4.49 | -16.2 | -1.6 | `0e5a52cfb7d50dc1ce64897c5d977809956a8bc66fdaf4bc066ed9ccfa12804a` |
| `standardise_1.ogg` | 2026-11-17 |  | 3.75 | -16.0 | -1.8 | `4b5feec69bca93c068cec9df00f5693b6d2a8c1d1db9fb31810d68bdac8d52b9` |
| `standardise_2.ogg` | 2026-11-17 |  | 3.77 | -16.0 | -1.9 | `7a27140529c125485aa921e4621d53d6509dedc3ac43196917ee7d76a9d604f9` |
| `state-answer_1.ogg` | 2026-11-17 |  | 3.50 | -16.1 | -1.8 | `eaa1b4e1f54dc452fea6c3be2155b4f3a8b79a99ee853de8a8bdffe2fd93262a` |
| `state-answer_2.ogg` | 2026-11-17 |  | 3.22 | -16.4 | -1.7 | `a802943ac9085029c819c04bce5431b5900de89e60eb104f6082987868372e32` |
| `substitute-back_1.ogg` | 2026-11-16 | yes | 2.95 | -16.0 | -2.6 | `5e41c996206ad53a3824b43ac39e8ad8b49ff9431f17c89589969cb119a26a1f` |
| `substitute-back_2.ogg` | 2026-11-16 |  | 3.07 | -16.6 | -1.8 | `866402b588991b6982551828c7811fa64b455ee885a21b94f6a8a33103d41cbb` |
| `substitute_1.ogg` | 2026-11-16 |  | 2.60 | -16.4 | -2.0 | `17fb6cdc6f578fbc013ea464159c803b03399ede8f847c41c759a41ca1272f2f` |
| `substitute_2.ogg` | 2026-11-16 | yes | 2.43 | -16.0 | -3.1 | `449b39a25fed8eb31aba6ead339ad62b272e0a89c7df1b7df56866b76d1b1fed` |
| `swap-x-and-y_1.ogg` | 2026-11-16 |  | 3.82 | -16.0 | -1.4 | `7eaf7ecf53b4867aa01c8d7f2f105ac05552df9ab1ff02ca725b9f3287818c47` |
| `swap-x-and-y_2.ogg` | 2026-11-16 |  | 3.51 | -16.3 | -1.8 | `67faf7da7f9137afbee0fd7d16891f380060f38de3744538dc0632b8ee38f69b` |
| `take-logs_1.ogg` | 2026-11-16 |  | 3.56 | -16.0 | -1.8 | `1e846a8fb8880abac22d9fa047e933021f5a50007eb87fa47181f9efc6a58d07` |
| `take-logs_2.ogg` | 2026-11-16 |  | 3.98 | -16.0 | -1.8 | `6f4ccf1c9550826c2daf5ca10c88d5ce71b031d83133ae48a40c459191e5d43a` |
| `test-point_1.ogg` | 2026-11-17 |  | 3.62 | -16.1 | -1.8 | `77615570165bf7c56f35b8616af25f3c666a6085b930b3caf82d0d198d8ae5a7` |
| `test-point_2.ogg` | 2026-11-16 |  | 3.42 | -16.0 | -1.8 | `2592b53a666acdec00a633c8a7159525d0a8b545ed224656cf8e45c4a566d273` |
| `transform-point_1.ogg` | 2026-11-16 |  | 4.30 | -15.8 | -1.8 | `de74c0483feb61ac8122c7687f013d1563e112bbd693d911023c1b0019902d65` |
| `transform-point_2.ogg` | 2026-11-17 |  | 4.30 | -16.0 | -1.7 | `700bbbd38ebb8f53b71fe64b85ddd83f5c5858b66183572777d83c941543ee57` |
| `use-complement_1.ogg` | 2026-11-17 |  | 3.86 | -16.3 | -1.6 | `3da8dcc27da1d571e1b009b44289a22e56220c61d8b133450fbbe56deb9932cd` |
| `use-complement_2.ogg` | 2026-11-17 |  | 4.07 | -16.0 | -1.7 | `664ac8672b0d566188c9217d2e0cfc787d889a706b5ea229ee0b3b38fa29ba61` |
| `use-identity_1.ogg` | 2026-11-16 |  | 4.28 | -15.9 | -1.8 | `f23a7d6ea810078d51b9a296d47d194bebbfea6363b4e5c01aeeb428cbae352e` |
| `use-identity_2.ogg` | 2026-11-16 |  | 4.40 | -15.9 | -1.8 | `05fe8c6e69eae4af1b3df173c6ec9724fe15783391b7889f5f8c9f597e4a9b1f` |
| `use-log-law_1.ogg` | 2026-11-16 |  | 4.43 | -16.0 | -1.9 | `ed506c203ef61d4efb235bb76f7793a4887119a8af04cac09dff73331acb1a04` |
| `use-log-law_2.ogg` | 2026-11-16 |  | 4.84 | -16.1 | -1.8 | `aeda01a393bdc37ecc248488ebec2b01a89ce2dfbd139686d76b4525272cbc93` |
| `use-right-triangle_1.ogg` | 2026-11-17 |  | 5.51 | -15.9 | -1.8 | `0f51dd61af4dc5f4bc5cb14a031cb32e83286e34301ea2937ccd323ae5655554` |
| `use-right-triangle_2.ogg` | 2026-11-17 |  | 5.42 | -16.1 | -1.8 | `eaf454820e057e3818b9dff8f23ac74c889c5c04fd834b0c73b9917099d849be` |
| `use-symmetry_1.ogg` | 2026-11-16 |  | 5.54 | -15.9 | -1.7 | `5dc36babcf5ba3175f47316f71eaef8583c2bf617a12ea0c1284d55492cba2a9` |
| `use-symmetry_2.ogg` | 2026-11-16 |  | 5.65 | -16.2 | -1.6 | `d564b626ea8ce3db06c36ce91902c21d1df1cc49bac57550d80eb6787b868c7a` |
| `zero-product_1.ogg` | 2026-11-16 |  | 3.72 | -16.3 | -1.7 | `bef52c13aa0812e38b59250a93a749f2ecfb438a4305e13e805bb0482d06dd00` |
| `zero-product_2.ogg` | 2026-11-16 |  | 3.52 | -16.1 | -1.8 | `854fda5590ea71507902036c5ca32b2cdda881191f184a84a22699e027e40fbd` |
