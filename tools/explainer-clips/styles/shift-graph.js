// CLIP: shift-graph. Just the maths: a board, no characters. "Replace x with x - 3 and the graph moves right 3" (AA SL 2.11, graph transformations).
// The prototype clip for the Salvage Ink look. Copy this file to start a new clip: change the content block,
// the objects and the moves, and keep the kit (lib/salvage-ink.js) and the structure.
{
  // ---------------------------------------------------------------- content
  const SHIFT = 3;                                  // y = (x - 3)^2: every point moves 3 to the right
  const TEXT = { start: 'y = x²', rule: 'y = (x − 3)²', word: 'RIGHT 3', end: 'vertex (3, 0)' };

  // ---------------------------------------------------------------- timing
  // Props move on twos (15 drawings a second); every event sits on that grid so picture, effects and voice share it.
  const DPS = 15, F = 1 / DPS, at = (n) => n / DPS;
  const D = at(327);                                // 21.8 s: four beats of about 5.3 s, one teacher line each
  const HOPS = [176, 182, 188].map(at), HOP = 4 * F;   // one hop per unit; each takes 4 drawings then holds 2
  const T = { draw0: at(4), draw1: at(22), cap1: at(26), cut2: at(80), cap2: at(84), arrow: at(105), word: at(109),
    cut3: at(160), dots: at(164), land: HOPS[2] + HOP, cut4: at(240), cap4: at(246), ting: at(255) };
  // The narrator's lines: every beat is voiced, and the captions are these words exactly. A clip is fixed, so the
  // narrator can say this clip's numbers. `slot` is the longest the recording may run (about 0.45 s a word).
  // The narrator is whoever teachers.json gives for the clip's zone. These are plain drafts: the Writer puts them in
  // the tutor's voice once that tutor is cast.
  const VOICE = [
    { t: at(8), slot: 4.8, say: 'Here is y equals x squared, its lowest point at the origin.' },
    { t: at(86), slot: 4.8, say: 'Put x minus three where x was, and the curve shifts right.' },
    { t: at(165), slot: 4.8, say: 'Every point moves three to the right. The shape never changes.' },
    { t: at(246), slot: 4.8, say: 'So the vertex lands at three, zero. Same curve, new position.' },
  ];
  // Beats, for the storyboard and for reviewers: `key` is the time of the still that shows the beat.
  const BEATS = [
    { t0: 0, t1: T.cut2, key: at(64), text: TEXT.start, change: 'The curve y = x² is chalked onto the board; its equation slip pops in.', camera: 'Whole board, slow drift.', sound: 'Chalk on slate, paper slip.' },
    { t0: T.cut2, t1: T.cut3, key: at(145), text: TEXT.rule + ' / ' + TEXT.word, change: 'The slip is replaced by the new rule; an arrow runs 3 units along the x-axis and the word lands.', camera: 'Whips in on the axis.', sound: 'Three relay ticks, a metal stamp.' },
    { t0: T.cut3, t1: T.cut4, key: at(220), text: '(none new)', change: 'Vertex and two side points hop right one unit at a time, three hops; the curve rides with them and a dashed ghost stays behind.', camera: 'Follows the curve right.', sound: 'Scrape per hop, metal clank on landing.' },
    { t0: T.cut4, t1: D, key: at(305), text: TEXT.end, change: 'New vertex is named; glints on the curve. Holds.', camera: 'Pulls back to the whole board.', sound: 'Stamp, two struck-pipe dings.' },
  ];

  registerStyle({
    id: 'shift-graph',
    name: 'Shift a graph right',
    topic: 'Replacing x with x − 3 moves the graph of y = x² three units right',
    syllabus: 'AA SL 2.11',
    duration: D,
    size: [1080, 1350],
    fonts: FONTS,
    zone: 'functions',
    voice: VOICE,
    beats: BEATS,
    assumptions: ['Clip frame is 1080×1350 (4:5) so it sits above captions and controls on the 1080×1920 game screen.',
      'The four teacher lines are plain drafts; the Functions tutor is not cast yet (GitHub issue #18), so nothing is recorded.'],
    render: { samples: 4, preview: 2, shutter: 0, tone: 'linear', exposure: 1, bloom: 0, vignette: 0, grain: 0, fov: 26, background: PAL.ground.lit },

    build(S) {
      const { THREE, K, scene, camera } = S;
      const ink = inkKit(S, { sun: [-5.5, 7.5, 6.5], sunTarget: [0, 1.6, 0], sunSize: 8 }), { fill, solid, mark, arc, burst, flat } = ink;
      ink.print();
      const M = { slate: fill(PAL.slate, { band: 0.05, hatch: 1.4 }), rust: fill(PAL.rust, { gloss: 0.03 }), iron: fill(PAL.iron, { gloss: 0.04 }),
        concrete: fill(PAL.concrete), magenta: fill(PAL.magenta, { gloss: 0.05 }), teal: fill(PAL.teal, { gloss: 0.05 }) };
      const group = (parent = scene) => { const g = new THREE.Group(); parent.add(g); return g; };
      const box = (w, h, d, r, mat, x, y, z, parent, f) => { const m = solid(K.roundedBox(w, h, d, r, 4), mat, parent, f); m.position.set(x, y, z); return m; };
      const pop = (x, d = 0.25) => (x < 0 ? 0 : K.ease.outBack(Math.min(1, (x + F / 2) / d), 2.4));
      const wobble = (x, f = 3.4, k = 9) => (x <= 0 ? 0 : Math.exp(-k * x) * Math.sin(x * 2 * Math.PI * f));
      const show = (m, s) => { m.visible = s > 1e-3; m.scale.setScalar(Math.max(s, 1e-3)); };

      // ---- ground: charcoal with a field of printed dots
      const ground = new THREE.Mesh(new THREE.PlaneGeometry(90, 90), fill(PAL.ground, { band: 0, hatch: 1.7 })); ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true; scene.add(ground);
      { const pts = [], r = 0.8; for (let j = -14; j <= 14; j++) for (let i = -14; i <= 14; i++) { const x = (i + (j & 1) * 0.5) * r, z = j * r * 0.866, s = 0.17 * (1 - K.smooth(2.5, 9, Math.hypot(x, z - 1))); if (s > 0.02) pts.push([x, z, s]); }
        const dots = new THREE.InstancedMesh(new THREE.CircleGeometry(1, 20).rotateX(-Math.PI / 2), fill(PAL.groundDot, { band: 0, hatch: 1.7 }), pts.length); dots.receiveShadow = true;
        pts.forEach(([x, z, s], i) => K.place(dots, i, [x, 0.004, z], null, s)); scene.add(dots); }

      // ---- the chalkboard: a slate slab in a rust frame on two posts, leaning back a little
      const BW = 4.5, BH = 3.9, BY = 2.75, LEAN = -0.1;
      const board = group(); board.position.set(0, BY, 0); board.rotation.x = LEAN;
      box(BW + 0.36, BH + 0.36, 0.2, 0.08, M.rust, 0, 0, -0.06, board);
      box(BW, BH, 0.2, 0.03, M.slate, 0, 0, 0.02, board, { line: 2.5, cast: false });
      for (const x of [-1.6, 1.6]) box(0.22, BY - BH / 2 + 0.3, 0.22, 0.05, M.iron, x, -BH / 2 - (BY - BH / 2) / 2 + 0.12, -0.2, board);
      for (const [x, y] of [[-1, 1], [1, 1], [-1, -1], [1, -1]]) solid(new THREE.SphereGeometry(0.07, 14, 10), M.concrete, board, { line: 2.5, cast: false }).position.set(x * (BW / 2 + 0.07), y * (BH / 2 + 0.07), 0.06);

      // ---- the graph, chalked on the slate. Maths units -> board units: [gx(x), gy(y)]
      const U = 0.44, OX = -0.66, OY = -1.3, gx = (x) => OX + x * U, gy = (y) => OY + y * U;
      const graph = group(board); graph.position.z = 0.125;
      const layer = (m, z) => { m.position.z = z; graph.add(m); return m; };
      const GRID = [], XR = [-3, 6], YR = [-1, 6.5];
      for (let x = Math.ceil(XR[0]); x <= XR[1]; x++) if (x) GRID.push([[[gx(x), gy(YR[0])], [gx(x), gy(YR[1])]], 0.012, 'none']);
      for (let y = Math.ceil(YR[0]); y <= YR[1]; y++) if (y) GRID.push([[[gx(XR[0]), gy(y)], [gx(XR[1]), gy(y)]], 0.012, 'none']);
      layer(new THREE.Mesh(ink.strokes(GRID), flat('#33445a')), 0.001);
      const head = (x, y, dx, dy, s = 0.13) => [[[x - dx * s - dy * s * 0.6, y - dy * s + dx * s * 0.6], [x, y], [x - dx * s + dy * s * 0.6, y - dy * s - dx * s * 0.6]], 0.04, 'none'];
      layer(new THREE.Mesh(ink.strokes([[[[gx(XR[0]), gy(0)], [gx(XR[1] + 0.3), gy(0)]], 0.04, 'none'], [[[gx(0), gy(YR[0])], [gx(0), gy(YR[1] + 0.3)]], 0.04, 'none'],
        head(gx(XR[1] + 0.3), gy(0), 1, 0), head(gx(0), gy(YR[1] + 0.3), 0, 1)]), flat(PAPER)), 0.002);
      const chalk = (text, h, color = PAPER) => K.textPlane(text, { font: '200px "Share Tech Mono"', color, height: h });
      { const lx = chalk('x', 0.3), ly = chalk('y', 0.3); lx.position.set(gx(XR[1] - 0.1), gy(-0.6), 0.003); ly.position.set(gx(-0.6), gy(YR[1] + 0.2), 0.003); graph.add(lx, ly); }
      const curvePts = (x0, x1, n = 40) => Array.from({ length: n + 1 }, (_, i) => { const x = K.lerp(x0, x1, i / n); return [gx(x), gy(x * x)]; });
      const XM = 2.45;
      // the dashed ghost of the old curve, left behind when the live curve moves
      const ghost = layer(new THREE.Mesh(ink.strokes(Array.from({ length: 13 }, (_, i) => { const a = -XM + i * (2 * XM / 12.6), b = a + XM / 10; return [curvePts(a, b, 6), 0.035, 'none']; })), flat(PAL.dust.shade)), 0.004);
      // the live curve; drawn in over STAGES drawings in beat 1, then carried right by `live`
      const live = layer(group(), 0.006), STAGES = 9;
      const stages = Array.from({ length: STAGES }, (_, i) => { const m = mark([[curvePts(-XM, K.lerp(-XM, XM, (i + 1) / STAGES), 8 + i * 5), 0.075, i === STAGES - 1 ? 'none' : 'tail']], PAL.teal.lit, 0.022); live.add(m); return m; });
      const disc = (r, color) => { const g = group(); g.add(new THREE.Mesh(new THREE.CircleGeometry(r + 0.03, 24), flat(INK))); const top = new THREE.Mesh(new THREE.CircleGeometry(r, 24), flat(color)); top.position.z = 0.002; g.add(top); return g; };
      const dots = [[0, 0, 0.12, PAL.magenta.lit], [-1, 1, 0.085, PAPER], [1, 1, 0.085, PAPER]].map(([x, y, r, c]) => { const d = disc(r, c); d.position.set(gx(x), gy(y), 0.01); live.add(d); return d; });
      // the arrow along the x-axis, and the "3" under where it ends
      const arrow = layer(mark([[[[gx(0.15), gy(-0.5)], [gx(SHIFT - 0.3), gy(-0.5)]], 0.07, 'none'], head(gx(SHIFT), gy(-0.5), 1, 0, 0.2)].map((s, i) => (i ? [s[0], 0.075, 'none'] : s)), PAL.magenta.lit, 0.024), 0.008);
      const three = chalk(String(SHIFT), 0.3, PAL.magenta.lit); three.position.set(gx(SHIFT / 2), gy(-1.12), 0.009); graph.add(three);
      const ticks = [1, 2, 3].map((i) => layer(new THREE.Mesh(ink.strokes([[[[gx(i), gy(-0.22)], [gx(i), gy(0.22)]], 0.045, 'none']]), flat(PAL.magenta.lit)), 0.008));
      const speed = layer(mark([[[[0, 0.5], [-0.45, 0.5]], 0.045, 'head'], [[[0, 0.15], [-0.6, 0.15]], 0.05, 'head'], [[[0, -0.2], [-0.4, -0.2]], 0.045, 'head']], PAPER, 0), 0.012);
      const hit = layer(mark(burst(9, 0.24, 0.24, 0.2, 0.05, 4), PAPER, 0), 0.012);
      const star = (s) => mark([[[[0, -s], [0, 0], [0, s]], s * 0.34], [[[-s * 0.7, 0], [0, 0], [s * 0.7, 0]], s * 0.3]], PAPER, 0.024);
      const ting = [layer(star(0.26), 0.014), layer(star(0.15), 0.014)];

      // ---- the camera: one framing per beat. [aim x, y, z, elevation, azimuth, distance]
      const DEG = Math.PI / 180;
      const cam = K.track([[0, [0, 2.75, 0, 9 * DEG, -5 * DEG, 14.6]], [T.cut2 - 4 * F, [0, 2.75, 0, 9.5 * DEG, -2 * DEG, 14.3], 'linear'],
        [T.cap2, [-0.1, 2.55, 0, 8 * DEG, 4 * DEG, 13.0], 'inOutQuint'], [T.cut3 - 4 * F, [-0.1, 2.55, 0, 8.5 * DEG, 7 * DEG, 12.8], 'linear'],
        [T.dots, [0.2, 2.6, 0, 9 * DEG, -5 * DEG, 12.9], 'inOutQuint'], [T.cut4 - 4 * F, [0.25, 2.6, 0, 9.5 * DEG, -2 * DEG, 12.7], 'linear'],
        [T.cap4, [0, 2.7, 0, 10 * DEG, 4 * DEG, 14.8], 'inOutQuint'], [D, [0, 2.7, 0, 10 * DEG, 7 * DEG, 14.5], 'linear']]);
      const camPos = (c) => [c[0] + c[5] * Math.sin(c[4]) * Math.cos(c[3]), c[1] + c[5] * Math.sin(c[3]), c[2] + c[5] * Math.cos(c[4]) * Math.cos(c[3])];
      // the world point at screen position (sx, sy) (-1..1) at a given time, turned flat to the picture; push moves it away
      const TAN = Math.tan(S.R.fov / 2 * DEG);
      const spot = (time, sx, sy, push = 0) => { const c = cam(time), p = camPos(c), e = c[3], a = c[4], d = c[5] + push, hh = d * TAN, hw = hh * S.W / S.H;
        const f = [-Math.sin(a) * Math.cos(e), -Math.sin(e), -Math.cos(a) * Math.cos(e)], r = [Math.cos(a), 0, -Math.sin(a)], u = [-Math.sin(a) * Math.sin(e), Math.cos(e), -Math.cos(a) * Math.sin(e)];
        return { pos: [0, 1, 2].map((i) => p[i] + f[i] * d + r[i] * sx * hw + u[i] * sy * hh), rot: new THREE.Quaternion().setFromRotationMatrix(new THREE.Matrix4().makeBasis(new THREE.Vector3(...r), new THREE.Vector3(...u), new THREE.Vector3(...f).negate())) }; };
      // a label stands in the scene, 2 units in front of the board, facing the camera of its own framing. It pops in at
      // `when` and out at `until`; (sx, sy) is its centre on screen (-1..1) and `wide` its width as a share of the frame.
      const label = (mesh, when, until, sx, sy, wide, tilt = 0) => { const g = group(), look = when + 0.9, a = spot(look, sx, sy, -2); g.add(mesh); g.position.set(...a.pos); g.quaternion.copy(a.rot);
        const s0 = wide * 2 * (cam(look)[5] - 2) * TAN * S.W / S.H / mesh.userData.size[0];
        return (q) => { const x = q - when; show(g, s0 * pop(x) * (1 - K.seg(q, until, until + 2 * F))); mesh.rotation.z = tilt + 0.05 * wobble(x + 0.03, 4, 10); }; };
      const word = ink.lettering(TEXT.word, { height: 0.62 }), [ww, wh] = word.userData.size;
      const wordTicks = mark(burst(9, ww * 0.56, wh * 0.62, 0.3, 0.06, 7)); wordTicks.position.z = -0.01; word.add(wordTicks);
      const labels = [
        label(ink.caption(TEXT.start), T.cap1, T.cut2 - 2 * F, -0.4, 0.84, 0.4, 0.03),
        label(ink.caption(TEXT.rule), T.cap2, T.cut3 - 2 * F, -0.2, 0.84, 0.64, -0.03),
        label(word, T.word, T.cut3 - 2 * F, 0.12, -0.74, 0.66, 0.02),
        label(ink.caption(TEXT.rule), T.dots - 2 * F, T.cut4 - 2 * F, -0.2, 0.84, 0.64, 0.02),
        label(ink.caption(TEXT.rule), T.cap4 - 2 * F, 99, -0.2, 0.84, 0.62, -0.03),
        label(ink.caption(TEXT.end), T.cap4, 99, 0.12, -0.76, 0.6, 0.03),
      ];

      // how far the live curve has moved (in units) at drawing time q, and its hop height
      const moved = (q) => HOPS.reduce((s, h) => s + K.seg(q, h, h + HOP, K.ease.inOut), 0);
      const hopY = (q) => HOPS.reduce((s, h) => { const u = K.seg(q, h, h + HOP); return s + (u > 0 && u < 1 ? Math.sin(Math.PI * u) : 0); }, 0);
      return {
        update(t) {
          const q = Math.floor(t * DPS + 1e-3) / DPS, n = Math.round(q * DPS);
          const c = cam(t); K.look(camera, camPos(c), c); ink.frame(t, camera);

          // beat 1: the curve is chalked on, one longer stroke per drawing
          const drawn = Math.ceil(K.seg(q, T.draw0, T.draw1) * STAGES - 1e-6);
          stages.forEach((m, i) => { m.visible = i === Math.min(drawn, STAGES) - 1; });

          // beat 2: arrow and ticks count out the shift
          show(arrow, pop(q - T.arrow, 0.2)); show(three, pop(q - T.arrow - 3 * F, 0.2));
          ticks.forEach((m, i) => { m.visible = q >= T.arrow + i * 2 * F && q < T.cut4; });
          wordTicks.visible = q >= T.word && q < T.word + 2 * F - 1e-3;

          // beat 3: three hops to the right; the ghost stays behind
          const mv = moved(q), mv0 = moved(q - F), hy = hopY(q), fast = mv - mv0 > 0.2;
          const sq = 1 + 0.1 * wobble(q - T.land + F * 0.5, 3.2, 8) + (fast ? 0.06 : 0);
          live.position.set(mv * U, hy * 0.07, 0.006); live.scale.set(sq, 1 / sq, 1);
          ghost.visible = q >= HOPS[0];
          dots.forEach((d, i) => { const s = pop(q - T.dots - i * F, 0.2) * (i === 0 ? 1 + 0.25 * Math.abs(wobble(q - T.land, 3, 7)) : 1); show(d, s); d.position.y = gy(i ? 1 : 0) + (i === 0 ? hy * 0.1 : 0); });
          speed.visible = fast; speed.position.set(gx(mv - 2.6), gy(2.2), 0.012);
          const lx = q - T.land; hit.visible = lx >= 0 && lx < 2 * F - 1e-3; hit.position.set(gx(SHIFT), gy(0), 0.012); hit.scale.setScalar(lx < F - 1e-3 ? 0.85 : 1.15);

          // beat 4: glints on the moved curve
          ting.forEach((m, i) => { const x = q - T.ting - i * 2 * F; show(m, pop(x, 0.2) * (1 + 0.12 * Math.sin(n * 1.6 + i))); m.position.set(gx(i ? SHIFT + 2.5 : SHIFT - 1.6), gy(i ? 4.6 : 3.3), 0.014); });
          for (const f of labels) f(q);
        },
      };
    },

    // Effects only: the teacher's voice is mixed in by the renderer from `voice` above. Every time is a frame the picture changes on.
    sound(k) {
      k.bed('room', 0, D, { gain: 0.6 });
      k.play('stroke', T.draw0, { material: 'chalk', dur: T.draw1 - T.draw0, gain: 0.9, pan: -0.1 });
      k.play('pop', T.cap1, { gain: 0.7, f: 560, pan: -0.3, minor: true });
      k.play('whoosh', T.cut2 - F, { gain: 0.7, dur: 0.4, pan: 0.2, minor: true });
      k.play('paper', T.cap2, { gain: 0.8, dur: 0.16, pan: -0.2, minor: true });
      k.play('swish', T.arrow, { gain: 0.8, dur: 0.2 });
      for (let i = 0; i < 3; i++) k.play('tick', T.arrow + i * 2 * F, { gain: 0.8, f: 3600 + i * 500, minor: true });
      k.play('stamp', T.word, { gain: 0.9, pan: 0.2 });
      k.play('whoosh', T.cut3 - F, { gain: 0.6, dur: 0.4, pan: -0.2, minor: true });
      k.play('pop', T.dots, { gain: 0.6, f: 760, minor: true });
      HOPS.forEach((h, i) => { k.play('swish', h, { gain: 0.7, dur: 0.2, pan: -0.2 + i * 0.2 }); k.play('tock', h + HOP, { gain: i === 2 ? 1 : 0.6, f: 520 + i * 90, pan: -0.1 + i * 0.2 }); });
      k.play('thud', T.land, { gain: 0.5, f: 150 });
      k.play('whoosh', T.cut4 - F, { gain: 0.6, dur: 0.4, minor: true });
      k.play('stamp', T.cap4, { gain: 0.8 });
      k.play('ding', T.ting, { gain: 0.6, f: 'A6', pan: -0.1 }); k.play('ding', T.ting + 2 * F, { gain: 0.45, f: 'E7', pan: 0.2 });
    },
  });
}
