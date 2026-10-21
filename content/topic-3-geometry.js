WA.registerPack({
  id:     'topic-3-geometry',
  island: 'topic-3-geometry',
  name:   'Dry Flats',
  topic:  'Geometry & Trigonometry',

  subtopics: [

    // ── SL3.2 Right-angle trigonometry ────────────────────────
    {
      id: 'sl3-2-right-trig',
      name: 'Right-Angle Trigonometry',
      questions: [
        {
          id: 'sl3-2-soh', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            // Choose a Pythagorean triple
            const triples = [[3,4,5],[5,12,13],[8,15,17],[7,24,25],[6,8,10],[9,12,15]];
            const [a,b,c] = QGen.pick(triples);
            const angle = QGen.pick(['opposite','adjacent']);
            const hyp = c;
            const opp = a, adj = b;
            const sinA = parseFloat((opp/hyp).toFixed(4));
            return { opp, adj, hyp, sinA };
          },
          question: p => `In a right-angled triangle, the opposite side is ${p.opp} and the hypotenuse is ${p.hyp}. Find $\\sin\\theta$ as a fraction.`,
          outputType: 'mcq',
          mcqDistractors(params) {
            return [`\\dfrac{${params.adj}}{${params.hyp}}`, `\\dfrac{${params.opp}}{${params.adj}}`, `\\dfrac{${params.hyp}}{${params.opp}}`];
          },
          answer: p => `\\dfrac{${p.opp}}{${p.hyp}}`,
          hint: p => `SOH: $\\sin\\theta = \\dfrac{\\text{opposite}}{\\text{hypotenuse}} = \\dfrac{${p.opp}}{${p.hyp}}$`,
          worked_solution: p => `$\\sin\\theta = \\dfrac{\\text{opp}}{\\text{hyp}} = \\dfrac{${p.opp}}{${p.hyp}}$`,
        },
        {
          id: 'sl3-2-findangle', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            const triples = [[3,4,5],[5,12,13],[8,15,17],[7,24,25]];
            const [a,b,c] = QGen.pick(triples);
            const angle = parseFloat((Math.atan2(a,b) * 180 / Math.PI).toFixed(1));
            return { opp: a, adj: b, hyp: c, angle };
          },
          question: p => `In a right-angled triangle, the opposite side is ${p.opp} and the adjacent side is ${p.adj}. Find the angle $\\theta$ (in degrees, to 1 d.p.).`,
          answer: p => p.angle,
          tolerance: 0.2,
          hint: p => `Use $\\tan\\theta = \\dfrac{\\text{opp}}{\\text{adj}} = \\dfrac{${p.opp}}{${p.adj}}$, then $\\theta = \\tan^{-1}\\!\\left(\\dfrac{${p.opp}}{${p.adj}}\\right)$.`,
          worked_solution: p => `$\\theta = \\tan^{-1}\\!\\left(\\dfrac{${p.opp}}{${p.adj}}\\right) = ${p.angle}°$`,
        },
        {
          id: 'sl3-2-findside', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const hyp = QGen.int(8,20);
            const deg = QGen.pick([30,45,60]);
            const rad = deg * Math.PI / 180;
            const opp = parseFloat((hyp * Math.sin(rad)).toFixed(2));
            return { hyp, deg, opp };
          },
          question: p => `In a right-angled triangle with hypotenuse ${p.hyp} cm and angle $${p.deg}°$, find the opposite side (to 2 d.p.).`,
          answer: p => p.opp,
          tolerance: 0.02,
          hint: p => `$\\sin ${p.deg}° = \\dfrac{\\text{opp}}{${p.hyp}}$, so $\\text{opp} = ${p.hyp} \\times \\sin ${p.deg}°$.`,
          worked_solution: p => `$\\text{opp} = ${p.hyp} \\times \\sin ${p.deg}° = ${p.hyp} \\times ${parseFloat(Math.sin(p.deg*Math.PI/180).toFixed(4))} = ${p.opp}$ cm`,
        },
      ],
    },

    // ── SL3.3 Non-right trigonometry ──────────────────────────
    {
      id: 'sl3-3-nrt',
      name: 'Sine & Cosine Rules',
      questions: [
        {
          id: 'sl3-3-sinerule', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const A = QGen.int(25,55), B = QGen.int(40,80);
            const C = 180 - A - B;
            const a = QGen.int(6,15);
            const b = parseFloat((a * Math.sin(B*Math.PI/180) / Math.sin(A*Math.PI/180)).toFixed(2));
            return { A, B, C, a, b };
          },
          question: p => `In triangle $ABC$, angle $A = ${p.A}°$, angle $B = ${p.B}°$ and side $a = ${p.a}$ cm. Find side $b$ (to 2 d.p.).`,
          answer: p => p.b,
          tolerance: 0.05,
          hint: p => `Sine rule: $\\dfrac{b}{\\sin B} = \\dfrac{a}{\\sin A}$. So $b = \\dfrac{${p.a} \\times \\sin ${p.B}°}{\\sin ${p.A}°}$.`,
          worked_solution: p => `$b = \\dfrac{${p.a} \\sin ${p.B}°}{\\sin ${p.A}°} = ${p.b}$ cm`,
        },
        {
          id: 'sl3-3-cosinerule-side', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const b = QGen.int(5,12), c = QGen.int(5,12), A = QGen.int(30,120);
            const a = parseFloat(Math.sqrt(b*b + c*c - 2*b*c*Math.cos(A*Math.PI/180)).toFixed(2));
            return { a, b, c, A };
          },
          question: p => `In triangle $ABC$, $b = ${p.b}$ cm, $c = ${p.c}$ cm and $\\angle A = ${p.A}°$. Find side $a$ (to 2 d.p.).`,
          answer: p => p.a,
          tolerance: 0.05,
          hint: p => `Cosine rule: $a^2 = b^2 + c^2 - 2bc\\cos A = ${p.b}^2 + ${p.c}^2 - 2(${p.b})(${p.c})\\cos ${p.A}°$`,
          worked_solution: p => `$a^2 = ${p.b*p.b} + ${p.c*p.c} - ${2*p.b*p.c} \\times ${parseFloat(Math.cos(p.A*Math.PI/180).toFixed(4))} = ${parseFloat((p.a*p.a).toFixed(2))}$ so $a = ${p.a}$ cm`,
        },
        {
          id: 'sl3-3-area', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const a = QGen.int(5,14), b = QGen.int(5,14), C = QGen.int(25,120);
            const area = parseFloat((0.5*a*b*Math.sin(C*Math.PI/180)).toFixed(2));
            return { a, b, C, area };
          },
          question: p => `Find the area of triangle $ABC$ where $a = ${p.a}$ cm, $b = ${p.b}$ cm and $\\angle C = ${p.C}°$. Give your answer to 2 d.p.`,
          answer: p => p.area,
          tolerance: 0.05,
          hint: p => `Area $= \\dfrac{1}{2}ab\\sin C = \\dfrac{1}{2}(${p.a})(${p.b})\\sin ${p.C}°$`,
          worked_solution: p => `Area $= \\dfrac{1}{2}(${p.a})(${p.b})\\sin ${p.C}° = ${p.area}$ cm²`,
        },
      ],
    },

    // ── SL3.4 Radians, arc length, sector area ────────────────
    {
      id: 'sl3-4-radians',
      name: 'Radians, Arcs & Sectors',
      questions: [
        {
          id: 'sl3-4-arc', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const r = QGen.int(4,12), theta = QGen.pick([0.5,1,1.2,1.5,2,2.5]);
            const arc = parseFloat((r*theta).toFixed(2));
            return { r, theta, arc };
          },
          question: p => `A sector has radius $${p.r}$ cm and angle $${p.theta}$ radians. Find the arc length (to 2 d.p.).`,
          answer: p => p.arc,
          tolerance: 0.02,
          hint: p => `Arc length $l = r\\theta = ${p.r} \\times ${p.theta}$.`,
          worked_solution: p => `$l = ${p.r} \\times ${p.theta} = ${p.arc}$ cm`,
        },
        {
          id: 'sl3-4-sector', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const r = QGen.int(4,12), theta = QGen.pick([0.5,1,1.2,1.5,2]);
            const area = parseFloat((0.5*r*r*theta).toFixed(2));
            return { r, theta, area };
          },
          question: p => `Find the area of a sector with radius $${p.r}$ cm and angle $${p.theta}$ radians. Give your answer to 2 d.p.`,
          answer: p => p.area,
          tolerance: 0.02,
          hint: p => `Area $= \\dfrac{1}{2}r^2\\theta = \\dfrac{1}{2}(${p.r})^2(${p.theta})$`,
          worked_solution: p => `$A = \\dfrac{1}{2}(${p.r})^2(${p.theta}) = \\dfrac{1}{2}(${p.r*p.r})(${p.theta}) = ${p.area}$ cm²`,
        },
        {
          id: 'sl3-4-rad-deg', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            // The numpad has no π key, so the player enters k where the angle is kπ
            const degs = [30,45,60,90,120,135,150,180,270,360];
            const deg = QGen.pick(degs);
            const g = QGen._gcd(deg, 180);
            const num = deg / g, den = 180 / g;
            return { deg, num, den, k: num / den, kTex: QGen.frac(num, den, '\\pi') };
          },
          question: p => `Convert $${p.deg}°$ to radians, as a multiple of $\\pi$. Enter $k$, where the angle is $k\\pi$ (a fraction such as 3/4 is fine).`,
          answer: p => p.k,
          tolerance: 0.005,
          hint: p => `Multiply by $\\dfrac{\\pi}{180}$: $${p.deg}° \\times \\dfrac{\\pi}{180}$, then simplify the fraction.`,
          worked_solution: p => `$${p.deg} \\times \\dfrac{\\pi}{180} = \\dfrac{${p.deg}}{180}\\pi = ${p.kTex}$, so $k = ${QGen.frac(p.num, p.den)}$${p.den === 1 ? '' : ` (about $${p.k.toFixed(4).replace(/0+$/, '')}$)`}.`,
        },
      ],
    },

    // ── Boss: multi-part trig problem ────────────────────────
    {
      id: 'sl3-boss',
      name: 'Boss: Dry Flats',
      questions: [
        {
          id: 'sl3-boss-1', type: 'boss', difficulty: 5,
          title: 'The Enforcer of the Flats',
          intro: 'Three-part battle. Navigate the terrain.',
          parts: [
            {
              type: 'value',
              question: 'In triangle $PQR$, $PQ = 8$ m, $QR = 5$ m and $\\angle PQR = 60°$. Find $PR$ using the cosine rule. Give your answer to 3 significant figures.',
              answer: parseFloat(Math.sqrt(64 + 25 - 2*8*5*Math.cos(Math.PI/3)).toFixed(3)),
              tolerance: 0.01,
              hint: '$PR^2 = PQ^2 + QR^2 - 2 \\cdot PQ \\cdot QR \\cdot \\cos(\\angle PQR)$',
              worked_solution: '$PR^2 = 64 + 25 - 80\\cos60° = 89 - 40 = 49$, so $PR = 7$ m.',
              marks: 3, followThrough: true,
            },
            {
              type: 'value',
              question: 'Using your value of $PR$ (or 7 m), find $\\angle QPR$ in degrees using the sine rule. Give to 1 d.p.',
              answer: parseFloat((Math.asin(5*Math.sin(Math.PI/3)/7)*180/Math.PI).toFixed(1)),
              tolerance: 0.2,
              hint: '$\\dfrac{\\sin(\\angle QPR)}{QR} = \\dfrac{\\sin(\\angle PQR)}{PR}$',
              worked_solution: '$\\sin(\\angle QPR) = \\dfrac{5\\sin60°}{7} \\approx 0.6186$, so $\\angle QPR \\approx 38.2°$.',
              marks: 3, followThrough: true,
            },
            {
              type: 'value',
              question: 'Find the area of triangle $PQR$ (using original values $PQ=8$, $QR=5$, $\\angle PQR=60°$). Give to 2 d.p.',
              answer: parseFloat((0.5*8*5*Math.sin(Math.PI/3)).toFixed(2)),
              tolerance: 0.05,
              hint: 'Area $= \\dfrac{1}{2} \\cdot PQ \\cdot QR \\cdot \\sin(\\angle PQR)$',
              worked_solution: 'Area $= \\dfrac{1}{2}(8)(5)\\sin 60° = 20 \\times \\dfrac{\\sqrt{3}}{2} \\approx 17.32$ m².',
              marks: 2, followThrough: false,
            },
          ],
          spark_mood: 'surprised',
        },
      ],
    },

  ],
});
