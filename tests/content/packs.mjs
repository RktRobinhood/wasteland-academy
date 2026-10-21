// Loads the content packs the way index.html does (classic scripts calling
// WA.registerPack), but inside a vm with a stub WA, and flattens them into
// the items the validator checks.
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

export function loadPacks() {
  const packs = [];
  const context = vm.createContext({ WA: { registerPack: pack => packs.push(pack) } });
  for (const file of PACK_FILES) {
    vm.runInContext(fs.readFileSync(path.join(REPO, file), 'utf8'), context, { filename: file });
  }
  return packs;
}

// Every question, plus each part of a multipart/boss question as its own item
// (`<id>.parts[i]`), since parts are answered like stand-alone mcq/value items.
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
