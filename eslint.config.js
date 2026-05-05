import js from "@eslint/js";
import globals from "globals";

/**
 * Ratchet queue — paths deferred for ESLint (enable when tooling lands):
 * - YAML / Helm: templates/, *.yaml, workflows/, actions/, .github/workflows/
 * - Markdown: PROMPT.md, README.md, docs/
 * - Bats / shell: test/*.bats
 */
export default [
  { ignores: ["**/node_modules/**"] },
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
