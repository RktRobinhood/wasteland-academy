WA.registerPack({
  id:     'topic-5-calculus',
  island: 'topic-5-calculus',
  name:   'Engine Core',
  topic:  'Calculus',

  subtopics: [

    // ── SL5.2 Derivatives — power rule ───────────────────────
    {
      id: 'sl5-2-differentiation',
      name: 'Basic Differentiation',
      questions: [
        {
          id: 'sl5-2-power', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            const n = QGen.int(2,6), a = QGen.nonzero(-5,5);
            return { n, a, coeff: a*n, pow: n-1 };
          },
          question: p => `Differentiate $f(x) = ${p.a}x^{${p.n}}$.`,
          outputType: 'mcq',
          mcqDistractors(params) {
            const { a, n } = params;
            return [`${a*(n+1)}x^{${n}}`, `${a}x^{${n+1}}`, `${a*(n-1)}x^{${n-2}}`];
          },
          answer: p => `${p.coeff}x^{${p.pow}}`,
          hint: p => `Power rule: $\\dfrac{d}{dx}[ax^n] = anx^{n-1}$. Here $a=${p.a}$, $n=${p.n}$.`,
          worked_solution: p => `$f'(x) = ${p.a} \\times ${p.n} \\cdot x^{${p.n}-1} = ${p.coeff}x^{${p.pow}}$`,
        },
        {
          id: 'sl5-2-poly', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            const a = QGen.nonzero(-4,4), b = QGen.nonzero(-5,5), c = QGen.int(-8,8);
            const x = QGen.int(-3,4);
            const dyDx = 3*a*x*x + 2*b*x + c;
            return { a, b, c, x, dyDx };
          },
          question: p => `Find $f'(${p.x})$ where $f(x) = ${p.a}x^3 + ${p.b}x^2 + ${p.c}x$.`,
          answer: p => p.dyDx,
          tolerance: 0,
          hint: p => `First differentiate: $f'(x) = ${3*p.a}x^2 + ${2*p.b}x + ${p.c}$. Then substitute $x = ${p.x}$.`,
          worked_solution: p => `$f'(x) = ${3*p.a}x^2 + ${2*p.b}x + ${p.c}$. $f'(${p.x}) = ${3*p.a}(${p.x})^2 + ${2*p.b}(${p.x}) + ${p.c} = ${p.dyDx}$`,
        },
        {
          id: 'sl5-2-chain', type: 'mcq', difficulty: 3,
          question: 'Find $\\dfrac{dy}{dx}$ where $y = (3x^2 + 1)^4$.',
          options: ['$24x(3x^2+1)^3$', '$4(3x^2+1)^3$', '$24x(3x^2+1)^4$', '$12x(3x^2+1)^3$'],
          correctIndex: 0,
          hint: 'Chain rule: $\\dfrac{dy}{dx} = 4(3x^2+1)^3 \\cdot \\dfrac{d}{dx}(3x^2+1)$.',
          worked_solution: '$\\dfrac{dy}{dx} = 4(3x^2+1)^3 \\cdot 6x = 24x(3x^2+1)^3$',
          spark_mood: 'thinking',
        },
        {
          id: 'sl5-2-product', type: 'mcq', difficulty: 4,
          question: 'Differentiate $y = x^2 \\ln x$.',
          options: ['$x(2\\ln x + 1)$', '$2x\\ln x$', '$\\dfrac{x^2}{x} + 2x$', '$2x + \\dfrac{1}{x}$'],
          correctIndex: 0,
          hint: 'Product rule: $(uv)\\prime = u\\prime v + uv\\prime$ with $u = x^2$, $v = \\ln x$.',
          worked_solution: '$u = x^2, u\\prime = 2x; \\ v = \\ln x, v\\prime = \\dfrac{1}{x}$. So $y\\prime = 2x\\ln x + x^2 \\cdot \\dfrac{1}{x} = 2x\\ln x + x = x(2\\ln x + 1)$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── SL5.4 Applications of differentiation ────────────────
    {
      id: 'sl5-4-applications',
      name: 'Applications of Derivatives',
      questions: [
        {
          id: 'sl5-4-tangent', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const a = QGen.nonzero(-3,4), b = QGen.int(-6,6);
            const x0 = QGen.int(-3,4);
            const y0 = a*x0*x0 + b;
            const m = 2*a*x0;
            const c = y0 - m*x0;
            return { a, b, x0, y0, m, c };
          },
          question: p => `Find the equation of the tangent to $y = ${p.a}x^2 + ${p.b}$ at $x = ${p.x0}$.`,
          outputType: 'mcq',
          mcqDistractors(params) {
            const { m, c } = params;
            return [`y = ${m}x + ${c+2}`, `y = ${m+2}x + ${c}`, `y = ${-m}x + ${c}`];
          },
          answer: p => `y = ${p.m}x + ${p.c}`,
          hint: p => `Gradient $= f'(${p.x0}) = 2(${p.a})(${p.x0}) = ${p.m}$. Point: $(${p.x0}, ${p.y0})$. Use $y - y_1 = m(x - x_1)$.`,
          worked_solution: p => `$f'(x) = ${2*p.a}x$; $m = ${p.m}$ at $x=${p.x0}$. Tangent: $y - ${p.y0} = ${p.m}(x - ${p.x0})$, so $y = ${p.m}x + ${p.c}$.`,
        },
        {
          id: 'sl5-4-stationary', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            // f(x) = ax^3 - 3a*h^2 * x + k  → f'(x) = 3ax^2 - 3a*h^2 = 3a(x^2-h^2) → roots at ±h
            const a = QGen.pick([1,2,-1,-2]);
            const h = QGen.int(1,4);
            const k = QGen.int(-10,10);
            // f(x) = ax^3 - 3ah^2 x + k
            const b = -3*a*h*h;
            const xMin = h * Math.sign(a) > 0 ? h : -h;  // stationary point
            return { a, h, k, b, xStat: h };
          },
          question: p => `Find the $x$-coordinates of the stationary points of $f(x) = ${p.a}x^3 + ${p.b}x + ${p.k}$.`,
          answer: p => p.xStat,
          tolerance: 0,
          hint: p => `Set $f'(x) = 0$: $f'(x) = ${3*p.a}x^2 + ${p.b} = 0$.`,
          worked_solution: p => `$f'(x) = ${3*p.a}x^2 + ${p.b} = 0 \\Rightarrow x^2 = ${p.h*p.h} \\Rightarrow x = \\pm ${p.h}$. Enter the positive root.`,
        },
        {
          id: 'sl5-4-incr', type: 'mcq', difficulty: 2,
          question: 'For $f(x) = x^2 - 4x + 3$, on which interval is $f$ decreasing?',
          options: ['$x < 2$', '$x > 2$', '$x < -2$', '$x > -2$'],
          correctIndex: 0,
          hint: '$f\\prime(x) = 2x - 4$. Set $f\\prime(x) < 0$: $2x - 4 < 0 \\Rightarrow x < 2$.',
          worked_solution: '$f\\prime(x) = 2x - 4 < 0 \\Rightarrow x < 2$. $f$ is decreasing for $x < 2$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── SL5.6 Integration ─────────────────────────────────────
    {
      id: 'sl5-6-integration',
      name: 'Indefinite Integration',
      questions: [
        {
          id: 'sl5-6-power', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const n = QGen.int(2,5), a = QGen.nonzero(-4,4);
            const num = a, den = n+1;
            const g = (x,y) => { let r=1; for(let d=2;d<=Math.min(x,y);d++) if(x%d===0&&y%d===0){r=d;} return r; };
            const gc = g(Math.abs(num),Math.abs(den));
            return { n, a, num: num/gc, den: den/gc };
          },
          question: p => `Find $\\displaystyle\\int ${p.a}x^{${p.n}}\\,dx$.`,
          outputType: 'mcq',
          mcqDistractors(params) {
            const { a, n } = params;
            const g = (x,y) => { let r=1; for(let d=2;d<=Math.min(Math.abs(x),Math.abs(y));d++) if(x%d===0&&y%d===0){r=d;} return r; };
            const gc1 = g(Math.abs(a), n+2);
            const gc2 = g(Math.abs(a), n);
            return [`\\dfrac{${a/gc1}}{${(n+2)/gc1}}x^{${n+2}} + C`, `${a*(n+1)}x^{${n+2}} + C`, `${a/g(Math.abs(a),n)}x^{${n-1}} + C`];
          },
          answer: p => `\\dfrac{${p.num}}{${p.den}}x^{${p.n+1}} + C`,
          hint: p => `Power rule: $\\int ax^n dx = \\dfrac{a}{n+1}x^{n+1} + C$.`,
          worked_solution: p => `$\\int ${p.a}x^{${p.n}}dx = \\dfrac{${p.a}}{${p.n+1}}x^{${p.n+1}} + C = \\dfrac{${p.num}}{${p.den}}x^{${p.n+1}} + C$`,
        },
        {
          id: 'sl5-6-definite', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const a = QGen.pick([1,2,3]), b = a + QGen.int(1,4);
            const n = QGen.int(2,3);
            // integral of x^n from a to b
            const ans = parseFloat((Math.pow(b,n+1)/(n+1) - Math.pow(a,n+1)/(n+1)).toFixed(2));
            return { a, b, n, ans };
          },
          question: p => `Evaluate $\\displaystyle\\int_{${p.a}}^{${p.b}} x^{${p.n}}\\,dx$.`,
          answer: p => p.ans,
          tolerance: 0.05,
          hint: p => `$\\left[\\dfrac{x^{${p.n+1}}}{${p.n+1}}\\right]_{${p.a}}^{${p.b}} = \\dfrac{${p.b}^{${p.n+1}}}{${p.n+1}} - \\dfrac{${p.a}^{${p.n+1}}}{${p.n+1}}$`,
          worked_solution: p => `$\\dfrac{${Math.pow(p.b,p.n+1)}}{${p.n+1}} - \\dfrac{${Math.pow(p.a,p.n+1)}}{${p.n+1}} = ${p.ans}$`,
        },
        {
          id: 'sl5-6-area', type: 'parametric',
          difficulty: 4, spark_mood: 'thinking',
          params() {
            // area under y = ax^2 from 0 to c
            const a = QGen.int(1,4), c = QGen.int(2,5);
            const area = parseFloat((a*Math.pow(c,3)/3).toFixed(2));
            return { a, c, area };
          },
          question: p => `Find the area enclosed between $y = ${p.a}x^2$, the $x$-axis and the line $x = ${p.c}$.`,
          answer: p => p.area,
          tolerance: 0.05,
          hint: p => `Area $= \\displaystyle\\int_0^{${p.c}} ${p.a}x^2\\,dx = \\left[\\dfrac{${p.a}}{3}x^3\\right]_0^{${p.c}}$`,
          worked_solution: p => `$\\dfrac{${p.a}}{3}(${p.c})^3 - 0 = \\dfrac{${p.a} \\times ${p.c**3}}{3} = ${p.area}$`,
        },
      ],
    },

    // ── SL5.8 Kinematics ─────────────────────────────────────
    {
      id: 'sl5-8-kinematics',
      name: 'Kinematics',
      questions: [
        {
          id: 'sl5-8-vel', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const a = QGen.int(1,4), b = QGen.int(-6,6), c = QGen.int(-10,10);
            const t = QGen.int(1,4);
            const v = 3*a*t*t + 2*b*t + c;
            return { a, b, c, t, v };
          },
          question: p => `A particle moves so its displacement is $s = ${p.a}t^3 + ${p.b}t^2 + ${p.c}t$ metres at time $t$ seconds. Find the velocity at $t = ${p.t}$ s.`,
          answer: p => p.v,
          tolerance: 0,
          hint: p => `Velocity $v = \\dfrac{ds}{dt} = ${3*p.a}t^2 + ${2*p.b}t + ${p.c}$. Substitute $t = ${p.t}$.`,
          worked_solution: p => `$v = ${3*p.a}t^2 + ${2*p.b}t + ${p.c}$. At $t=${p.t}$: $v = ${3*p.a}(${p.t})^2 + ${2*p.b}(${p.t}) + ${p.c} = ${p.v}$ m/s`,
        },
        {
          id: 'sl5-8-accel', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const a = QGen.nonzero(-3,4), b = QGen.int(-8,8);
            const t = QGen.int(1,5);
            const acc = 2*a;  // constant for at^2 + bt
            return { a, b, t, acc };
          },
          question: p => `Velocity of a particle: $v = ${p.a}t^2 + ${p.b}$. Find the acceleration.`,
          answer: p => p.acc * p.t,  // at t
          tolerance: 0,
          hint: p => `Acceleration $a = \\dfrac{dv}{dt}$. Differentiate $v = ${p.a}t^2 + ${p.b}$.`,
          worked_solution: p => `$a = \\dfrac{dv}{dt} = ${2*p.a}t$. The acceleration is ${2*p.a}t (not constant).`,
        },
        {
          id: 'sl5-8-rest', type: 'mcq', difficulty: 3,
          question: 'A particle has velocity $v = t^2 - 4t + 3$ m/s. When is the particle at rest?',
          options: ['$t = 1$ and $t = 3$', '$t = 0$ and $t = 4$', '$t = 2$ only', '$t = -1$ and $t = -3$'],
          correctIndex: 0,
          hint: 'At rest means $v = 0$. Solve $t^2 - 4t + 3 = 0$.',
          worked_solution: '$(t-1)(t-3) = 0 \\Rightarrow t = 1$ or $t = 3$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── Boss: multi-part calculus ────────────────────────────
    {
      id: 'sl5-boss',
      name: 'Boss: The Engine Core',
      questions: [
        {
          id: 'sl5-boss-1', type: 'boss', difficulty: 5,
          title: 'The Core Overseer',
          intro: 'The Overseer controls the Engine Core. Four-stage analysis — hold nothing back.',
          parts: [
            {
              type: 'value',
              question: 'Let $f(x) = x^3 - 6x^2 + 9x + 2$. Find $f\\prime(x)$ and determine the $x$-coordinates of the stationary points. Enter the larger $x$-value.',
              answer: 3,
              tolerance: 0,
              hint: '$f\\prime(x) = 3x^2 - 12x + 9 = 3(x^2 - 4x + 3) = 3(x-1)(x-3) = 0$',
              worked_solution: '$f\\prime(x) = 3x^2 - 12x + 9$. Setting $= 0$: $x = 1$ or $x = 3$. Larger value: $3$.',
              marks: 3, followThrough: true,
            },
            {
              type: 'value',
              question: 'Using $x = 3$ (or your larger stationary point), find the $y$-value at this point.',
              answer: 2,
              tolerance: 0,
              hint: 'Substitute $x = 3$: $f(3) = 27 - 54 + 27 + 2$.',
              worked_solution: '$f(3) = 27 - 54 + 27 + 2 = 2$.',
              marks: 2, followThrough: true,
            },
            {
              type: 'mcq',
              question: 'Use the second derivative to classify the stationary point at $x = 3$.',
              options: [
                'Local minimum: $f\\prime\\prime(3) > 0$',
                'Local maximum: $f\\prime\\prime(3) > 0$',
                'Local maximum: $f\\prime\\prime(3) < 0$',
                'Point of inflection: $f\\prime\\prime(3) = 0$'
              ],
              correctIndex: 0,
              hint: '$f\\prime\\prime(x) = 6x - 12$. Evaluate at $x = 3$.',
              worked_solution: '$f\\prime\\prime(3) = 18 - 12 = 6 > 0$. Since $f\\prime\\prime > 0$, it is a local minimum.',
              marks: 2, followThrough: false,
            },
            {
              type: 'value',
              question: 'Find the area enclosed between $f(x) = x^3 - 6x^2 + 9x + 2$, the $x$-axis, and the lines $x=1$ and $x=3$. Give to 2 d.p.',
              answer: parseFloat(Math.abs(
                (81/4 - 6*27/3 + 9*9/2 + 2*3) - (1/4 - 6/3 + 9/2 + 2*1)
              ).toFixed(2)),
              tolerance: 0.1,
              hint: 'Area $= \\left|\\displaystyle\\int_1^3 f(x)\\,dx\\right|$. Antiderivative: $\\dfrac{x^4}{4} - 2x^3 + \\dfrac{9x^2}{2} + 2x$.',
              worked_solution: '$\\left[\\dfrac{x^4}{4} - 2x^3 + \\dfrac{9x^2}{2} + 2x\\right]_1^3 = (\\tfrac{81}{4}-54+\\tfrac{81}{2}+6)-(\\tfrac{1}{4}-2+\\tfrac{9}{2}+2) = 4$ square units.',
              marks: 3, followThrough: true,
            },
          ],
          spark_mood: 'surprised',
        },
      ],
    },

  ],
});
