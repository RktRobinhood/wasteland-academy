// Allowed values for skill fields in the curriculum map (curriculum/aa-sl.json,
// aa-hl.json and ai.json). Shared by tools/coverage.mjs and tools/courses.mjs.
export const ENUMS = {
  paper: ['p1', 'p2', 'either'],
  formats: ['mcq', 'value', 'multipart', 'error-spot', 'method-pick', 'match',
            'order-steps', 'graph-pick', 'true-false-reason'],
  representations: ['symbolic', 'graph', 'table', 'words', 'context', 'diagram', 'vector'],
  approach: ['algebraic', 'formula', 'graphical', 'gdc', 'numerical', 'geometric',
             'calculus', 'symmetry', 'structural', 'transformation', 'diagram',
             'counting', 'estimation', 'contextual', 'proof'],
};
