import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import { spawn } from "node:child_process";
import { assertRequiredEnv } from "./env.mjs";

const PI_CLI_PACKAGE = "@mariozechner/pi-coding-agent";
const PI_PROVIDER_ID = "litellm";
const PI_SETUP_HINT =
  "Consult the lint-ratchet workflow docs for Litellm and Pi vars; put unset entries under workflow env: on the job or lint-ratchet step.";

function writePiModelsConfig(env) {
  const piDir = join(homedir(), ".pi", "agent");
  const modelsPath = join(piDir, "models.json");
  mkdirSync(piDir, { recursive: true });

  const config = {
    providers: {
      [PI_PROVIDER_ID]: {
        baseUrl: env.LITELLM_BASE_URL,
        api: "openai-completions",
        apiKey: "LITELLM_API_KEY",
        models: [{ id: env.PI_MODEL }],
      },
    },
  };

  writeFileSync(modelsPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

function runPiCommand({ cwd, prompt, env, stdout, stderr }) {
  const args = ["-y", PI_CLI_PACKAGE, "--model", env.PI_MODEL, "-p", prompt];

  return new Promise((resolve, reject) => {
    const child = spawn("npx", args, { cwd, env, stdio: ["ignore", "pipe", "pipe"] });

    child.stdout.on("data", (chunk) => stdout.write(chunk));
    child.stderr.on("data", (chunk) => stderr.write(chunk));
    child.on("error", reject);
    child.on("close", (code) => resolve(code ?? 1));
  });
}

export const piHarness = {
  id: "pi",
  requiredEnv: ["LITELLM_BASE_URL", "LITELLM_API_KEY", "PI_MODEL"],
  validateEnv(env) {
    assertRequiredEnv("pi", this.requiredEnv, env, PI_SETUP_HINT);
  },
  async run({ cwd, prompt, env, stdout, stderr }) {
    writePiModelsConfig(env);
    const code = await runPiCommand({ cwd, prompt, env, stdout, stderr });
    if (code !== 0) {
      stderr.write(
        `PI runtime failed with exit code ${code}. Verify LITELLM_BASE_URL, LITELLM_API_KEY, and PI_MODEL.\n`,
      );
      return code;
    }
    return 0;
  },
};
