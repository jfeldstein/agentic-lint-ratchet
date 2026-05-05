/**
 * Reads PROMPT.md (or RATCHET_PROMPT_FILE) and runs one-shot Cursor agent via @cursor/sdk.
 * Intended for GitHub Actions with CURSOR_API_KEY from repository secrets.
 */
import { readFileSync, existsSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import { Agent, CursorAgentError } from "@cursor/sdk";

function getWorkspaceCwd() {
  return process.env.GITHUB_WORKSPACE || process.cwd();
}

function readPromptOrExit({ cwd }) {
  const promptFile = process.env.RATCHET_PROMPT_FILE || "PROMPT.md";
  const promptPath = isAbsolute(promptFile) ? promptFile : join(cwd, promptFile);

  if (!existsSync(promptPath)) {
    console.error(`Missing prompt file: ${promptPath}`);
    process.exit(1);
  }

  return readFileSync(promptPath, "utf8");
}

function getCursorApiKeyOrExit() {
  const apiKey = process.env.CURSOR_API_KEY;
  if (!apiKey?.trim()) {
    console.error(
      "CURSOR_API_KEY is required. Add a repository secret named CURSOR_API_KEY (Cursor Dashboard → Integrations or team service account).",
    );
    process.exit(1);
  }
  return apiKey.trim();
}

const cwd = getWorkspaceCwd();
const prompt = readPromptOrExit({ cwd });
const apiKey = getCursorApiKeyOrExit();
const modelId = process.env.CURSOR_MODEL || "composer-2";

try {
  const runResult = await Agent.prompt(prompt, {
    apiKey,
    model: { id: modelId },
    local: { cwd },
  });

  if (runResult.status === "error") {
    console.error(
      "Run finished with error status:",
      runResult.id,
      runResult.result ?? "",
    );
    process.exit(2);
  }

  if (runResult.git?.branches?.length) {
    console.log("Git:", JSON.stringify(runResult.git, null, 2));
  }
  console.log("Done:", runResult.status, "run", runResult.id);
  process.exit(0);
} catch (err) {
  if (err instanceof CursorAgentError) {
    console.error(
      "Cursor agent error:",
      err.message,
      "retryable=",
      err.isRetryable,
    );
    process.exit(1);
  }
  throw err;
}
