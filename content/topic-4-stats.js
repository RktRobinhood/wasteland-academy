WA.registerPack({
  id:     'topic-4-stats',
  island: 'topic-4-stats',
  name:   'Radio Spires',
  topic:  'Statistics & Probability',

  subtopics: [

    // ── SL4.2 Mean, variance, std dev ─────────────────────────
    {
      id: 'sl4-2-descriptive',
      name: 'Descriptive Statistics',
      questions: [
        {
          id: 'sl4-2-mean', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            const n = QGen.int(4,7);
            const vals = Array.from({length:n}, () => QGen.int(2,20));
            const sum = vals.reduce((a,b)=>a+b,0);
            const mean = parseFloat((sum/n).toFixed(2));
            return { vals, n, sum, mean };
          },
          question: p => `Find the mean of the data set: $${p.vals.join(', ')}$.`,
          answer: p => p.mean,
          tolerance: 0.02,
          hint: p => `Add all values: $${p.sum}$. Divide by $n = ${p.n}$.`,
          worked_solution: p => `Mean $= \\dfrac{${p.vals.join('+')}}{${p.n}} = \\dfrac{${p.sum}}{${p.n}} = ${p.mean}$`,
        },
        {
          id: 'sl4-2-median', type: 'parametric',
          difficulty: 2, spark_mood: 'thinking',
          params() {
            const n = QGen.pick([5,7,9]);  // odd — clean median
            const vals = Array.from({length:n}, () => QGen.int(2,25)).sort((a,b)=>a-b);
            const median = vals[Math.floor(n/2)];
            return { vals, n, median };
          },
          question: p => `Find the median of: $${p.vals.join(', ')}$ (already sorted).`,
          answer: p => p.median,
          tolerance: 0,
          hint: p => `Median is the middle value of ${p.n} data points — the ${Math.floor(p.n/2)+1}th value.`,
          worked_solution: p => `Sorted: $${p.vals.join(', ')}$. Middle value (position ${Math.floor(p.n/2)+1}) $= ${p.median}$.`,
        },
        {
          id: 'sl4-2-sd', type: 'mcq', difficulty: 3,
          question: 'The data set $\\{2, 4, 4, 4, 5, 5, 7, 9\\}$ has mean $5$. Which statement about standard deviation is correct?',
          options: [
            'Standard deviation $\\approx 2$, measuring spread around the mean',
            'Standard deviation $= 5$, equal to the mean',
            'Standard deviation is negative because some values are below the mean',
            'Standard deviation $= 0$ because the mean is an integer'
          ],
          correctIndex: 0,
          hint: 'Standard deviation measures how spread out the data is from the mean. It is always non-negative.',
          worked_solution: '$\\sigma = \\sqrt{\\dfrac{\\sum(x_i - \\bar{x})^2}{n}} \\approx 2$. Standard deviation measures spread — always $\\geq 0$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── SL4.5 Probability ────────────────────────────────────
    {
      id: 'sl4-5-probability',
      name: 'Basic Probability',
      questions: [
        {
          id: 'sl4-5-basic', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            const total = QGen.int(8,20);
            const fav = QGen.int(1, total-1);
            const gcd = (a,b) => b===0?a:gcd(b,a%b);
            const g = gcd(fav, total);
            return { total, fav, num: fav/g, den: total/g };
          },
          question: p => `A bag contains ${p.total} counters, of which ${p.fav} are red. One counter is chosen at random. Find $P(\\text{red})$ as a fraction in its simplest form. Enter the numerator.`,
          answer: p => p.num,
          tolerance: 0,
          hint: p => `$P(\\text{red}) = \\dfrac{\\text{favourable outcomes}}{\\text{total outcomes}} = \\dfrac{${p.fav}}{${p.total}}$`,
          worked_solution: p => `$P(\\text{red}) = \\dfrac{${p.fav}}{${p.total}} = \\dfrac{${p.num}}{${p.den}}$. Numerator $= ${p.num}$.`,
        },
        {
          id: 'sl4-5-complement', type: 'parametric',
          difficulty: 1, spark_mood: 'happy',
          params() {
            const p = QGen.float(0.15,0.80,2);
            const comp = parseFloat((1-p).toFixed(2));
            return { p, comp };
          },
          question: p => `$P(A) = ${p.p}$. Find $P(A')$ (the complement of $A$).`,
          answer: p => p.comp,
          tolerance: 0.005,
          hint: () => `$P(A') = 1 - P(A)$`,
          worked_solution: p => `$P(A') = 1 - ${p.p} = ${p.comp}$`,
        },
        {
          id: 'sl4-5-cond', type: 'mcq', difficulty: 3,
          question: '$P(A) = 0.6$, $P(B) = 0.5$, $P(A \\cap B) = 0.3$. Find $P(A | B)$.',
          options: ['$0.6$', '$0.5$', '$0.3$', '$0.18$'],
          correctIndex: 0,
          hint: '$P(A|B) = \\dfrac{P(A \\cap B)}{P(B)}$',
          worked_solution: '$P(A|B) = \\dfrac{0.3}{0.5} = 0.6$',
          spark_mood: 'thinking',
        },
        {
          id: 'sl4-5-independence', type: 'mcq', difficulty: 3,
          question: 'Events $A$ and $B$ are independent with $P(A) = 0.4$ and $P(B) = 0.3$. Find $P(A \\cap B)$.',
          options: ['$0.12$', '$0.70$', '$0.58$', '$0.10$'],
          correctIndex: 0,
          hint: 'Independent events: $P(A \\cap B) = P(A) \\times P(B)$.',
          worked_solution: '$P(A \\cap B) = 0.4 \\times 0.3 = 0.12$',
          spark_mood: 'happy',
        },
      ],
    },

    // ── SL4.4 Binomial distribution ──────────────────────────
    {
      id: 'sl4-4-binomial',
      name: 'Binomial Distribution',
      questions: [
        {
          id: 'sl4-4-binom-prob', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const n = QGen.int(5,10), k = QGen.int(1,4);
            const pVal = QGen.pick([0.2,0.25,0.3,0.4,0.5]);
            // P(X=k) = C(n,k)*p^k*(1-p)^(n-k)
            const C = (a,b) => { let r=1; for(let i=0;i<b;i++) r=r*(a-i)/(i+1); return r; };
            const prob = parseFloat((C(n,k)*Math.pow(pVal,k)*Math.pow(1-pVal,n-k)).toFixed(4));
            return { n, k, p: pVal, prob };
          },
          question: p => `$X \\sim B(${p.n}, ${p.p})$. Find $P(X = ${p.k})$ to 4 decimal places.`,
          answer: p => p.prob,
          tolerance: 0.0005,
          hint: p => `$P(X=k) = \\binom{n}{k}p^k(1-p)^{n-k} = \\binom{${p.n}}{${p.k}}(${p.p})^{${p.k}}(${1-p.p})^{${p.n-p.k}}$`,
          worked_solution: p => `$P(X=${p.k}) = \\binom{${p.n}}{${p.k}}(${p.p})^{${p.k}}(${1-p.p})^{${p.n-p.k}} = ${p.prob}$`,
        },
        {
          id: 'sl4-4-binom-mean', type: 'parametric',
          difficulty: 2, spark_mood: 'happy',
          params() {
            const n = QGen.int(5,20), p = QGen.pick([0.2,0.25,0.3,0.4,0.5,0.6]);
            const mean = parseFloat((n*p).toFixed(2));
            const variance = parseFloat((n*p*(1-p)).toFixed(3));
            return { n, p, mean, variance };
          },
          question: p => `$X \\sim B(${p.n}, ${p.p})$. Find the mean $E(X)$.`,
          answer: p => p.mean,
          tolerance: 0.01,
          hint: () => `For $X \\sim B(n,p)$: $E(X) = np$.`,
          worked_solution: p => `$E(X) = np = ${p.n} \\times ${p.p} = ${p.mean}$`,
        },
        {
          id: 'sl4-4-binom-identify', type: 'mcq', difficulty: 2,
          question: 'A fair coin is flipped 8 times. Let $X$ = number of heads. Which distribution describes $X$?',
          options: ['$B(8, 0.5)$', '$B(0.5, 8)$', 'Normal$(4, 2)$', '$B(8, 0.5^8)$'],
          correctIndex: 0,
          hint: 'Binomial: $B(n, p)$ where $n$ is the number of trials and $p$ is the probability of success.',
          worked_solution: '$n = 8$ trials, $p = 0.5$ (fair coin). So $X \\sim B(8, 0.5)$.',
          spark_mood: 'happy',
        },
      ],
    },

    // ── SL4.3 Normal distribution ────────────────────────────
    {
      id: 'sl4-3-normal',
      name: 'Normal Distribution',
      questions: [
        {
          id: 'sl4-3-standard', type: 'mcq', difficulty: 2,
          question: 'Heights of students are normally distributed with mean $170$ cm and standard deviation $8$ cm. Approximately what percentage of students are within one standard deviation of the mean?',
          options: ['$68\\%$', '$95\\%$', '$99.7\\%$', '$50\\%$'],
          correctIndex: 0,
          hint: 'The 68-95-99.7 rule: $\\approx68\\%$ within $\\pm1\\sigma$, $\\approx95\\%$ within $\\pm2\\sigma$.',
          worked_solution: 'By the empirical rule, $\\approx 68\\%$ of data falls within one standard deviation of the mean.',
          spark_mood: 'happy',
        },
        {
          id: 'sl4-3-zscore', type: 'parametric',
          difficulty: 3, spark_mood: 'thinking',
          params() {
            const mu = QGen.int(40,80)*2, sigma = QGen.int(4,12);
            const x = mu + QGen.pick([-2,-1,1,2])*sigma;  // nice z-scores
            const z = parseFloat(((x-mu)/sigma).toFixed(2));
            return { mu, sigma, x, z };
          },
          question: p => `A variable $X \\sim N(${p.mu}, ${p.sigma}^2)$. Find the $z$-score for $X = ${p.x}$.`,
          answer: p => p.z,
          tolerance: 0.01,
          hint: p => `$z = \\dfrac{x - \\mu}{\\sigma} = \\dfrac{${p.x} - ${p.mu}}{${p.sigma}}$`,
          worked_solution: p => `$z = \\dfrac{${p.x} - ${p.mu}}{${p.sigma}} = \\dfrac{${p.x - p.mu}}{${p.sigma}} = ${p.z}$`,
        },
        {
          id: 'sl4-3-inverse', type: 'mcq', difficulty: 4,
          question: 'The exam scores $X \\sim N(62, 12^2)$. The top $10\\%$ of students get a distinction. Using the inverse normal, the distinction threshold is closest to:',
          options: ['$77.4$', '$68$', '$86$', '$74$'],
          correctIndex: 0,
          hint: 'Find $z$ such that $P(Z > z) = 0.10$, i.e. $z \\approx 1.282$. Then $x = \\mu + z\\sigma$.',
          worked_solution: '$z = 1.282$ (from tables). $x = 62 + 1.282 \\times 12 = 62 + 15.38 = 77.4$.',
          spark_mood: 'thinking',
        },
      ],
    },

    // ── Boss: multi-part stats ────────────────────────────────
    {
      id: 'sl4-boss',
      name: 'Boss: The Spire Warden',
      questions: [
        {
          id: 'sl4-boss-1', type: 'boss', difficulty: 5,
          title: 'Spire Warden',
          intro: 'The Warden controls the data. Break through three analytical challenges.',
          parts: [
            {
              type: 'value',
              question: 'In a school, the probability a student studies Mathematics is $0.6$, and the probability they study Biology is $0.4$. The probability they study both is $0.15$. Find $P(M \\cup B)$.',
              answer: 0.85,
              tolerance: 0.005,
              hint: '$P(M \\cup B) = P(M) + P(B) - P(M \\cap B)$',
              worked_solution: '$P(M \\cup B) = 0.6 + 0.4 - 0.15 = 0.85$',
              marks: 3, followThrough: true,
            },
            {
              type: 'value',
              question: 'Using the same data, find $P(M | B)$ — the probability a student studies Mathematics given they study Biology.',
              answer: parseFloat((0.15/0.4).toFixed(4)),
              tolerance: 0.005,
              hint: '$P(M|B) = \\dfrac{P(M \\cap B)}{P(B)} = \\dfrac{0.15}{0.4}$',
              worked_solution: '$P(M|B) = \\dfrac{0.15}{0.4} = 0.375$',
              marks: 2, followThrough: true,
            },
            {
              type: 'mcq',
              question: 'Are events $M$ (studies Mathematics) and $B$ (studies Biology) independent? Justify.',
              options: [
                'No — $P(M|B) \\neq P(M)$, so they are not independent',
                'Yes — $P(M \\cap B) > 0$ means they overlap',
                'Yes — $P(M) \\times P(B) = P(M \\cap B)$',
                'Cannot be determined without more data'
              ],
              correctIndex: 0,
              hint: 'Check: are $P(M|B) = P(M)$ and $P(M)\\times P(B) = P(M\\cap B)$?',
              worked_solution: '$P(M|B) = 0.375 \\neq 0.6 = P(M)$, so $M$ and $B$ are NOT independent. Also: $P(M)P(B) = 0.6 \\times 0.4 = 0.24 \\neq 0.15 = P(M \\cap B)$.',
              marks: 2, followThrough: false,
            },
          ],
          spark_mood: 'surprised',
        },
      ],
    },

  ],
});
