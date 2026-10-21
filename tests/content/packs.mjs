// Loads the content packs the way index.html does (classic scripts calling
// WA.registerPack, with QGen loaded first), but inside a vm with a stub WA,
// and flattens them into the items the validator checks.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

export const REPO = path.resolve(import.meta.dirname, '../..');

export const PACK_FILES = [
  'content/topic-1-algebra.js',
  'content/topic-2-functions.js',
  'content/topic-3-geometry.js',
  'content/topic-4-stats.js',
  'content/topic-5-calculus.js',
];

// Runs classic scripts in one fresh context and returns it
export function loadScripts(files, globals = {}) {
  const context = vm.createContext({ console, ...globals });
  for (const file of files) {
    vm.runInContext(fs.readFileSync(path.join(REPO, file), 'utf8'), context, { filename: file });
  }
  return context;
}

export function loadPacks() {
  const packs = [];
  const context = loadScripts(['js/question-gen.js', ...PACK_FILES], { WA: { registerPack: pack => packs.push(pack) } });
  packs.QGen = vm.runInContext('QGen', context);
  return packs;
}

// Every question, plus each part of a multipart/boss question as its own item
// (`<id>.parts[i]`), since parts are answered like stand-alone mcq/value items.
// Generated (parametric) templates are listed once, unexpanded; see
// loadGenerated() for their output.
export function loadItems() {
  const items = [];
  for (const pack of loadPacks()) {
    for (const st of pack.subtopics) {
      for (const q of st.questions || []) {
        items.push({ id: q.id, packId: pack.id, subtopic: st.id, q });
        (q.parts || []).forEach((part, i) => {
          items.push({ id: `${q.id}.parts[${i}]`, packId: pack.id, subtopic: st.id, q: part, parent: q });
        });
      }
    }
  }
  return items;
}

// Each parametric template expanded `runs` times by the real QGen.expand.
// A failed expansion gives `q: null`.
export function loadGenerated(runs) {
  const packs = loadPacks();
  const out = [];
  for (const pack of packs) {
    for (const st of pack.subtopics) {
      for (const t of st.questions || []) {
        if (t.type !== 'parametric') continue;
        const expansions = [];
        for (let i = 0; i < runs; i++) expansions.push(packs.QGen.expand(t));
        out.push({ id: t.id, packId: pack.id, subtopic: st.id, template: t, expansions });
      }
    }
  }
  return out;
}
