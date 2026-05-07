import js from "@eslint/js";
import globals from "globals";

// Active coverage: scripts/**/*.mjs, eslint.config.js (flat config; same rules).
// YAML: yamllint (.yamllint, npm run lint:yaml): .github/, .lint-ratchet.config.yml,
//   config/, workflows/, Chart.yaml, actions/*.yml, values.yaml — not templates/** (Helm).
// Deferred for ESLint: docs/, templates/, test/, Chart.lock, PROMPT.md, README.md until JS tooling maps them.
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
