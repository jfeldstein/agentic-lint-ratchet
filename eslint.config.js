import js from "@eslint/js";
import globals from "globals";

// Active coverage: all *.mjs under scripts/ (recursive).
//
// Depth-first ratchet queue — explicit deferrals (ignored until JS lint applies here):
// 1. .github/
// 2. actions/
// 3. config/
// 4. docs/
// 5. templates/
// 6. test/
// 7. workflows/
// 8. Root Helm + prose: Chart.yaml, Chart.lock, values.yaml, PROMPT.md, README.md
export default [
  {
    ignores: [
      "**/node_modules/**",
      ".github/**",
      "actions/**",
      "config/**",
      "docs/**",
      "templates/**",
      "test/**",
      "workflows/**",
      "Chart.yaml",
      "Chart.lock",
      "values.yaml",
      "PROMPT.md",
      "README.md",
    ],
  },
  {
    files: ["scripts/**/*.mjs"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module",
      globals: globals.node,
    },
    ...js.configs.recommended,
  },
];
