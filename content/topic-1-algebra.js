WA.registerPack({
  id:     'topic-1-algebra',
  island: 'topic-1-algebra',
  name:   'Scrap Fields',
  topic:  'Numbers & Algebra',

  subtopics: [

    // ── SL1.1 Numbers in standard form ─────────────────────────
    {
      id:   'sl1-1-standard-form',
      name: 'Standard Form',
      questions: [
        {
          id: 'sl1-1-a', type: 'mcq', difficulty: 1,
          question: 'Write $6\\,400\\,000$ in standard form.',
          options: ['$6.4 \\times 10^5$', '$6.4 \\times 10^6$', '$64 \\times 10^5$', '$0.64 \\times 10^7$'],
          correctIndex: 1,
          hint: 'Move the decimal point until you have a number between 1 and 10. Count how many places you moved.',
          worked_solution: '$6\\,400\\,000 = 6.4 \\times 10^6$ because the decimal point moves 6 places to the left.',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-1-b', type: 'mcq', difficulty: 1,
          question: 'Evaluate $(3 \\times 10^4) \\times (2 \\times 10^3)$, giving your answer in standard form.',
          options: ['$6 \\times 10^7$', '$6 \\times 10^{12}$', '$5 \\times 10^7$', '$6 \\times 10^6$'],
          correctIndex: 0,
          hint: 'Multiply the coefficients: $3 \\times 2 = 6$. Add the powers: $4 + 3 = 7$.',
          worked_solution: '$(3 \\times 10^4)(2 \\times 10^3) = 6 \\times 10^{4+3} = 6 \\times 10^7$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-1-c', type: 'value', difficulty: 2,
          question: 'Given $p = 4.2 \\times 10^{-3}$ and $q = 6 \\times 10^5$, find $\\dfrac{p}{q}$. Give your answer in the form $a \\times 10^n$ where $n$ is an integer. Enter the value of $a$ (to 1 d.p.).',
          answer: 7.0,
          tolerance: 0.15,
          hint: 'Divide the coefficients: $4.2 \\div 6 = 0.7$. Then adjust: $0.7 = 7 \\times 10^{-1}$. What does that do to the power of 10?',
          worked_solution: '$\\dfrac{4.2 \\times 10^{-3}}{6 \\times 10^5} = 0.7 \\times 10^{-8} = 7.0 \\times 10^{-9}$. The answer is $a = 7.0$.',
          spark_mood: 'thinking'
        },
      ]
    },

    // ── SL1.2 Arithmetic sequences ────────────────────────────
    {
      id:   'sl1-2-arithmetic',
      name: 'Arithmetic Sequences',
      questions: [
        {
          id: 'sl1-2-a', type: 'mcq', difficulty: 1,
          question: 'The first term of an arithmetic sequence is $5$ and the common difference is $3$. What is the $10$th term?',
          options: ['$30$', '$32$', '$27$', '$35$'],
          correctIndex: 1,
          hint: 'Use $u_n = u_1 + (n-1)d$. Substitute $u_1 = 5$, $d = 3$, $n = 10$.',
          worked_solution: '$u_{10} = 5 + (10-1)(3) = 5 + 27 = 32$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-2-b', type: 'value', difficulty: 2,
          question: 'An arithmetic sequence has first term $u_1 = 7$ and common difference $d = 4$. Find the sum of the first $20$ terms.',
          answer: 900,
          tolerance: 0,
          hint: 'Use $S_n = \\dfrac{n}{2}(2u_1 + (n-1)d)$ with $n=20$, $u_1=7$, $d=4$.',
          worked_solution: '$S_{20} = \\dfrac{20}{2}(2 \\cdot 7 + 19 \\cdot 4) = 10(14 + 76) = 10 \\times 90 = 900$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-2-c', type: 'mcq', difficulty: 2,
          question: 'The $5$th term of an arithmetic sequence is $23$ and the $9$th term is $39$. Find the common difference.',
          options: ['$3$', '$4$', '$5$', '$6$'],
          correctIndex: 1,
          hint: 'The difference between the 9th and 5th term covers $9 - 5 = 4$ steps. So $4d = 39 - 23$.',
          worked_solution: '$4d = 39 - 23 = 16 \\Rightarrow d = 4$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-2-d', type: 'value', difficulty: 3,
          question: 'An arithmetic sequence has $u_1 = 3$ and $d = 2$. Find the first term greater than $100$.',
          answer: 101,
          tolerance: 0,
          hint: 'Solve $u_n > 100$: $3 + (n-1)2 > 100 \\Rightarrow 2n > 99 \\Rightarrow n > 49.5$, so the first such term has $n = 50$.',
          worked_solution: '$u_{50} = 3 + 49 \\times 2 = 3 + 98 = 101$',
          spark_mood: 'happy'
        },
      ]
    },

    // ── SL1.3 Geometric sequences ────────────────────────────
    {
      id:   'sl1-3-geometric',
      name: 'Geometric Sequences',
      prerequisite: 'sl1-2-arithmetic',
      questions: [
        {
          id: 'sl1-3-a', type: 'mcq', difficulty: 1,
          question: 'A geometric sequence has first term $2$ and common ratio $3$. What is the $5$th term?',
          options: ['$162$', '$486$', '$54$', '$243$'],
          correctIndex: 0,
          hint: 'Use $u_n = u_1 \\cdot r^{n-1}$. Substitute $u_1=2$, $r=3$, $n=5$.',
          worked_solution: '$u_5 = 2 \\times 3^4 = 2 \\times 81 = 162$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-3-b', type: 'mcq', difficulty: 2,
          question: 'A geometric sequence has $u_3 = 12$ and $u_6 = 96$. Find the common ratio $r$.',
          options: ['$2$', '$3$', '$4$', '$\\sqrt{2}$'],
          correctIndex: 0,
          hint: '$u_6 = u_3 \\cdot r^3$, so $96 = 12 r^3$. Solve for $r$.',
          worked_solution: '$r^3 = \\dfrac{96}{12} = 8 \\Rightarrow r = 2$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-3-c', type: 'value', difficulty: 2,
          question: 'Find the sum of the first $8$ terms of the geometric sequence $1, 2, 4, 8, \\ldots$',
          answer: 255,
          tolerance: 0,
          hint: 'Use $S_n = \\dfrac{u_1(r^n - 1)}{r - 1}$ with $u_1=1$, $r=2$, $n=8$.',
          worked_solution: '$S_8 = \\dfrac{1(2^8 - 1)}{2-1} = 256 - 1 = 255$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-3-d', type: 'mcq', difficulty: 3,
          question: 'Which condition ensures that an infinite geometric series converges?',
          options: ['$r > 0$', '$|r| < 1$', '$r < 1$', '$r \\neq 1$'],
          correctIndex: 1,
          hint: 'Think about what happens to $r^n$ as $n \\to \\infty$. It must approach $0$.',
          worked_solution: 'For $S_\\infty = \\dfrac{u_1}{1-r}$ to exist, we need $|r| < 1$ so that $r^n \\to 0$.',
          spark_mood: 'thinking'
        },
      ]
    },

    // ── SL1.4 Financial mathematics ──────────────────────────
    {
      id:   'sl1-4-financial',
      name: 'Financial Applications',
      questions: [
        {
          id: 'sl1-4-a', type: 'mcq', difficulty: 1,
          question: '$\\$1200$ is invested at $5\\%$ per annum compound interest. What is the value after $3$ years?',
          options: ['$\\$1380.00$', '$\\$1389.15$', '$\\$1323.00$', '$\\$1260.00$'],
          correctIndex: 1,
          hint: 'Use $FV = PV \\times \\left(1 + \\dfrac{r}{100}\\right)^n$.',
          worked_solution: '$FV = 1200 \\times 1.05^3 = 1200 \\times 1.157625 = \\$1389.15$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-4-b', type: 'value', difficulty: 2,
          question: 'An investment grows from $\\$500$ to $\\$605$ over $2$ years with compound interest. Find the annual interest rate as a percentage. Give your answer to the nearest whole number.',
          answer: 10,
          tolerance: 0.05,
          hint: '$(1+r)^2 = \\dfrac{605}{500} = 1.21$. Take the square root.',
          worked_solution: '$(1+r)^2 = 1.21 \\Rightarrow 1 + r = 1.1 \\Rightarrow r = 0.1 = 10\\%$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-4-c', type: 'mcq', difficulty: 3,
          question: '$\\$2000$ is invested at $4\\%$ per annum compounded quarterly. Which expression gives the value after $5$ years?',
          options: [
            '$2000 \\times 1.04^5$',
            '$2000 \\times 1.01^{20}$',
            '$2000 \\times 1.04^{20}$',
            '$2000 \\times 1.01^5$'
          ],
          correctIndex: 1,
          hint: 'Quarterly means 4 times a year. Divide the rate by 4, multiply the years by 4.',
          worked_solution: 'Rate per quarter $= 4\\% \\div 4 = 1\\% = 0.01$. Periods $= 5 \\times 4 = 20$. So $FV = 2000 \\times 1.01^{20}$.',
          spark_mood: 'thinking'
        },
      ]
    },

    // ── SL1.5 Exponents & logs ────────────────────────────────
    {
      id:   'sl1-5-logs',
      name: 'Exponents & Logarithms',
      prerequisite: 'sl1-3-geometric',
      questions: [
        {
          id: 'sl1-5-a', type: 'mcq', difficulty: 1,
          question: 'Solve $2^x = 32$.',
          options: ['$x = 4$', '$x = 5$', '$x = 6$', '$x = 16$'],
          correctIndex: 1,
          hint: 'Write $32$ as a power of $2$: $32 = 2^?$',
          worked_solution: '$2^x = 2^5 \\Rightarrow x = 5$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-5-b', type: 'mcq', difficulty: 2,
          question: 'Simplify $\\log_3 81 - \\log_3 9$.',
          options: ['$9$', '$3$', '$2$', '$1$'],
          correctIndex: 2,
          hint: 'Use $\\log_3 81 - \\log_3 9 = \\log_3 \\left(\\dfrac{81}{9}\\right)$.',
          worked_solution: '$\\log_3 \\left(\\dfrac{81}{9}\\right) = \\log_3 9 = 2$ (since $3^2 = 9$).',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-5-c', type: 'value', difficulty: 2,
          question: 'Solve $\\log_2 x = 5$. Enter the value of $x$.',
          answer: 32,
          tolerance: 0,
          hint: '$\\log_2 x = 5$ means $2^5 = x$.',
          worked_solution: '$x = 2^5 = 32$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-5-d', type: 'mcq', difficulty: 3,
          question: 'Solve $3^{x+1} = 5^x$. Give the answer to $3$ significant figures.',
          options: ['$x \\approx 2.15$', '$x \\approx 3.15$', '$x \\approx 1.87$', '$x \\approx 4.50$'],
          correctIndex: 0,
          hint: 'Take $\\ln$ of both sides: $(x+1)\\ln 3 = x \\ln 5$. Expand and collect $x$ terms.',
          worked_solution: '$(x+1)\\ln 3 = x \\ln 5 \\Rightarrow x\\ln 3 + \\ln 3 = x\\ln 5 \\Rightarrow \\ln 3 = x(\\ln 5 - \\ln 3) \\Rightarrow x = \\dfrac{\\ln 3}{\\ln 5 - \\ln 3} = \\dfrac{1.0986}{0.5108} \\approx 2.15$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-5-e', type: 'mcq', difficulty: 3,
          question: 'Express $\\log_5 8$ in terms of $\\log 2$ and $\\log 5$ using the change of base formula.',
          options: [
            '$\\dfrac{3\\log 2}{\\log 5}$',
            '$\\dfrac{\\log 2}{3\\log 5}$',
            '$3\\log_5 2$',
            'Both A and C are correct'
          ],
          correctIndex: 3,
          hint: 'Change of base: $\\log_5 8 = \\dfrac{\\log 8}{\\log 5} = \\dfrac{3 \\log 2}{\\log 5}$. Also note $\\log_5 8 = \\log_5 2^3 = 3\\log_5 2$.',
          worked_solution: '$\\log_5 8 = \\log_5 2^3 = 3 \\log_5 2 = \\dfrac{3 \\log 2}{\\log 5}$. Both A and C are equivalent correct forms.',
          spark_mood: 'sarcastic'
        },
      ]
    },

    // ── SL1.6 Deductive proof ─────────────────────────────────
    {
      id:   'sl1-6-proof',
      name: 'Deductive Proof',
      prerequisite: 'sl1-5-logs',
      questions: [
        {
          id: 'sl1-6-a', type: 'mcq', difficulty: 3,
          question: 'To prove that the sum of two consecutive integers is always odd, we write the integers as $n$ and $n+1$. The sum is $2n+1$. This is odd because...',
          options: [
            '$n$ is any integer so $2n+1$ could be even',
            '$2n$ is always even, and even + 1 is always odd',
            '$n+1$ is always odd',
            'We only proved it for positive $n$'
          ],
          correctIndex: 1,
          hint: 'An even number has the form $2k$ for integer $k$. Adding $1$ gives $2k+1$, which is the definition of odd.',
          worked_solution: 'Let the integers be $n$ and $n+1$ for any integer $n$. Their sum is $2n+1$. Since $2n$ is divisible by $2$ (even), $2n+1$ is odd. This holds for all integers $n$, so the proof is complete.',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-6-b', type: 'mcq', difficulty: 4,
          question: 'Which is the correct first step to prove that $n^2 + n$ is always even for all integers $n$?',
          options: [
            'Try $n = 1, 2, 3$',
            'Write $n^2 + n = n(n+1)$ and note that one of $n$, $n+1$ is always even',
            'Say $n^2$ and $n$ are both odd',
            'Assume $n$ is even and let $n = 2k$'
          ],
          correctIndex: 1,
          hint: 'Factor the expression first. Consecutive integers always include one even number.',
          worked_solution: '$n^2 + n = n(n+1)$. Consecutive integers $n$ and $n+1$ always include exactly one even number, so their product is always even.',
          spark_mood: 'thinking'
        },
      ]
    },

    // ── SL1.7 Laws of exponents / change of base ─────────────
    {
      id:   'sl1-7-laws',
      name: 'Laws of Exponents',
      prerequisite: 'sl1-5-logs',
      questions: [
        {
          id: 'sl1-7-a', type: 'mcq', difficulty: 2,
          question: 'Simplify $\\dfrac{2^8}{2^3}$.',
          options: ['$2^5$', '$2^{11}$', '$2^{24}$', '$4^5$'],
          correctIndex: 0,
          hint: 'Division rule: subtract the exponents.',
          worked_solution: '$\\dfrac{2^8}{2^3} = 2^{8-3} = 2^5$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-7-b', type: 'mcq', difficulty: 2,
          question: 'Simplify $(x^3)^4$.',
          options: ['$x^{12}$', '$x^7$', '$x^{81}$', '$4x^3$'],
          correctIndex: 0,
          hint: 'Power rule: multiply the exponents.',
          worked_solution: '$(x^3)^4 = x^{3 \\times 4} = x^{12}$',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-7-c', type: 'mcq', difficulty: 3,
          question: 'Simplify $\\dfrac{a^{-2}b^3}{a^3b^{-1}}$.',
          options: ['$\\dfrac{b^4}{a^5}$', '$\\dfrac{a}{b^2}$', '$a^5b^4$', '$\\dfrac{a^5}{b^4}$'],
          correctIndex: 0,
          hint: 'Subtract exponents for each base. Remember: $\\dfrac{b^3}{b^{-1}} = b^{3-(-1)} = b^4$.',
          worked_solution: '$\\dfrac{a^{-2}b^3}{a^3b^{-1}} = a^{-2-3} \\cdot b^{3-(-1)} = a^{-5}b^4 = \\dfrac{b^4}{a^5}$',
          spark_mood: 'thinking'
        },
      ]
    },

    // ── SL1.8 Infinite geometric series ──────────────────────
    {
      id:   'sl1-8-infinite',
      name: 'Infinite Geometric Series',
      prerequisite: 'sl1-3-geometric',
      questions: [
        {
          id: 'sl1-8-a', type: 'value', difficulty: 2,
          question: 'Find the sum to infinity of the geometric series $12 + 6 + 3 + \\cdots$',
          answer: 24,
          tolerance: 0,
          hint: 'Check $r = \\dfrac{6}{12} = 0.5$. Use $S_\\infty = \\dfrac{u_1}{1-r}$.',
          worked_solution: '$r = 0.5$, $|r| < 1$ so the series converges. $S_\\infty = \\dfrac{12}{1-0.5} = \\dfrac{12}{0.5} = 24$.',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-8-b', type: 'mcq', difficulty: 3,
          question: 'A geometric series has $u_1 = 8$ and $S_\\infty = 20$. Find the common ratio $r$.',
          options: ['$r = 0.4$', '$r = 0.5$', '$r = 0.6$', '$r = 0.3$'],
          correctIndex: 2,
          hint: '$S_\\infty = \\dfrac{u_1}{1-r} \\Rightarrow 20 = \\dfrac{8}{1-r} \\Rightarrow 1-r = \\dfrac{8}{20}$.',
          worked_solution: '$1-r = \\dfrac{8}{20} = 0.4 \\Rightarrow r = 0.6$',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-8-c', type: 'multipart', difficulty: 4,
          question: 'A geometric series has first term $a$ and common ratio $r$ where $|r| < 1$.',
          parts: [
            {
              type: 'mcq',
              question: 'Write down the formula for $S_\\infty$.',
              options: [
                '$S_\\infty = \\dfrac{a}{1-r}$',
                '$S_\\infty = \\dfrac{a}{1+r}$',
                '$S_\\infty = a(1-r)$',
                '$S_\\infty = \\dfrac{r}{1-a}$'
              ],
              correctIndex: 0
            },
            {
              type: 'value',
              question: 'Given $a = 5$ and $r = 0.8$, find $S_\\infty$.',
              answer: 25,
              tolerance: 0
            }
          ],
          hint: 'Part (a): recall the standard formula. Part (b): substitute the given values.',
          worked_solution: '(a) $S_\\infty = \\dfrac{a}{1-r}$. (b) $S_\\infty = \\dfrac{5}{1-0.8} = \\dfrac{5}{0.2} = 25$.',
          spark_mood: 'happy'
        },
      ]
    },

    // ── SL1.9 Binomial theorem ────────────────────────────────
    {
      id:   'sl1-9-binomial',
      name: 'Binomial Theorem',
      prerequisite: 'sl1-7-laws',
      questions: [
        {
          id: 'sl1-9-a', type: 'value', difficulty: 2,
          question: 'Find the coefficient of $x^2$ in the expansion of $(1+x)^5$.',
          answer: 10,
          tolerance: 0,
          hint: 'Use $\\binom{5}{2} = \\dfrac{5!}{2!3!}$.',
          worked_solution: '$\\binom{5}{2} = 10$, so the $x^2$ term is $10x^2$.',
          spark_mood: 'happy'
        },
        {
          id: 'sl1-9-b', type: 'mcq', difficulty: 3,
          question: 'Find the constant term in the expansion of $\\left(x + \\dfrac{2}{x}\\right)^6$.',
          options: ['$60$', '$120$', '$160$', '$240$'],
          correctIndex: 2,
          hint: 'The general term is $\\binom{6}{r} x^{6-r} \\left(\\dfrac{2}{x}\\right)^r = \\binom{6}{r} 2^r x^{6-2r}$. Set $6 - 2r = 0$.',
          worked_solution: '$6 - 2r = 0 \\Rightarrow r = 3$. Term $= \\binom{6}{3} 2^3 = 20 \\times 8 = 160$.',
          spark_mood: 'thinking'
        },
        {
          id: 'sl1-9-c', type: 'mcq', difficulty: 4,
          question: 'Find the term containing $x^3$ in the expansion of $(2-x)^7$.',
          options: ['$-280x^3$', '$280x^3$', '$-560x^3$', '$560x^3$'],
          correctIndex: 2,
          hint: 'General term of $(2-x)^7$: $\\binom{7}{r}2^{7-r}(-x)^r$. Set $r = 3$ for the $x^3$ term.',
          worked_solution: 'General term: $\\binom{7}{r}2^{7-r}(-1)^r x^r$. At $r=3$: $\\binom{7}{3} \\cdot 2^4 \\cdot (-1)^3 = 35 \\cdot 16 \\cdot (-1) = -560$. Term: $-560x^3$.',
          spark_mood: 'sarcastic'
        },
        {
          id: 'sl1-9-d', type: 'mcq', difficulty: 5,
          question: 'In the expansion of $(1 + kx)^8$, the coefficient of $x^2$ is $112$. Find $k$.',
          options: ['$k = \\pm\\sqrt{2}$', '$k = \\pm 2$', '$k = \\pm 3$', '$k = 4$'],
          correctIndex: 1,
          hint: 'The $x^2$ term is $\\binom{8}{2}(kx)^2 = 28k^2x^2$. Set $28k^2 = 112$.',
          worked_solution: '$28k^2 = 112 \\Rightarrow k^2 = 4 \\Rightarrow k = \\pm 2$.',
          spark_mood: 'thinking'
        },
      ]
    },

  ] // end subtopics
});
