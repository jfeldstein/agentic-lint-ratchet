import { readFileSync, existsSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import { resolveHarness } from "./runtime/registry.mjs";
import { MissingRuntimeEnvError, UnsupportedRuntimeError } from "./runtime/errors.mjs";

export function getWorkspaceCwd(env = process.env) {
  return env.GITHUB_WORKSPACE ?? process.cwd();
}

export function readPromptOrExit({ cwd, env = process.env }) {
  const promptFile = env.RATCHET_PROMPT_FILE || "PROMPT.md";
  const promptPath = isAbsolute(promptFile) ? promptFile : join(cwd, promptFile);

  if (!existsSync(promptPath)) {
    console.error(`Missing prompt file: ${promptPath}`);
    process.exit(1);
  }

  return readFileSync(promptPath, "utf8");
}

export async function main({ env = process.env, stdout = process.stdout, stderr = process.stderr } = {}) {
  const cwd = getWorkspaceCwd(env);
  const prompt = readPromptOrExit({ cwd, env });
  const selectedRuntime = env.RATCHET_AGENT ?? "cursor";

  try {
    const harness = resolveHarness(selectedRuntime);
    harness.validateEnv(env);
    return await harness.run({ cwd, prompt, env, stdout, stderr });
  } catch (err) {
    if (err instanceof UnsupportedRuntimeError || err instanceof MissingRuntimeEnvError) {
      stderr.write(`${err.message}\n`);
      return 1;
    }
    throw err;
  }
}

const exitCode = await main();
process.exit(exitCode);
