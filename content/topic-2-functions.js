WA.registerPack({
  id:     'topic-2-functions',
  island: 'topic-2-functions',
  name:   'Signal Tower',
  topic:  'Functions',

  subtopics: [

    // ── SL2.2 Functions — domain, range, composite, inverse ───
    {
      id: 'sl2-2-functions',
      name: 'Functions: Notation & Basics',
      questions: [
        {
          id: 'sl2-2-gen-eval', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            const a = QGen.nonzero(-5,5), b = QGen.int(-6,6), x = QGen.int(-4,4);
            return { a, b, x, ans: a*x + b };
          },
          question: p => `Given $f(x) = ${QGen.poly([[p.a,'x'],[p.b,'']])}$, find $f(${p.x})$.`,
          answer:   p => p.ans,
          tolerance: 0,
          hint:  p => `Substitute $x = ${p.x}$ directly: $f(${p.x}) = ${p.a}(${p.x})${QGen.signed(p.b)}$.`,
          worked_solution: p => `$${QGen.chain(`f(${p.x})`, `${p.a}(${p.x})${QGen.signed(p.b)}`, `${p.a*p.x}${QGen.signed(p.b)}`, p.ans)}$`,
        },
        {
          id: 'sl2-2-inverse', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            // |a| >= 2 and b != 0, so no wrong option simplifies to the answer
            const a = QGen.pick([-4,-3,-2,2,3,4]), b = QGen.nonzero(-8,8);
            const over = (num, d) => d < 0 ? `-\\dfrac{${num}}{${-d}}` : `\\dfrac{${num}}{${d}}`;
            return { a, b, f: QGen.poly([[a,'x'],[b,'']]), inv: over(`x${QGen.signed(-b)}`, a), over };
          },
          question: p => `Find $f^{-1}(x)$ where $f(x) = ${p.f}$.`,
          outputType: 'mcq',
          mcqDistractors(p) {
            return [
              p.over(`x${QGen.signed(p.b)}`, p.a),                 // sign slip
              `${QGen.frac(1, p.a, 'x')}${QGen.signed(-p.b)}`,     // divided only the x term by a
              QGen.poly([[p.a,'x'],[-p.b,'']]),                    // multiplied instead of dividing
              `\\dfrac{1}{${p.f}}`,                               // reciprocal, not inverse
            ];
          },
          answer: p => p.inv,
          hint: p => `Let $y = ${p.f}$. Swap $x$ and $y$, then solve for $y$.`,
          worked_solution: p => `$y = ${p.f}$ → swap: $x = ${QGen.poly([[p.a,'y'],[p.b,'']])}$ → $${p.a}y = x${QGen.signed(-p.b)}$ → $y = ${p.inv}$`,
        },
        {
          id: 'sl2-2-composite', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            const a = QGen.nonzero(-3,4), b = QGen.int(-5,5);
            const c = QGen.nonzero(-3,3), d = QGen.int(-5,5);
            const x = QGen.int(-3,3);
            const gx = c*x + d;
            const ans = a*(gx) + b;
            return { a, b, c, d, x, gx, ans };
          },
          question: p => `$f(x) = ${QGen.poly([[p.a,'x'],[p.b,'']])}$ and $g(x) = ${QGen.poly([[p.c,'x'],[p.d,'']])}$. Find $(f \\circ g)(${p.x})$.`,
          answer: p => p.ans,
          tolerance: 0,
          hint: p => `$(f \\circ g)(x) = f(g(x))$. First compute $g(${p.x}) = ${p.gx}$, then apply $f$.`,
          worked_solution: p => `$${QGen.chain(`g(${p.x})`, `${p.c}(${p.x})${QGen.signed(p.d)}`, p.gx)}$. Then $${QGen.chain(`f(${p.gx})`, `${p.a}(${p.gx})${QGen.signed(p.b)}`, p.ans)}$.`,
        },
        {
          id: 'sl2-2-domain', type: 'mcq', difficulty: 2,
          question: 'What is the domain of $f(x) = \\sqrt{x - 3}$?',
          options: ['$x \\geq 0$', '$x \\geq 3$', '$x > 3$', '$x \\in \\mathbb{R}$'],
          correctIndex: 1,
          hint: 'The expression under the square root must be $\\geq 0$. Solve $x - 3 \\geq 0$.',
          worked_solution: '$x - 3 \\geq 0 \\Rightarrow x \\geq 3$. Domain: $[3, \\infty)$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── SL2.4 Quadratic functions ──────────────────────────────
    {
      id: 'sl2-4-quadratic',
      name: 'Quadratic Functions',
      questions: [
        {
          id: 'sl2-4-vertex', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            const h = QGen.int(-5,5), k = QGen.int(-8,8), a = QGen.nonzero(-3,3);
            const sq = h === 0 ? 'x^2' : `(x${QGen.signed(-h)})^2`;
            const f = `${a === 1 ? '' : a === -1 ? '-' : a}${sq}${QGen.signed(k)}`;
            return { h, k, a, f };
          },
          question: p => `The graph of $f(x) = ${p.f}$ is a parabola. What is the $x$-coordinate of its vertex?`,
          answer: p => p.h,
          tolerance: 0,
          hint: p => `The vertex form $a(x-h)^2 + k$ has its vertex at $(h, k)$. Watch the sign inside the bracket.`,
          worked_solution: p => `$f(x) = ${p.f}$ is in the form $a(x-h)^2 + k$ with $h = ${p.h}$ and $k = ${p.k}$. The vertex is $(${p.h}, ${p.k})$, so its $x$-coordinate is $${p.h}$.`,
        },
        {
          id: 'sl2-4-discrim', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            // Guarantee integer discriminant
            const a = QGen.nonzero(-2, 3);
            const b = QGen.int(-6, 6);
            const c = QGen.int(-8, 8);
            const disc = b*b - 4*a*c;
            return { a, b, c, disc };
          },
          question: p => `For $f(x) = ${QGen.poly([[p.a,'x^2'],[p.b,'x'],[p.c,'']])}$, calculate the discriminant $\\Delta = b^2 - 4ac$.`,
          answer: p => p.disc,
          tolerance: 0,
          hint: p => `Here $a = ${p.a}$, $b = ${p.b}$, $c = ${p.c}$. $\\Delta = ${QGen.tex(p.b)}^2 - 4(${p.a})(${p.c})$`,
          worked_solution: p => `$${QGen.chain('\\Delta', `${QGen.tex(p.b)}^2 - 4(${p.a})(${p.c})`, `${p.b*p.b}${QGen.signed(-4*p.a*p.c)}`, p.disc)}$`,
        },
        {
          id: 'sl2-4-roots', type: 'mcq', difficulty: 2,
          question: 'Solve $x^2 - 5x + 6 = 0$.',
          options: ['$x = 2$ or $x = 3$', '$x = -2$ or $x = -3$', '$x = 1$ or $x = 6$', '$x = 2$ or $x = -3$'],
          correctIndex: 0,
          hint: 'Factorise: find two numbers that multiply to $6$ and add to $-5$.',
          worked_solution: '$(x-2)(x-3) = 0 \\Rightarrow x = 2$ or $x = 3$.',
          spark_mood: 'happy',
        },
        {
          id: 'sl2-4-axis', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const a = QGen.nonzero(-3,3), b = QGen.int(-8,8), c = QGen.int(-10,10);
            // axis of symmetry = -b/(2a)
            // make it nice: b = 2*a*n for integer n
            const n = QGen.int(-4,4);
            const bNice = 2*a*n;
            return { a, b: bNice, c, axis: -n };
          },
          question: p => `Find the axis of symmetry of $f(x) = ${QGen.poly([[p.a,'x^2'],[p.b,'x'],[p.c,'']])}$. Enter the value of $x$.`,
          answer: p => p.axis,
          tolerance: 0.01,
          hint: p => `Axis of symmetry: $x = -\\dfrac{b}{2a} = -\\dfrac{${p.b}}{2(${p.a})}$`,
          worked_solution: p => `$x = -\\dfrac{b}{2a} = -\\dfrac{${p.b}}{2(${p.a})} = ${p.axis}$`,
        },
      ],
    },

    // ── SL2.5 Exponential & logarithmic functions ─────────────
    {
      id: 'sl2-5-explog',
      name: 'Exponential & Log Functions',
      questions: [
        {
          id: 'sl2-5-expgrowth', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const a = QGen.int(50,500) * 10;  // nice initial value
            const r = QGen.float(1.05,1.25,2); // growth factor
            const t = QGen.int(2,8);
            const ans = parseFloat((a * Math.pow(r,t)).toFixed(0));
            return { a, r, t, ans };
          },
          question: p => `A population of ${p.a} grows by a factor of $${p.r}$ each year. What is the population after ${p.t} years? (Give your answer to the nearest whole number.)`,
          answer: p => p.ans,
          tolerance: 0.005,
          hint: p => `Use $P = P_0 \\times r^t$ with $P_0 = ${p.a}$, $r = ${p.r}$, $t = ${p.t}$.`,
          worked_solution: p => `$P = ${p.a} \\times ${p.r}^{${p.t}} = ${p.a} \\times ${parseFloat(Math.pow(p.r,p.t).toFixed(4))} \\approx ${p.ans}$`,
        },
        {
          id: 'sl2-5-logsolve', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const base = QGen.pick([2,3,5,10]);
            const n = QGen.int(1,4);
            const ans = Math.pow(base, n);
            return { base, n, ans };
          },
          question: p => `Solve $\\log_{${p.base}} x = ${p.n}$`,
          answer: p => p.ans,
          tolerance: 0,
          hint: p => `$\\log_{${p.base}} x = ${p.n}$ means $${p.base}^{${p.n}} = x$.`,
          worked_solution: p => `$x = ${p.base}^{${p.n}} = ${p.ans}$`,
        },
        {
          id: 'sl2-5-natlog', type: 'mcq', difficulty: 3,
          question: 'Solve $e^{2x} = 7$ for $x$. Give your answer in exact form.',
          options: ['$x = \\dfrac{\\ln 7}{2}$', '$x = \\dfrac{7}{2e}$', '$x = 2\\ln 7$', '$x = \\ln\\dfrac{7}{2}$'],
          correctIndex: 0,
          hint: 'Take $\\ln$ of both sides: $2x = \\ln 7$.',
          worked_solution: '$\\ln(e^{2x}) = \\ln 7 \\Rightarrow 2x = \\ln 7 \\Rightarrow x = \\dfrac{\\ln 7}{2}$. Careful: $\\ln\\dfrac{7}{2} = \\ln 7 - \\ln 2$, which is not the same.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── SL2.8 Transformations of graphs ──────────────────────
    {
      id: 'sl2-8-transformations',
      name: 'Graph Transformations',
      questions: [
        {
          id: 'sl2-8-translate', type: 'mcq', difficulty: 2,
          question: 'The graph of $y = f(x)$ is translated by $\\begin{pmatrix}3 \\\\ -2\\end{pmatrix}$. What is the new equation?',
          options: ['$y = f(x-3) - 2$', '$y = f(x+3) + 2$', '$y = f(x-3) + 2$', '$y = f(x+3) - 2$'],
          correctIndex: 0,
          hint: 'A translation of $\\binom{a}{b}$ replaces $x$ with $(x-a)$ and adds $b$ to $y$.',
          worked_solution: 'Translation $\\binom{3}{-2}$: replace $x$ with $(x-3)$, subtract $2$ from $y$. Result: $y = f(x-3) - 2$.',
          spark_mood: 'thinking',
        },
        {
          id: 'sl2-8-stretch', type: 'mcq', difficulty: 2,
          question: 'Which transformation maps $y = \\sin x$ to $y = 3\\sin(2x)$?',
          options: [
            'Stretch scale factor $3$ in $y$-direction and stretch scale factor $\\frac{1}{2}$ in $x$-direction',
            'Stretch scale factor $3$ in $y$-direction and stretch scale factor $2$ in $x$-direction',
            'Translation $\\binom{2}{3}$',
            'Stretch scale factor $\\frac{1}{3}$ in $y$-direction'
          ],
          correctIndex: 0,
          hint: '$y = a\\,f(bx)$: scale factor $a$ in $y$, scale factor $\\frac{1}{b}$ in $x$.',
          worked_solution: '$a=3$ gives stretch $\\times 3$ in $y$-direction. $b=2$ gives stretch $\\times \\frac{1}{2}$ in $x$-direction (halving the period).',
          spark_mood: 'thinking',
        },
        {
          id: 'sl2-8-reflect', type: 'mcq', difficulty: 2,
          question: 'What is the equation of $y = x^2 + 1$ reflected in the $x$-axis?',
          options: ['$y = -x^2 - 1$', '$y = x^2 - 1$', '$y = -x^2 + 1$', '$y = (-x)^2 + 1$'],
          correctIndex: 0,
          hint: 'Reflection in the $x$-axis: replace $y$ with $-y$, i.e. negate the whole function.',
          worked_solution: 'Reflecting $y = x^2 + 1$ in the $x$-axis gives $y = -(x^2 + 1) = -x^2 - 1$.',
          spark_mood: 'happy',
        },
      ],
    },

    // ── Boss question: mixed functions ───────────────────────
    {
      id: 'sl2-boss',
      name: 'Boss: Signal Tower',
      questions: [
        {
          id: 'sl2-boss-1', type: 'boss', difficulty: 5,
          title: 'Signal Tower Warlord',
          intro: 'The Warlord blocks the tower. Three stages to bring it down.',
          parts: [
            {
              type: 'value',
              question: 'Let $f(x) = 2x^2 - 8x + 6$. Find the zeros of $f$. Enter the smaller one.',
              answer: 1,  // smaller root
              tolerance: 0,
              hint: 'Factorise or use the quadratic formula. $2(x^2-4x+3) = 2(x-1)(x-3)$.',
              worked_solution: '$2(x-1)(x-3)=0 \\Rightarrow x=1$ or $x=3$. Enter the smaller root.',
              marks: 3,
              followThrough: true,
            },
            {
              type: 'value',
              question: '(Using your roots) Find the $x$-coordinate of the vertex of $f(x) = 2x^2 - 8x + 6$.',
              answer: 2,
              tolerance: 0,
              hint: 'The vertex lies halfway between the roots. $x_{\\text{vertex}} = \\dfrac{x_1 + x_2}{2}$.',
              worked_solution: '$x_{\\text{vertex}} = \\dfrac{1+3}{2} = 2$',
              marks: 2,
              followThrough: true,
            },
            {
              type: 'value',
              question: 'Find the minimum value of $f(x) = 2x^2 - 8x + 6$.',
              answer: -2,
              tolerance: 0,
              hint: 'Substitute $x = 2$ (the vertex $x$-coordinate) into $f(x)$.',
              worked_solution: '$f(2) = 2(4) - 8(2) + 6 = 8 - 16 + 6 = -2$',
              marks: 2,
              followThrough: true,
            },
          ],
          spark_mood: 'surprised',
        },
      ],
    },

  ], // end subtopics
});
