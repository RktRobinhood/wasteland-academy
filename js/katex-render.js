const KR = {
  ready: false,

  // Never blocks boot. render() checks for KaTeX on every call, so maths
  // shows as plain text if the CDN script hasn't loaded (or never does).
  init() {
    this.ready = typeof katex !== 'undefined';
    return Promise.resolve();
  },

  render(el) {
    if (!el) return;
    if (typeof renderMathInElement === 'undefined') return;
    try {
      renderMathInElement(el, {
        delimiters: [
          { left: '$$', right: '$$', display: true },
          { left: '$', right: '$', display: false },
          { left: '\\(', right: '\\)', display: false },
          { left: '\\[', right: '\\]', display: true }
        ],
        throwOnError: false,
        output: 'html'
      });
    } catch(e) {
      console.warn('[KR] Render error', e);
    }
  },

  renderString(str) {
    if (!str) return '';
    if (typeof katex === 'undefined') return str;
    const div = document.createElement('div');
    div.textContent = str;
    this.render(div);
    return div.innerHTML;
  }
};
