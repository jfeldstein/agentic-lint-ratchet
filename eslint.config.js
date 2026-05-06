import js from "@eslint/js";
import globals from "globals";

// Active coverage: scripts/**/*.mjs, eslint.config.js (flat config; same rules).
// Path map (depth-first): below are not in files[] until they gain linted JS —
//   .github/, actions/, config/, docs/, templates/, test/, workflows/,
//   Chart.yaml, Chart.lock, values.yaml, PROMPT.md, README.md (non-JS assets).
export default [
  {
    ignores: ["**/node_modules/**"],
  },
  {
    files: ["scripts/**/*.mjs", "eslint.config.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: globals.node,
    },
    ...js.configs.recommended,
  },
];
