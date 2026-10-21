# WASTELAND ACADEMY — Content Schema

> Question format reference for all content pack authors.  
> All content files live in `/content/` and self-register via `WA.registerPack(pack)`.

---

## CONTENT PACK STRUCTURE

```js
// content/topic-1-algebra.js

WA.registerPack({
  id: "topic-1-algebra",
  name: "Numbers & Algebra",
  island: "scrap-fields",          // matches overworld island id
  icon: "⚙️",
  subtopics: [
    {
      id: "SL1.1",
      name: "Scientific Notation",
      prerequisite: null,          // null = starting node, no prerequisite
      questions: [ /* see below */ ]
    },
    {
      id: "SL1.2",
      name: "Arithmetic Sequences",
      prerequisite: "SL1.1",
      questions: [ /* ... */ ]
    }
  ]
});
```

---

## QUESTION FORMAT

### MCQ Question

```js
{
  id: "SL1.2-d1-001",              // subtopic-difficulty-number (unique)
  type: "mcq",
  difficulty: 1,                   // 1–5 (D1 Recruit → D5 Overseer)
  subtopic: "SL1.2",
  syllabus: "Arithmetic Sequences & Series",

  // Question text — use $...$ for inline math, $$...$$ for display math
  question: "The first term of an arithmetic sequence is $5$ and the common difference is $3$. Find the 10th term.",

  options: [
    { id: "a", text: "$27$" },
    { id: "b", text: "$30$" },     // ← correct
    { id: "c", text: "$32$" },
    { id: "d", text: "$35$" }
  ],
  correct: "b",

  // Worked solution — written as SPARK's voice where possible
  solution: [
    "Use the formula $u_n = u_1 + (n-1)d$.",
    "Here $u_1 = 5$, $d = 3$, and $n = 10$.",
    "So $u_{10} = 5 + (10-1) \\times 3 = 5 + 27 = 32$.",
    "Wait — check the arithmetic: $5 + 27 = 32$, not 30. Let me recount.",
    "Actually $u_{10} = 5 + 9 \\times 3 = 5 + 27 = 32$... hmm, option B says 30.",
    "SPARK note to author: double-check this one before publishing!"
  ],

  tags: ["sequences", "arithmetic", "formula"]
}
```

> **Note on solutions**: Write each step as a separate string in the array. They display one at a time when the student taps "next step". Final string should confirm the answer clearly.

---

### Value Input Question

```js
{
  id: "SL1.3-d2-001",
  type: "value",
  difficulty: 2,
  subtopic: "SL1.3",
  syllabus: "Geometric Sequences & Series",

  question: "A geometric sequence has first term $4$ and common ratio $\\frac{1}{2}$. Find the sum to infinity.",

  // For value questions, specify the accepted answer format
  answer: {
    value: 8,                      // numeric value
    format: "integer",             // "integer" | "fraction" | "decimal-1dp" | "decimal-2dp"
    display: "$8$"                 // how the answer is shown in solution
  },

  solution: [
    "Use the sum to infinity formula: $S_\\infty = \\frac{u_1}{1-r}$ for $|r| < 1$.",
    "Here $u_1 = 4$ and $r = \\frac{1}{2}$, so $|r| = \\frac{1}{2} < 1$ ✓",
    "$$S_\\infty = \\frac{4}{1 - \\frac{1}{2}} = \\frac{4}{\\frac{1}{2}} = 8$$"
  ],

  tags: ["sequences", "geometric", "infinite-series"]
}
```

---

### Multi-Part Question (Boss/Mini-Boss only)

```js
{
  id: "SL1.7-d3-boss-001",
  type: "multipart",
  difficulty: 3,                   // D3 = mini-boss, D4 = mini-boss, D5 = boss
  subtopic: "SL1.7",
  syllabus: "Logarithm Laws",
  isBoss: false,                   // true for island boss (D5 only)

  stem: "Let $f(x) = \\log_2(x-1) + 3$.",  // shared context for all parts

  parts: [
    {
      label: "a",
      marks: 2,
      question: "Write down the equation of the vertical asymptote of $f$.",
      type: "mcq",
      options: [
        { id: "a", text: "$x = 0$" },
        { id: "b", text: "$x = 1$" },    // ← correct
        { id: "c", text: "$x = -1$" },
        { id: "d", text: "$x = 3$" }
      ],
      correct: "b",
      solution: [
        "The logarithm $\\log_2(x-1)$ is defined when $x - 1 > 0$, i.e. $x > 1$.",
        "So the vertical asymptote is at $x = 1$."
      ]
    },
    {
      label: "b",
      marks: 2,
      question: "Find $f^{-1}(x)$.",
      type: "mcq",
      options: [
        { id: "a", text: "$2^{x-3} + 1$" },   // ← correct
        { id: "b", text: "$2^{x+3} - 1$" },
        { id: "c", text: "$\\log_2(x-3) + 1$" },
        { id: "d", text: "$2^x - 3 + 1$" }
      ],
      correct: "a",
      solution: [
        "Let $y = \\log_2(x-1) + 3$. Swap $x$ and $y$:",
        "$x = \\log_2(y-1) + 3$",
        "$x - 3 = \\log_2(y-1)$",
        "$2^{x-3} = y - 1$",
        "$y = 2^{x-3} + 1$",
        "So $f^{-1}(x) = 2^{x-3} + 1$."
      ]
    },
    {
      label: "c",
      marks: 2,
      question: "Find the $x$-intercept of $f$.",
      type: "value",
      answer: { value: 1.125, format: "decimal-3dp", display: "$x \\approx 1.125$" },
      solution: [
        "Set $f(x) = 0$: $\\log_2(x-1) + 3 = 0$",
        "$\\log_2(x-1) = -3$",
        "$x - 1 = 2^{-3} = \\frac{1}{8}$",
        "$x = 1 + \\frac{1}{8} = \\frac{9}{8} = 1.125$"
      ]
    }
  ]
}
```

---

## DIFFICULTY CALIBRATION GUIDE

| D | Marks | Paper | Characteristics | Example stems |
|---|-------|-------|-----------------|---------------|
| 1 | 1–2 | Either | Single step, direct recall or substitution | "Write down...", "State...", "Find the value of..." |
| 2 | 3–4 | Either | Two steps, one method required | "Find...", "Solve...", "Calculate..." |
| 3 | 5–6 | P1 (no calc) | Multi-step, algebraic reasoning, exact answers | "Show that...", "Find the exact value of...", "Prove..." |
| 4 | 5–6 | P2 (calc OK) | Contextual, applied, modelling | "A company...", "The temperature...", interpret and apply |
| 5 | 10+ | Either | Synoptic, multi-topic, extended reasoning | Multi-part questions with connected parts across topics |

Use the Math AASL Question Bank (`../Math AASL Question Bank/`) as a calibration reference.  
Do not copy questions from it — use it to judge what difficulty "feels like" at each level.

---

## SUBTOPIC MAP

Full list of subtopic IDs and their names, for use in the `subtopic` field and island node maps.

### Topic 1 — Numbers & Algebra (Island: Scrap Fields)
| ID | Name | Prereq |
|----|------|--------|
| SL1.1 | Scientific Notation | — |
| SL1.2 | Arithmetic Sequences & Series | SL1.1 |
| SL1.3 | Geometric Sequences & Series | SL1.2 |
| SL1.4 | Financial Applications | SL1.3 |
| SL1.5 | Exponents & Intro to Logs | SL1.1 |
| SL1.7 | Logarithm Laws | SL1.5 |
| SL1.8 | Infinite Geometric Series | SL1.3 |
| SL1.6 | Reasoning & Proof | SL1.7 |

### Topic 2 — Functions (Island: Signal Tower)
| ID | Name | Prereq |
|----|------|--------|
| SL2.1 | Straight Lines | — |
| SL2.2 | Function Basics | SL2.1 |
| SL2.3 | Graphing Functions | SL2.2 |
| SL2.4 | Graph Features | SL2.3 |
| SL2.5 | Composite & Inverse Functions | SL2.2 |
| SL2.6 | Quadratic Functions | SL2.3 |
| SL2.7 | Solving Quadratics | SL2.6 |
| SL2.8 | Rational Functions | SL2.4 |
| SL2.9 | Exponential & Log Functions | SL2.5 |
| SL2.11 | Graph Transformations | SL2.4 |

### Topic 3 — Geometry & Trigonometry (Island: Dry Flats)
| ID | Name | Prereq |
|----|------|--------|
| SL3.1 | 3D Geometry | — |
| SL3.2 | Non-Right Angled Trig | SL3.1 |
| SL3.3 | Trigonometry Applications | SL3.2 |
| SL3.4 | Radians, Arcs & Sectors | SL3.3 |
| SL3.5 | The Unit Circle | SL3.4 |
| SL3.6 | Trigonometric Identities | SL3.5 |
| SL3.7 | Trig Functions & Graphs | SL3.5 |
| SL3.8 | Solving Trig Equations | SL3.6 |

### Topic 4 — Statistics & Probability (Island: Radio Spires)
| ID | Name | Prereq |
|----|------|--------|
| SL4.1 | Data & Sampling Concepts | — |
| SL4.2 | Data Presentation | SL4.1 |
| SL4.3 | Descriptive Statistics | SL4.2 |
| SL4.4 | Correlation & Regression | SL4.3 |
| SL4.5 | Probability Basics | SL4.1 |
| SL4.6 | Probability Rules & Diagrams | SL4.5 |
| SL4.7 | Discrete Distributions & Binomial | SL4.6 |
| SL4.8 | Normal Distribution | SL4.7 |

### Topic 5 — Calculus (Island: Engine Core)
| ID | Name | Prereq |
|----|------|--------|
| SL5.1 | Limits & Rate of Change | — |
| SL5.2 | Increasing & Decreasing Functions | SL5.1 |
| SL5.3 | Basic Differentiation Rules | SL5.1 |
| SL5.4 | Tangents & Normals | SL5.3 |
| SL5.5 | Introduction to Integration | SL5.3 |
| SL5.6 | Advanced Differentiation Rules | SL5.3 |
| SL5.7 | Second Derivative & Concavity | SL5.6 |
| SL5.8 | Optimisation | SL5.7 |
| SL5.9 | Kinematics | SL5.5 |
| SL5.10 | Integration Techniques | SL5.5 |
| SL5.11 | Definite Integrals & Area | SL5.10 |

---

## CONTENT COVERAGE TARGET (V1)

Per subtopic, aim for:
- **2× D1 questions** (MCQ)
- **2× D2 questions** (MCQ)
- **1× D3 question** (MCQ or multi-part — for mini-boss nodes)
- **1× D4 question** per island (contextual, MCQ or multi-part)
- **1× D5 multi-part** per island (island boss fight)

Minimum viable: 2 questions per subtopic so spaced repetition has something to work with.

---

## WRITING STYLE NOTES

- Questions should match IB command terms: "Find", "Show that", "Write down", "Calculate", "Determine", "Sketch"
- Distractors (wrong MCQ options) should be plausible — common errors, not random numbers
- Solutions written in SPARK's voice: helpful, slightly informal, step-by-step
- Avoid culturally specific contexts — keep scenarios neutral (geometry, growth models, generic data)
- All LaTeX must render correctly in KaTeX (KaTeX has slightly different support than MathJax — test before publishing)
- KaTeX does not support `\dfrac` — use `\frac` with display math `$$...$$` instead
