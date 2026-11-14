#!/usr/bin/env node
// Renders an explainer clip without anyone watching. Usage, from tools/explainer-clips:
//   node render.mjs <clip-id> storyboard   one still per beat + out/<clip>/storyboard.html + voice-script.json (fast; do this first)
//   node render.mjs <clip-id> video        out/<clip>/<clip>.mp4 (review), .ogv (Godot), .vtt (captions), report.json
//   node render.mjs <clip-id> all          both
// Add --draft to video for a quick rough render (never ship a draft).
// Exits non-zero when a check fails, so a worker or CI can gate on it. Needs ffmpeg and Chromium (Playwright).
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile, access } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { existsSync } from 'node:fs';

const HERE = path.dirname(fileURLToPath(import.meta.url)), ROOT = path.resolve(HERE, '../..');
const DRAFT = process.argv.includes('--draft');   // one sample a frame: about four times faster, rougher edges, for checking only
const [clip, mode = 'all'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
if (!clip || !['storyboard', 'video', 'all'].includes(mode)) { console.error('usage: node render.mjs <clip-id> storyboard|video|all'); process.exit(2); }
const OUT = path.join(HERE, 'out', clip), FPS = 30, LUFS = -15;
const { chromium } = await import('@playwright/test');   // from the repo root: run `npm ci` there once
// CHROMIUM_PATH points at a browser when the Playwright-managed one is not installed (cloud sessions keep one in /opt/pw-browsers)
const CHROME = process.env.CHROMIUM_PATH || (existsSync('/opt/pw-browsers/chromium') ? '/opt/pw-browsers/chromium' : undefined);

const TYPES = { '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.woff2': 'font/woff2', '.ogg': 'audio/ogg', '.png': 'image/png' };
const server = createServer(async (req, res) => {
  try { const p = path.join(ROOT, decodeURIComponent(new URL(req.url, 'http://x').pathname)); if (!p.startsWith(ROOT)) throw 0;
    const data = await readFile(p); res.writeHead(200, { 'content-type': TYPES[path.extname(p)] || 'application/octet-stream' }); res.end(data); } catch { res.writeHead(404); res.end(); }
}).listen(0, '127.0.0.1');
await once(server, 'listening');
const base = `http://127.0.0.1:${server.address().port}/tools/explainer-clips/player.html?clip=${clip}${DRAFT ? '&samples=1' : ''}`;

const run = (cmd, args, input) => new Promise((ok, bad) => { const p = spawn(cmd, args, { stdio: [input ? 'pipe' : 'ignore', 'pipe', 'pipe'] }); let out = '', err = '';
  p.stdout.on('data', (d) => (out += d)); p.stderr.on('data', (d) => (err += d)); p.on('close', (c) => (c ? bad(new Error(`${cmd} failed:\n${err.slice(-2000)}`)) : ok(out + err))); if (input) p.stdin.end(input); });
const problems = [], warn = (m) => { problems.push(m); console.error('CHECK FAILED: ' + m); };

const browser = await chromium.launch({ executablePath: CHROME, args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', '--enable-gpu'] });
const page = await browser.newPage();
page.on('pageerror', (e) => warn('page error: ' + e.message));
page.on('console', (m) => { if (m.type() === 'error') warn('console error: ' + m.text()); });
await page.goto(base); await page.waitForFunction('window.READY === true', null, { timeout: 120000 });
const style = await page.evaluate(() => ({ duration: STYLE.duration, size: STYLE.size || [1920, 1080], samples: STYLE.render.samples || 16, voice: STYLE.voice || [], teacher: STYLE.teacher || '', zone: STYLE.zone || '', beats: STYLE.beats || [], name: STYLE.name, topic: STYLE.topic, syllabus: STYLE.syllabus || '', assumptions: STYLE.assumptions || [] }));
const [W, H] = style.size, D = style.duration;
await mkdir(OUT, { recursive: true });
const cast = JSON.parse(await readFile(path.join(HERE, 'teachers.json'), 'utf8')), teachers = cast.teachers;
// the narrator is the zone's teacher unless the clip names one itself
if (!style.teacher) style.teacher = cast.zones[style.zone] || '';
if (!cast.zones[style.zone]) warn(`clip zone "${style.zone}" is not a map zone in teachers.json`);
const frame = async (t, n) => Buffer.from((await page.evaluate(([t, n]) => { seek(t, n); return document.getElementById('c').toDataURL('image/png'); }, [t, n])).split(',')[1], 'base64');

// ---- checks on the script itself: lines are in bounds, in tone, and their recordings (when made) fit their slots
const BANNED = /\b(just|easy|simple|simply|obvious|obviously|guess)\b/i;   // writing/voice-sheets.md
const voiceDir = path.join(ROOT, 'game/assets/audio/voice', style.teacher || 'unassigned', 'clips', clip), voice = [];
if (!style.voice.length) warn('clip has no voice lines: every clip is fully voiced');
if (!teachers[style.teacher]) warn(`teacher "${style.teacher}" is not in teachers.json`);
for (const [i, v] of style.voice.entries()) {
  const file = path.join(voiceDir, String(i + 1).padStart(2, '0') + '.ogg'), line = { ...v, n: i + 1, file: path.relative(ROOT, file), recorded: existsSync(file) };
  if (BANNED.test(v.say)) warn(`line ${i + 1} uses a word the voice sheets rule out: "${v.say}"`);
  if (!(v.slot > 0)) warn(`line ${i + 1} has no slot`);
  if (line.recorded) { line.len = +(await run('ffprobe', ['-v', '0', '-show_entries', 'format=duration', '-of', 'csv=p=0', file])).trim();
    if (line.len > v.slot) warn(`line ${i + 1} runs ${line.len.toFixed(2)} s but its slot is ${v.slot} s: re-record shorter or re-time the beat`); }
  voice.push(line);
}
voice.forEach((v, i) => { if (i && v.t < voice[i - 1].t + voice[i - 1].slot + 0.2) warn(`line ${v.n} starts inside line ${voice[i - 1].n}'s slot (needs a 0.2 s gap)`);
  if (v.t + v.slot > D - 0.5) warn(`line ${v.n}'s slot runs into the last half second`); });
for (const [i, b] of style.beats.entries()) if (!voice.some((v) => v.t >= b.t0 && v.t < b.t1)) warn(`beat ${i + 1} has no voice line: every beat is voiced`);
const recorded = voice.filter((v) => v.recorded), pending = voice.filter((v) => !v.recorded);
// what the Audio Designer records from: the lines, where each file goes and how long it may run
await writeFile(path.join(OUT, 'voice-script.json'), JSON.stringify({ clip, zone: style.zone, teacher: style.teacher, sheet: teachers[style.teacher]?.sheet ?? null, brief: teachers[style.teacher]?.brief ?? null, lines: voice.map((v) => ({ n: v.n, say: v.say, maxSeconds: v.slot, file: v.file, recorded: v.recorded })) }, null, 2) + '\n');
if (!style.beats.length) warn('clip has no beats: reviewers need one entry per beat');
if (D < 5 || D > 30) warn(`duration ${D.toFixed(1)} s is outside 5-30 s`);

// ---- storyboard: one finished still per beat, and a page that lays them out with their notes
if (mode !== 'video') {
  const esc = (s) => String(s).replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
  let cards = '';
  for (const [i, b] of style.beats.entries()) {
    const name = `beat-${i + 1}.png`; await writeFile(path.join(OUT, name), await frame(b.key, style.samples));
    const said = voice.filter((v) => v.t >= b.t0 && v.t < b.t1).map((v) => `“${v.say}”${v.recorded ? '' : ' (not recorded yet)'}`).join(' ') || 'nothing';
    cards += `<figure><img src="${name}" alt="Beat ${i + 1}"><figcaption><b>Beat ${i + 1}</b> · ${b.t0.toFixed(1)}–${b.t1.toFixed(1)} s<br><b>On screen:</b> ${esc(b.text)}<br><b>Narrator says:</b> ${esc(said)}<br><b>Change:</b> ${esc(b.change)}<br><b>Camera:</b> ${esc(b.camera)}<br><b>Sound:</b> ${esc(b.sound)}</figcaption></figure>`;
  }
  await writeFile(path.join(OUT, 'storyboard.html'), `<!doctype html><meta charset="utf-8"><title>Storyboard: ${esc(style.name)}</title><style>body{background:#0c1118;color:#e8ecf2;font:15px/1.5 system-ui,sans-serif;margin:24px}h1{color:#22d3c5}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:20px}figure{margin:0;background:#1f2937;border-radius:8px;overflow:hidden}img{width:100%;display:block}figcaption{padding:12px}b{color:#eacb74}</style><h1>${esc(style.name)}</h1><p>${esc(style.topic)} · ${esc(style.syllabus)} · zone: ${esc(style.zone)} · narrator: ${esc(teachers[style.teacher]?.name ?? 'none')} · ${D.toFixed(1)} s · ${W}×${H}</p><main>${cards}</main><h2>Assumed</h2><ul>${style.assumptions.map((a) => `<li>${esc(a)}</li>`).join('')}</ul>`);
  console.log(`storyboard: ${path.relative(process.cwd(), path.join(OUT, 'storyboard.html'))}`);
}

// ---- video: every frame at the style's full sample count, effects rendered offline, Spark's lines mixed on top
if (mode !== 'storyboard') {
  const N = Math.round(D * FPS), silent = path.join(OUT, 'picture.mp4'), sfx = path.join(OUT, 'sfx.f32'), mp4 = path.join(OUT, `${clip}.mp4`);
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'png', '-i', '-', '-c:v', 'libx264', '-crf', '14', '-preset', 'medium', '-pix_fmt', 'yuv420p', silent], { stdio: ['pipe', 'inherit', 'inherit'] });
  let first, last, hold;
  for (let i = 0; i < N; i++) {
    const png = await frame(i / FPS, DRAFT ? 1 : style.samples);
    if (i === 0) first = png; if (i === N - 31) hold = png; if (i === N - 1) last = png;
    if (!ff.stdin.write(png)) await once(ff.stdin, 'drain');
    if (i % 30 === 0) process.stdout.write(`\rframes ${i}/${N}`);
  }
  ff.stdin.end(); await once(ff, 'close'); process.stdout.write(`\rframes ${N}/${N}\n`);
  await writeFile(path.join(OUT, 'first.png'), first); await writeFile(path.join(OUT, 'last.png'), last);
  if (first.length < 60000) warn('the first frame is nearly empty: it should already be worth looking at');

  const snd = await page.evaluate(() => renderSound());
  await writeFile(sfx, Buffer.from(snd.b64, 'base64'));
  const ins = ['-f', 'f32le', '-ar', String(snd.sr), '-ac', '2', '-i', sfx], parts = ['[0:a]volume=1[s]'];
  recorded.forEach((v, i) => { ins.push('-i', path.join(ROOT, v.file)); parts.push(`[${i + 1}:a]aresample=48000,adelay=${Math.round(v.t * 1000)}:all=1,volume=1.6[v${i}]`); });
  const mix = path.join(OUT, 'mix.wav');
  await run('ffmpeg', ['-y', '-loglevel', 'error', ...ins, '-filter_complex', `${parts.join(';')};[s]${recorded.map((_, i) => `[v${i}]`).join('')}amix=inputs=${recorded.length + 1}:normalize=0,loudnorm=I=${LUFS}:TP=-1.5:LRA=11,apad[a]`, '-map', '[a]', '-t', String(D), '-ar', '48000', mix]);
  await run('ffmpeg', ['-y', '-loglevel', 'error', '-i', silent, '-i', mix, '-c:v', 'copy', '-c:a', 'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart', mp4]);
  // Godot's VideoStreamPlayer plays Ogg Theora only
  await run('ffmpeg', ['-y', '-loglevel', 'error', '-i', silent, '-i', mix, '-c:v', 'libtheora', '-q:v', '8', '-c:a', 'libvorbis', '-q:a', '5', path.join(OUT, `${clip}.ogv`)]);
  const loud = /Integrated loudness:\s+I:\s+(-?[\d.]+) LUFS/.exec(await run('ffmpeg', ['-i', mp4, '-af', 'ebur128', '-f', 'null', '-']).catch((e) => String(e)));
  if (loud && Math.abs(+loud[1] - LUFS) > 1.5) warn(`loudness is ${loud[1]} LUFS, wanted about ${LUFS}`);

  // captions: the teacher's words, for the game's caption track
  const ts = (s) => new Date(s * 1000).toISOString().slice(11, 23);
  await writeFile(path.join(OUT, `${clip}.vtt`), 'WEBVTT\n\n' + voice.map((v) => `${ts(v.t)} --> ${ts(v.t + (v.len ?? v.slot))}\n${v.say}\n`).join('\n'));
  await writeFile(path.join(OUT, 'report.json'), JSON.stringify({ clip, name: style.name, topic: style.topic, syllabus: style.syllabus, duration: D, size: [W, H], fps: FPS, frames: N, loudness: loud ? +loud[1] : null,
    zone: style.zone, teacher: style.teacher,
    voice: voice.map((v) => ({ n: v.n, t: v.t, slot: v.slot, len: v.len ?? null, recorded: v.recorded, say: v.say })), voicePending: pending.length, draft: DRAFT, ready: !DRAFT && !problems.length && !pending.length, assumptions: style.assumptions, problems }, null, 2) + '\n');
  console.log(`video: ${path.relative(process.cwd(), mp4)} (+ .ogv, .vtt, report.json)`);
}

await browser.close(); server.close();
if (problems.length) { console.error(`\n${problems.length} check(s) failed`); process.exit(1); }
if (pending.length) console.log(`voice pending: ${pending.length} line(s) not recorded yet; see out/${clip}/voice-script.json`);
console.log('all checks passed');
