// Content defects that are known but not fixed yet. They're reported as TODO
// tests, so they stay visible without turning the suite red. When one is
// fixed, the "known-defect list is current" test fails until its entry is
// deleted here.
//
// Each entry is either:
//   { id, check, reason }   a mechanical check from checks.mjs that fails on this item
//   { id, reason, assert }  a targeted assertion that holds once the item is fixed
//
// The FAL-205 audit's defects were fixed in FAL-210; their assertions now live
// in content.test.mjs as regression tests.
export const KNOWN_DEFECTS = [];
