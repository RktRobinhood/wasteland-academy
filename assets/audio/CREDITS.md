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

## FAL-428 — Spark's explainer move lines (voice)

162 voice files: two takes of every move line in `curriculum/moves.json` (81 moves). The words are each move's `say` text exactly, because the explainer captions show them. Generated locally with VoxCPM2 on 2026-10-30. No recordings of any real person went in: the voice was designed from a text description, then that designed take was used as the reference for every line, so all 162 sound like the same Spark.

Rights basis: VoxCPM2 (OpenBMB) code and weights are released under the [Apache License 2.0](https://github.com/OpenBMB/VoxCPM/blob/main/LICENSE), which allows commercial use; model card https://huggingface.co/openbmb/VoxCPM2, checked 2026-10-30. Package `voxcpm` 2.0.3, weights `openbmb/VoxCPM2` from the local Hugging Face cache. No library recordings and no AI input audio other than the designed reference below.

- **Voice design (reference take):** VoxCPM2 voice-design mode with the Spark control string from `writing/voice-briefs.md`: "A small robot companion with a bright, light, youthful voice, gender-neutral, quick pace with short sudden pauses, crisp clear consonants, dry amused tone with real warmth underneath, a little mischievous, lively but never shouting." Audition line 3 ("Your b squared came out negative. Squares can't do that. Minus five, squared, is twenty-five."), seed `42801`, chosen from the six-line audition at seeds 42801–42803. That reference stays in the task's scratch folder and does not ship.
- **Move lines:** VoxCPM2 cloning with that take as both `reference_wav_path` and `prompt_wav_path`, and its words as `prompt_text`; cfg 2.0, 10 inference timesteps, text normalisation off, denoiser off. Seed per file below (`torch.manual_seed`).
- **Text fed to the model** is the `say` line, except both `factorise` takes, which were fed "Factorize, and take out any common factor first." as a pronunciation hint (seeds fed "Factorise" kept stressing it like "factories"). It sounds the same; the caption stays the British spelling.
- **Checks:** every take transcribed with faster-whisper small (CPU). Takes that matched only on a homophone (sine/sign, whole/hole, weight/wait, maths/mass, root/route, surd) or a dropped possessive were confirmed by a second pass with the maths vocabulary in the prompt.
- **Changes, every file:** high-pass 70 Hz; compressor 3:1 above −24 dBFS (5 ms attack, 80 ms release); trim silence below −50 dB at both ends; 30 ms lead-in and 60 ms tail; static gain to −16 LUFS-I through an `alimiter` at −2 dBFS (two measuring passes); 10 ms fade-in and 40 ms fade-out; resample 48 → 44.1 kHz; mono OGG Vorbis q5. No speed or pitch change.
- **Measured across all 162:** −16.36 to −16.04 LUFS-I, −2.66 to −1.23 dBTP, 1.20 to 3.69 s long.

| File (`game/assets/audio/voice/spark/moves/`) | Seed | LUFS-I | dBTP | SHA-256 |
|---|---|---|---|---|
| `add-probabilities_1.ogg` | `4280691` | -16.22 | -1.77 | `80c1f602af7ac9bac7758a186d4d35758b419fe8e81d26b43cff1083fe598a75` |
| `add-probabilities_2.ogg` | `4280692` | -16.11 | -2.04 | `d63808857abdc70ec6ab8bdda83a41de41588325c06ad8a333de04e90ee5aa6c` |
| `angle-sum_1.ogg` | `4280561` | -16.24 | -1.86 | `524711ef199c055847c612133cf4442c1f3b9130af77ef821b76fc2a3770320e` |
| `angle-sum_2.ogg` | `4280562` | -16.20 | -1.70 | `19a02aa6e9f5ed64cab0f1d241ef5b2b78e8033b19022362597d56b6ffd0fb53` |
| `apply-condition_1.ogg` | `4280081` | -16.13 | -2.14 | `c2eeeb970a40a129d0c3731837ebc7f5e1ca8619027efbdae476796ad7b723c5` |
| `apply-condition_2.ogg` | `4280082` | -16.14 | -1.93 | `5b8dba3c8c13155dd9062c83e554c36b983d9edaba29585a36e0123365d83e8d` |
| `apply-inverse_1.ogg` | `4280441` | -16.11 | -1.78 | `6f071ae9c2eb95d15f9e5bf8969cb1535cdd70b906c10054b1f8fa66094a0985` |
| `apply-inverse_2.ogg` | `4280442` | -16.13 | -1.90 | `af730b33f24d1a991a6a31edbadc9b768173f22d5ef7e12c1b865973da0f0d6d` |
| `ask-what-power_1.ogg` | `4280451` | -16.10 | -1.83 | `433ade5c2e54445d6472b6774e90125db046f8b6fb07cb883ce7393bf89210b1` |
| `ask-what-power_2.ogg` | `4280452` | -16.08 | -1.76 | `387d3bd419ff1b971490cda646e6cded605cd40f37799be4ce52f0b038794fdb` |
| `change-of-base_1.ogg` | `4280431` | -16.17 | -1.64 | `54624e23701826b7c790496951d19bb8eae81018ec15f41979c7302ab1de2aa4` |
| `change-of-base_2.ogg` | `4280432` | -16.16 | -2.36 | `407c0df4e01faeee18d05e1f050490e17862bcde59597dbe86ea8bda394b7f65` |
| `check_1.ogg` | `4280141` | -16.32 | -1.82 | `0c0edb1cf8725d44473ba5ab77e1dca9803f7ea7807eb3f147b4499531a7527f` |
| `check_2.ogg` | `4280142` | -16.11 | -1.80 | `58a8990bb1de5c75311fc53d421e9f7b7502c75cc548b12fb30625f3e267cc03` |
| `choose-rule_1.ogg` | `4280071` | -16.15 | -1.50 | `5e360f0958979be5453c231587b16176474acff1f92ca20b424f54e60b8a1e66` |
| `choose-rule_2.ogg` | `4280072` | -16.29 | -1.47 | `07e086a790f6947942a20cfc48ab1b2ebd49cd2e692fc9ce5a7a759a173bf06b` |
| `classify-turning-point_1.ogg` | `4280651` | -16.05 | -2.00 | `7ec0bf4fc92aabc04628086815ca77540ef45d20e544e4e3e58c64e75ee9344a` |
| `classify-turning-point_2.ogg` | `4280652` | -16.24 | -1.91 | `25a023846f32e6ecd9640b8e1529909cdf4ca90e2c9e2b3d5739ab252ecb48ef` |
| `clear-fractions_1.ogg` | `4280271` | -16.14 | -2.05 | `aac0189e9ed65395c207db543f4aed992417921114e4917bb008781b46226382` |
| `clear-fractions_2.ogg` | `4280272` | -16.19 | -1.90 | `976b548e5d58ab901f1604bc259be0047c776a3886b7593d73708a98abab1185` |
| `compare-coefficients_1.ogg` | `4280281` | -16.26 | -1.29 | `fb757cb4c675944dd42b55b3d13fb6f570345a08a0b5c278e466057bb3e24591` |
| `compare-coefficients_2.ogg` | `4280282` | -16.22 | -1.69 | `393504a71e5d374b4109161703a9508437948293dd2480f1fef39ac73459fc2e` |
| `compare-neighbours_1.ogg` | `4280511` | -16.18 | -1.83 | `f42d39eb70821989e4099dd9c7008576f94f8e0051b9d92e31e146154f2b9c6f` |
| `compare-neighbours_2.ogg` | `4280512` | -16.11 | -1.81 | `f6f16fb542106efffc229b2266f2fcb272ce98f7ad5a15d6c12ac13f043374d7` |
| `complete-square_1.ogg` | `4280251` | -16.18 | -1.23 | `0d3c455af4ea099ef354ed5cdd6083a5611acbb8f1a84770fca10d855ee282ab` |
| `complete-square_2.ogg` | `4280252` | -16.14 | -1.79 | `e1b38353df40def0d359c6081318e1f2afc245a02d83222ad17e6128131028a6` |
| `compose_1.ogg` | `4280481` | -16.20 | -2.44 | `30902b9d067b1e23520ef4abe4f0edb24ffd0397e04e7dfc5c98b8b3b9541f84` |
| `compose_2.ogg` | `4280482` | -16.16 | -2.32 | `b3f4198b186358d6c7cb97579c6915e062aa7f9f87c852234def57cb07907a80` |
| `compute-discriminant_1.ogg` | `4280301` | -16.12 | -1.64 | `68240e6aa20e6ce49a399727b34f3a80f3f7f2f3ed745b67172a3678c6783683` |
| `compute-discriminant_2.ogg` | `4280302` | -16.15 | -1.91 | `be2d99c534aca1fb2646c7e12165f8468fc2bad6a5db854687112d2b58f22035` |
| `convert-log-exp_1.ogg` | `4280411` | -16.10 | -1.65 | `5d42e7c2d0493382ba34891deaa34c1930909711e50337bb3a1f185550c5345e` |
| `convert-log-exp_2.ogg` | `4280412` | -16.15 | -1.71 | `5884df3917d7bc0e88e445ab65fc96d57060e783c1f79d69e43a0e47e5a30313` |
| `count-steps_1.ogg` | `4280521` | -16.33 | -2.04 | `16a4ff717eac78746a3aef2d19a31824e5b1cf978c6ce4432ce04aa74a7b350a` |
| `count-steps_2.ogg` | `4280522` | -16.16 | -1.84 | `8543b543ce064452b04c3ee4fed9bd9647cc65383cb46b9191fdcbe1d789ffd9` |
| `definite-integral_1.ogg` | `4280671` | -16.14 | -1.79 | `953abebde8b4a136beb66f8f36ae98465e117e894f86927ef7bea16c94214d96` |
| `definite-integral_2.ogg` | `4280672` | -16.15 | -1.82 | `04779213e94b25cb5dd289aec74097c0f018bacb5603765c0e5d806ef31881c3` |
| `describe-transformation_1.ogg` | `4280501` | -16.15 | -1.91 | `bc4c84d564163df3ca2965416390f8fe2ef29d099f0ba25705cbfdc410ea8158` |
| `describe-transformation_2.ogg` | `4280502` | -16.25 | -1.96 | `7e2a16b78fbbf337f36098af0ae29344ee0eb6054fb96757f535ed2773a407cf` |
| `differentiate_1.ogg` | `4280641` | -16.16 | -1.75 | `8de4f0e2eacfda71624ce37473cec7db6f787fb440778d6e81298bf2cb3ad6cc` |
| `differentiate_2.ogg` | `4280642` | -16.19 | -2.07 | `b0bc4379561f37dd98eafe1ee1d01696474892b1a0157c6c0411924444b1763a` |
| `draw-construction_1.ogg` | `4280021` | -16.05 | -1.91 | `e88d41f728a5b2cc338da02b82a97429594dfe5032954089f137d88ad37d7888` |
| `draw-construction_2.ogg` | `4280022` | -16.09 | -1.99 | `09c216ed93132f7997927349a05607323008ce648fdd7aa4a720a7a0931ec7c2` |
| `eliminate_1.ogg` | `4280341` | -16.15 | -2.15 | `f074d36762bf7f50780ea2f88ac0fbe0de6b31360f0d312c76bcf44c01548778` |
| `eliminate_2.ogg` | `4280342` | -16.16 | -1.87 | `690beefc8162772037c0d07638d03b8a015bf5f2fe1fdb77c5c74d3afee27af8` |
| `end-behaviour_1.ogg` | `4280381` | -16.34 | -1.80 | `16bec4a5c779450479fd933f8f5f204892b0fa6cf95dc58ec26e5388e8c9c59c` |
| `end-behaviour_2.ogg` | `4280382` | -16.31 | -1.87 | `1fc4ac71f9b5cc9c708cf06d9d518e48ab94b75c7bf88fb0b1b5ef61083e75ec` |
| `equate_1.ogg` | `4280331` | -16.29 | -1.58 | `24c9af81ebb881cf5adaee9290e9e0062654d5762b5e22f096fcfa79f2b34bfd` |
| `equate_2.ogg` | `4280332` | -16.21 | -1.73 | `6f2d295f3dee9437629113df635293011bd2001383a231738dfb75fd348ba8af` |
| `evaluate_1.ogg` | `4280121` | -16.12 | -2.25 | `6ee4e399566802edb06516cc80c31fa4d81576865d07c91dd4e4a5696ef456a3` |
| `evaluate_2.ogg` | `4280122` | -16.08 | -1.70 | `bac4eec693db24d78ac463a82d1cd3c3e27c61e9a2ad6aa12ff593a8fc9d56a8` |
| `exact-value_1.ogg` | `4280591` | -16.14 | -1.41 | `791d89ca3da43c190d6ec885b442770e46f7305f3e6d92f9bd7d594c1397831f` |
| `exact-value_2.ogg` | `4280592` | -16.09 | -1.71 | `3de3755973fcc38adbba49385a2e5eed94f832608174f8be2618f17d3c98e27e` |
| `expand_1.ogg` | `4280201` | -16.04 | -2.02 | `82ed5edf15069faa6005300af2c964bb49514051961af5b6c137833c99db4550` |
| `expand_2.ogg` | `4280202` | -16.08 | -1.72 | `1d2b89c3e87508573c6f67cc44ee16dd452742a077f33ab5922da7670cc26368` |
| `expected-count_1.ogg` | `4280721` | -16.25 | -2.16 | `7f49c28463681bcdf2e3e6a4f5a6ad19262fe36bdb69b59b65123bbad5ae0188` |
| `expected-count_2.ogg` | `4280722` | -16.26 | -2.13 | `4c76b35db9c3fb56171dea95cc11e9ce82d66bdc27603a4942efee7214bbed45` |
| `expected-value_1.ogg` | `4280711` | -16.16 | -1.80 | `ff4086aeae2968d705f3b51805e489e21acba0fdb0a9a5b949d079a6dfd007c1` |
| `expected-value_2.ogg` | `4280712` | -16.12 | -1.80 | `b24b1b267049c837b057f1cee4de3abb671739c748e2cbd705798980c4eb3390` |
| `factorise_1.ogg` | `4280224` | -16.16 | -1.83 | `45aa7a55d7e0e99a8b4b0ce7d91cc9d9391f43e8f0f95896df343633d5f349c7` |
| `factorise_2.ogg` | `4280225` | -16.13 | -1.51 | `9e24e8663295e534ab9c5e035badceca7d3e7380d3d4822fdfa30f4ad018f681` |
| `find-all-angles_1.ogg` | `4280601` | -16.26 | -2.07 | `eb5f90b8a7711fd4f789b5ecb00970e4f8563e0887bb0c8925cfdf67ec32db48` |
| `find-all-angles_2.ogg` | `4280602` | -16.21 | -1.88 | `a3f8c4428534d981d3d684ed350ffbce00e79d2527c0edbc6326b9f83cae4596` |
| `find-factor-pair_1.ogg` | `4280221` | -16.27 | -1.73 | `472568efc4110d90e62365b51d047e1b12c2acd4c189f4fae9e3e754a6ae1f0e` |
| `find-factor-pair_2.ogg` | `4280222` | -16.19 | -1.67 | `b56fe2438b21f7ecc5d0c4a881721087233cfe5fd53eb41c42d98e91d82212be` |
| `find-gradient_1.ogg` | `4280611` | -16.12 | -2.04 | `148d603b45664f23bac2c2333b2ca41033abb7b6491eb0c11f94868d9c57cfb8` |
| `find-gradient_2.ogg` | `4280612` | -16.20 | -2.11 | `1de74edfc58d205df537c4c33c85efe224b4c414a5080e5f1368af1b43610680` |
| `find-midpoint_1.ogg` | `4280151` | -16.16 | -1.83 | `4fc55a18d8e8a24fac77d7bcbcb466d9ee44f5fad17f894b5caa449e7b00ceac` |
| `find-midpoint_2.ogg` | `4280152` | -16.10 | -1.64 | `2294aeb3dbab919d17fcfb6fffb73597915d3678d74d41db9ef01a94997ce04f` |
| `gauss-pair_1.ogg` | `4280551` | -16.23 | -1.68 | `11191b4f052bacfe55954a5c76127152c5c6f01aa0803c59feb147c3fc2dbbb9` |
| `gauss-pair_2.ogg` | `4280552` | -16.20 | -1.56 | `b768a15126b6cd74da927061d209c423e8be050edea827e5f2720026d1d3601a` |
| `gdc-graph_1.ogg` | `4280741` | -16.23 | -1.67 | `20d566ad2c246513285d854c9ad6c2e1365561704ed1194a339e5ffd3b5107c1` |
| `gdc-graph_2.ogg` | `4280742` | -16.14 | -2.06 | `09301f952f3d69e44910fb42317a76aa3b50feb247de775dec6aefce5cda83f4` |
| `gdc-solver_1.ogg` | `4280751` | -16.06 | -1.91 | `533f34972694a25ed46aa897b1798988539d0507f099f48123387d610d9d6f58` |
| `gdc-solver_2.ogg` | `4280754` | -16.10 | -2.20 | `fee043625c66e8b104af1bdd733f9ef8561c849878ab35d69b290f7011e64019` |
| `gdc-stats_1.ogg` | `4280761` | -16.13 | -1.88 | `001839ffb081a30c9f08fdf6cb22841477060c76951b77f8b1899151ca15583d` |
| `gdc-stats_2.ogg` | `4280762` | -16.31 | -1.82 | `51ac973492882b472e6e42af96ec32e44e490eb158628aada351d2186d859593` |
| `integrate_1.ogg` | `4280661` | -16.17 | -2.01 | `d304fff5c27fb4e133897ed69e975a0155b1efb8b57190d5452dc2320424052d` |
| `integrate_2.ogg` | `4280662` | -16.10 | -1.86 | `f4a10349b11decf2e4b9d96f7655e0fae273063ced16c86034d0d3216c0ee4b8` |
| `interpret_1.ogg` | `4280775` | -16.28 | -2.33 | `8b577ffc60418e84070d18abf353b66539c52481f0c598963d2885a0b75325fb` |
| `interpret_2.ogg` | `4280774` | -16.22 | -2.01 | `c3effcae193c791767cc30ba6941ecfc33d31cd8225069e3baf9bfa9f3b06849` |
| `introduce-letter_1.ogg` | `4280031` | -16.04 | -2.44 | `3973fc7de7506601c8396c4e77396621ade3358cfa5d7afdcaf047dd239d3659` |
| `introduce-letter_2.ogg` | `4280034` | -16.25 | -2.35 | `68c86c1508bbce6710abb1f5583422cbdc2b2bbea23cc4e9d46a1fc394e890aa` |
| `isolate_1.ogg` | `4280171` | -16.20 | -2.02 | `221a3cb0d6a318fb565d188affd0209f7ef34d907f0c8762bd5f4904ed81acad` |
| `isolate_2.ogg` | `4280172` | -16.18 | -2.19 | `cd6f317b225a96c7a04080ba30e1f7d92a0c85306914f61000bb308989644693` |
| `keep-valid-solutions_1.ogg` | `4280781` | -16.15 | -1.56 | `26dd9465539a7d7868824d2405a91f0a14e84116f17cfae76986d079cdaff1be` |
| `keep-valid-solutions_2.ogg` | `4280782` | -16.17 | -1.83 | `443b039c7d37141c516d60669c2b23d21f0c5847905d8fceafa96feee3f11084` |
| `label-diagram_1.ogg` | `4280011` | -16.08 | -1.88 | `1e96225074f769507a16f64749d91beae5025298fb0d88a9b03ee2c8db58f35b` |
| `label-diagram_2.ogg` | `4280012` | -16.20 | -1.59 | `8a8123ecc1ce1b04dd43419731685bf513926364d6c71719c5f22bb5779f5ac9` |
| `list-outcomes_1.ogg` | `4280683` | -16.14 | -1.93 | `00102b9b4537f969f1c76268f08b22ab319ac6adde0e43a728531dd3b43b2a40` |
| `list-outcomes_2.ogg` | `4280682` | -16.13 | -1.88 | `e1f98bc0198009256b38edb00f5fa6d9b2f54691de67a2c0741bc5ecc302c3bb` |
| `model-from-context_1.ogg` | `4280041` | -16.13 | -2.05 | `88973bc62c11fcfad919fdbabbac3409d4e4ee47c51ed3b7e1ea09a0253a7ba4` |
| `model-from-context_2.ogg` | `4280044` | -16.14 | -1.86 | `3390c904e9003b9154cf5b418ed0e5a2a3d39daeb4f9f7605446cc7ae6730d56` |
| `percent-multiplier_1.ogg` | `4280541` | -16.19 | -1.95 | `9d1bc6d1ffaf2e0b3a3311a9f67b4b89f57721c02208e129f2e9e459cd9abf60` |
| `percent-multiplier_2.ogg` | `4280542` | -16.16 | -1.74 | `16cfdb503e74a23edc68645b0d8d5f9c0f5ca0d5d2abfa4427a34d7a61b2c20c` |
| `perpendicular-gradient_1.ogg` | `4280631` | -16.15 | -1.73 | `c8efa386853275aaf9c37d0d063cc414a0eb61cc2cf7923280268c8d5a7a9e0c` |
| `perpendicular-gradient_2.ogg` | `4280632` | -16.14 | -1.73 | `f557754024182a5452c136f00b789a5472e1c4c052abbf900c0f04b97647a768` |
| `pick-region_1.ogg` | `4280361` | -16.22 | -1.79 | `1e03d5581089fe6eb5db7c70dd43a07e0703e3c6c1c5916d7ad4d69db7940dbb` |
| `pick-region_2.ogg` | `4280362` | -16.24 | -1.97 | `0e0d4b863407309bb3deb94825dba2b625809ebe145886fbe026fc9528e5b94d` |
| `point-gradient-line_1.ogg` | `4280621` | -16.21 | -1.93 | `63c1f18f569863e6e2409b309ebffa8a8dedfe95742c574b700b2df134c6a476` |
| `point-gradient-line_2.ogg` | `4280622` | -16.10 | -2.17 | `d6e76c681d930a6a25c0249d0076d359b458a42242e14706cdd8611a2074a8f0` |
| `pythagoras_1.ogg` | `4280581` | -16.13 | -1.97 | `2aa0d3a11555045989f92d402e30db7ec31bd3b455d5368889ec6b95253c0b5d` |
| `pythagoras_2.ogg` | `4280582` | -16.23 | -1.88 | `ddd4ccded7f41b0ee0fb978dcd43dc4b0af471522daf7e16a5be04f62bbff2b2` |
| `quadratic-formula_1.ogg` | `4280311` | -16.07 | -1.79 | `7d2944b6f320aa6652e101224107308e5bfc6a95435785cc63669aa059622df3` |
| `quadratic-formula_2.ogg` | `4280312` | -16.11 | -1.72 | `d71dbcdcdcf31f880eaa65e5811fb3b2fc4fa4905bfbb690eb903f73d6c3d782` |
| `read-givens_1.ogg` | `4280001` | -16.17 | -1.72 | `7e94c115436b5cfb5d20a25038ecd2bf5fc5edd608087437687cc6d052be98ee` |
| `read-givens_2.ogg` | `4280002` | -16.13 | -1.94 | `fd30c818d337721d003f0ebc26ee8223e3cc468317761f8474bcc21568bce963` |
| `rearrange_1.ogg` | `4280161` | -16.16 | -2.12 | `6a78dedd0c6dbd85465e8ddb88978e77511ab2e94cf2015821e5aafeb668048c` |
| `rearrange_2.ogg` | `4280162` | -16.22 | -2.32 | `f1e94afcc4ce3f6c18d3dbcf9418b8845c3849d9dfd147f9f1b5c64c1b81c343` |
| `reason-from-shape_1.ogg` | `4280371` | -16.36 | -1.57 | `521b238005d197ca1928cc3dc80ae4cc14d642cae2014169cd9683e41f8cb685` |
| `reason-from-shape_2.ogg` | `4280372` | -16.18 | -1.64 | `8e39f2b9205d9a47a1cec257cdab0da1f93e9d54511a27a17a5a1a5e6f87a8cc` |
| `recall-fact_1.ogg` | `4280061` | -16.13 | -1.84 | `dd39533e8d9c6148612212e987abe7843e4ba33cb2c23144402d1ae9f5f395c5` |
| `recall-fact_2.ogg` | `4280062` | -16.24 | -1.71 | `ac5244bec238c09b0bb7d33ad824cdce7b0b9552b9222e6b57035fae5ebfbc3f` |
| `recall-formula_1.ogg` | `4280051` | -16.16 | -1.85 | `4d0842b4aebf564f5be268e2a65aa5bb07b9b0d21b3bd7d814767776d71b46e2` |
| `recall-formula_2.ogg` | `4280052` | -16.10 | -1.94 | `29e5b18e31c94a3881943d6d536f9e1bf276bb6cf77d18f5d36cc38657356dcb` |
| `repeat-multiplier_1.ogg` | `4280531` | -16.30 | -2.44 | `5db3cee5a764f7800b6af93729745d285783ea1c4ca51de6d634c765156b9dbf` |
| `repeat-multiplier_2.ogg` | `4280532` | -16.22 | -2.03 | `5d8b7b22451ee33d112823168ad14b8cbf9dd5705226148315941e6f97d14452` |
| `reverse-operations_1.ogg` | `4280471` | -16.12 | -1.86 | `8ab58698c30ee3623e9503e0880d3d1bf637a0f1fe17ed9befbc75e033e9cca9` |
| `reverse-operations_2.ogg` | `4280472` | -16.09 | -1.95 | `e3b9a26aa763dea2ee684ce073e251f6ecc156f40892f1213b84a73bb5d153ff` |
| `rewrite-form_1.ogg` | `4280291` | -16.10 | -1.89 | `cb1e72e1096287588af897e503dbffe614686b4b3563407698631f1c0804e68a` |
| `rewrite-form_2.ogg` | `4280292` | -16.07 | -2.19 | `69375f205b0f8cdb16679efe017c0942672e2b6ac9408c13a26b92ed4bdd081d` |
| `roots-to-factors_1.ogg` | `4280241` | -16.26 | -1.65 | `7878c7386ca116a20a795e3bb7226766e211d5e146ff48b9f636c8f011434b6a` |
| `roots-to-factors_2.ogg` | `4280246` | -16.07 | -1.61 | `dc39786695dff573c7ab179836a6328933a85d2cfb75d2894ef42fb18a4db820` |
| `round-for-context_1.ogg` | `4280791` | -16.27 | -1.86 | `f703e1888c11b5ecc10d2ae51f61ee7b8e57b8e033d1280a475bf5621cb98c2f` |
| `round-for-context_2.ogg` | `4280792` | -16.15 | -1.79 | `92f9cd7ebc2b9f6dc41ae1ce471b9f3c21ca7eba00441684da7cd5f642bcc154` |
| `sign-table_1.ogg` | `4280351` | -16.29 | -1.87 | `1c3da66d25d575153f7fe0100af148e559100a11b797b9b6fa885a93da40a164` |
| `sign-table_2.ogg` | `4280352` | -16.17 | -1.76 | `0af6984c314f65cd053d900796d259bc3853c6a1d5a190f98bbb2fd555e02e57` |
| `simplify-surd_1.ogg` | `4280321` | -16.23 | -2.02 | `738876f816b5b755badbe74f6391e69d74b98422eea9063350872db2f6d178e1` |
| `simplify-surd_2.ogg` | `4280322` | -16.15 | -1.82 | `63e8d78255c49fcc9e45f9ebfab11857f8b656675bbb8341af05c010355e79eb` |
| `simplify_1.ogg` | `4280191` | -16.20 | -1.69 | `03a0d3703dd7216b8a6b5579cde86cc3f5d43858ce59442a7413b5127f0348ec` |
| `simplify_2.ogg` | `4280192` | -16.15 | -1.49 | `309615668d93b7938f1fd559448055d642c0b1779171daba46e511f5b6ed0fc8` |
| `solve-equation_1.ogg` | `4280181` | -16.13 | -1.88 | `d9ad037e9bc0943147433afc2aff9063b83c618e233c5f0cb9b91cabee7db641` |
| `solve-equation_2.ogg` | `4280184` | -16.29 | -1.80 | `42b06a1c2c3575e0791994087f4e0de987caf953d87f9f16aea060e03701e42f` |
| `square-root-both-sides_1.ogg` | `4280261` | -16.32 | -1.57 | `cd10654f365755e309914a477f9fc0562b00d870718545591149bc24dab8c0ab` |
| `square-root-both-sides_2.ogg` | `4280262` | -16.26 | -1.45 | `f40bcd8cebabdf5e4662eaf88598e89c248d79bbad87ef637b6c6d7254a4d915` |
| `standardise_1.ogg` | `4280731` | -16.15 | -1.72 | `87ec5d632e7d1f593a7f8d766339eeb601e0d1aaf290c72e5722c2da8253334e` |
| `standardise_2.ogg` | `4280732` | -16.11 | -2.66 | `f99f5f05bf018c3c4010b96dcb10629531d27ddbefe701335472d464229e4141` |
| `state-answer_1.ogg` | `4280801` | -16.16 | -1.82 | `a7e75ac500a9407173a225b76c29f915d4644bf30cc3f246b610f9a99a74aeba` |
| `state-answer_2.ogg` | `4280802` | -16.15 | -1.79 | `cb419f10435f170ac0674c2f3c76720ce4475ad2b0e9039316c61ceded56d0a7` |
| `substitute-back_1.ogg` | `4280111` | -16.25 | -1.60 | `6e36432c7c9ad9fb28d2ca5fec2654541c5f72cd7979f5b63d9ec66c513a8d81` |
| `substitute-back_2.ogg` | `4280112` | -16.13 | -1.83 | `d387474c12ef0be8b867d0c82105d9fa23b0b8b75a9b2e112f4d3b12ff8057e7` |
| `substitute_1.ogg` | `4280101` | -16.33 | -2.21 | `454b04d1924f956c7dc95020d88fedcbb6c2b366bf19150103b1e8a795136558` |
| `substitute_2.ogg` | `4280102` | -16.30 | -2.44 | `ed769c911f5cc76f1ebf182bf6ddd94937384687734a7950757058b3294d448e` |
| `swap-x-and-y_1.ogg` | `4280461` | -16.17 | -2.26 | `00fdc43f5a79d27a547320c87bf829ea8c9b5f23dfc97870a30f35c9d38d47b1` |
| `swap-x-and-y_2.ogg` | `4280462` | -16.23 | -1.64 | `0ff9380952908e4f935f3b84923f37a7d259b5d12fc8b4c75dce87ed040326ca` |
| `take-logs_1.ogg` | `4280401` | -16.20 | -1.61 | `5f1589ab253dd60c9bb7a28d27d938e6e8dcff33bb43db07c3d94c7e30f9e840` |
| `take-logs_2.ogg` | `4280402` | -16.20 | -1.78 | `79cd186eb7c0c8ebf65697bc6d39e8efcef8c1204592875cecd18eefec668cf4` |
| `test-point_1.ogg` | `4280131` | -16.13 | -1.75 | `078a4bf3dc266bdb258922784c7c9d2ceca5bfe91e751e8111e7cd2c7a823b00` |
| `test-point_2.ogg` | `4280132` | -16.31 | -1.90 | `1e3e5ed5d712a67059d40d6ecfc35ead0bbe0e5b2fe3698382db50e4ef491964` |
| `transform-point_1.ogg` | `4280491` | -16.16 | -1.91 | `75284c95030463a8f26f553b7df24b15d36bd6587464bf31d3bd64a8e27e234c` |
| `transform-point_2.ogg` | `4280492` | -16.16 | -1.81 | `40c53fbc3348c8ffef08835a8c8ca6295c0eb933a8191920c0fce99cd5c5ff86` |
| `use-complement_1.ogg` | `4280701` | -16.08 | -2.22 | `90f302750ce4f82cbc621bb38212deff3c5d5e2647b312b0dd5f88a482e9c667` |
| `use-complement_2.ogg` | `4280702` | -16.04 | -2.04 | `cea06a7dd55633c0f0d3f115491ca28e56c1d6a33d32b18bd44fb79c0a0c5144` |
| `use-identity_1.ogg` | `4280091` | -16.20 | -2.24 | `c3c12ceca7ecf3ab4f7f03dd09d87a6d1e97b68f17f898c8611ddbab0532aa83` |
| `use-identity_2.ogg` | `4280094` | -16.15 | -2.16 | `17a5e4a0adc163ec5e57a3e244d44d749c1548fc90bfa7511c7c80d85b9f2fdb` |
| `use-log-law_1.ogg` | `4280421` | -16.29 | -1.80 | `ed7a513455c600616571e306094c4aed9560482108d25212ade22f76d1dd1520` |
| `use-log-law_2.ogg` | `4280422` | -16.10 | -1.74 | `3f842fcad433bed49cef306d4fdf1527ec61613586721574f7f082a2698ace07` |
| `use-right-triangle_1.ogg` | `4280571` | -16.17 | -2.01 | `6f9f2bbe0f4fd778480081da77a2dafb39e87bf5196c7b129fe7dfef5d3eae8d` |
| `use-right-triangle_2.ogg` | `4280572` | -16.13 | -2.55 | `12a4223af13ecb184bc3ade9d85b7c6e82fd79c201cb2d5b21ed01db7827c66a` |
| `use-symmetry_1.ogg` | `4280391` | -16.23 | -1.93 | `2d06c1812f7484c9154d96addf3136ff2b157c44615339017af0b7ed61b36184` |
| `use-symmetry_2.ogg` | `4280394` | -16.18 | -1.95 | `c8100306595192e625c54952b2fb2c1678bb57e1451a47a0e3f5ca412cc46f2f` |
| `zero-product_1.ogg` | `4280231` | -16.14 | -1.96 | `637a6751a32fe9e4b2c599ddc6f51718ff3b7d3662355cc54f59f798cc973ca4` |
| `zero-product_2.ogg` | `4280232` | -16.19 | -1.90 | `74ef2c85385e5cb8976613b724f87b866e0831c04ba7d960386ede37f4a49247` |
