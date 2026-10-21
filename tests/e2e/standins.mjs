// Stand-in PNGs for every art file the game hooks, at the exact sizes in
// ART_REQUIREMENTS.md. Drawn here, in memory, so the art tests never depend
// on (or commit) files under assets/.
import zlib from 'node:zlib';

const CRC_TABLE = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
const crc32 = buf => {
  let c = 0xFFFFFFFF;
  for (const b of buf) c = CRC_TABLE[(c ^ b) & 0xFF] ^ (c >>> 8);
  return (c ^ 0xFFFFFFFF) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};

// An RGBA PNG; `pixel(x, y)` returns [r, g, b, a]
export function png(width, height, pixel) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y++) {
    const row = y * (width * 4 + 1);
    for (let x = 0; x < width; x++) raw.set(pixel(x, y), row + 1 + x * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0); ihdr.writeUInt32BE(height, 4);
  ihdr.set([8, 6, 0, 0, 0], 8);  // 8-bit RGBA
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
  ]);
}

const hex = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
const TEAL = hex('#22D3C5'), MAGENTA = hex('#FF3DA7'), RUST = hex('#FAA261'), DUST = hex('#EACB74');
const METAL = hex('#4B5563'), DARK = hex('#111827'), GREY = hex('#9CA3AF');
const CLEAR = [0, 0, 0, 0];

// A picture: diagonal stripes in `colour`, a dark outline, and a bright dot,
// so it's obviously a stand-in in a screenshot
const picture = (w, h, colour) => png(w, h, (x, y) => {
  if (x < 3 || y < 3 || x >= w - 3 || y >= h - 3) return [...DARK, 255];
  if (Math.hypot(x - w / 2, y - h / 2) < Math.min(w, h) / 6) return [255, 255, 255, 255];
  return ((x + y) >> 3) % 2 ? [...colour, 255] : [...colour.map(c => c >> 1), 255];
});

// A 9-slice frame: a `left`/`top` band around the edge with rivets in the
// corners, and a transparent window inside
const frame = (w, h, { top, left, bottom = top, right = left, colour }) => png(w, h, (x, y) => {
  const inWindow = x >= left && x < w - right && y >= top && y < h - bottom;
  if (inWindow) return CLEAR;
  const edge = x < 2 || y < 2 || x >= w - 2 || y >= h - 2
    || (x === left - 1 || x === w - right) && y >= top - 1 && y <= h - bottom
    || (y === top - 1 || y === h - bottom) && x >= left - 1 && x <= w - right;
  if (edge) return [...colour, 255];
  const r = Math.min(top, left) / 4;
  for (const [cx, cy] of [[left / 2, top / 2], [w - right / 2, top / 2], [left / 2, h - bottom / 2], [w - right / 2, h - bottom / 2]]) {
    if (Math.hypot(x - cx, y - cy) < r) return [...colour, 255];
  }
  return ((x + y) >> 2) % 2 ? [...METAL, 255] : [...METAL.map(c => c - 16), 255];
});

const icon = colour => png(128, 128, (x, y) => {
  const d = Math.hypot(x - 64, y - 64);
  return d < 52 ? [...colour, 255] : d < 58 ? [...DARK, 255] : CLEAR;
});

// path under assets/ → [width, height, () => PNG buffer]
const SPECS = {
  'icons/favicon-32.png': [32, 32, () => picture(32, 32, MAGENTA)],
  'icons/icon-192.png': [192, 192, () => picture(192, 192, MAGENTA)],
  'icons/icon-512.png': [512, 512, () => picture(512, 512, MAGENTA)],
  'avatars/avatar-female.png': [256, 256, () => picture(256, 256, MAGENTA)],
  'avatars/avatar-male.png': [256, 256, () => picture(256, 256, TEAL)],
  'avatars/avatar-spark.png': [256, 256, () => picture(256, 256, DUST)],
  'avatars/spark-happy.png': [128, 128, () => picture(128, 128, TEAL)],
  'avatars/spark-thinking.png': [128, 128, () => picture(128, 128, DUST)],
  'avatars/spark-surprised.png': [128, 128, () => picture(128, 128, RUST)],
  'avatars/spark-sarcastic.png': [128, 128, () => picture(128, 128, MAGENTA)],
  'enemies/d1-scavenger.png': [256, 256, () => picture(256, 256, RUST)],
  'enemies/d2-raider.png': [256, 256, () => picture(256, 256, RUST)],
  'enemies/d3-enforcer.png': [256, 256, () => picture(256, 256, MAGENTA)],
  'enemies/d4-warlord.png': [256, 256, () => picture(256, 256, MAGENTA)],
  'enemies/d5-overseer.png': [256, 256, () => picture(256, 256, MAGENTA)],
  'ui/lifeline-fifty-on.png': [128, 128, () => icon(MAGENTA)],
  'ui/lifeline-fifty-off.png': [128, 128, () => icon(GREY)],
  'ui/lifeline-freeze-on.png': [128, 128, () => icon(TEAL)],
  'ui/lifeline-freeze-off.png': [128, 128, () => icon(GREY)],
  'ui/lifeline-hint-on.png': [128, 128, () => icon(DUST)],
  'ui/lifeline-hint-off.png': [128, 128, () => icon(GREY)],
  'ui/wanted-badge.png': [96, 64, () => picture(96, 64, RUST)],
  'ui/question-card.png': [360, 400, () => frame(360, 400, { top: 40, left: 40, colour: RUST })],
  'ui/hp-frame-player.png': [320, 48, () => frame(320, 48, { top: 14, left: 24, colour: TEAL })],
  'ui/hp-frame-enemy.png': [320, 48, () => frame(320, 48, { top: 14, left: 24, colour: MAGENTA })],
  'map/island-scrap-fields.png': [200, 150, () => picture(200, 150, RUST)],
  'map/island-signal-tower.png': [200, 150, () => picture(200, 150, TEAL)],
  'map/island-dry-flats.png': [200, 150, () => picture(200, 150, DUST)],
  'map/island-radio-spires.png': [200, 150, () => picture(200, 150, MAGENTA)],
  'map/island-engine-core.png': [200, 150, () => picture(200, 150, GREY)],
  'map/thunderdome.png': [200, 150, () => picture(200, 150, MAGENTA)],
  'map/arena-bg.png': [1080, 600, () => picture(1080, 600, METAL)],
  'map/overworld.png': [1080, 1920, () => picture(1080, 1920, DUST)],
};

export const STANDIN_SIZES = Object.fromEntries(Object.entries(SPECS).map(([p, [w, h]]) => [p, [w, h]]));

const cache = new Map();
export function standin(path) {
  if (!SPECS[path]) return null;
  if (!cache.has(path)) cache.set(path, SPECS[path][2]());
  return cache.get(path);
}
