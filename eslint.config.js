import js from "@eslint/js";
import globals from "globals";

// Path scope (see .github/workflows/ci.yml): active vs deferred vs ratchet queue.
//
// Active: scripts/**/*.mjs, eslint.config.js (flat config; same rules).
//
// Depth-first ratchet queue (JS — enable in order with CI):
//   1. scripts/**/*.mjs — done.
//   2. eslint.config.js — done.
//   (No other application JS trees in this chart; YAML uses yamllint, not ESLint.)
//
// YAML: yamllint (.yamllint, npm run lint:yaml): .github/, .lint-ratchet.config.yml,
//   config/, workflows/, Chart.yaml, actions/*.yml, values.yaml — not templates/** (Helm).
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
