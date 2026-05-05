/**
 * Reads PROMPT.md (or RATCHET_PROMPT_FILE) and runs a streaming Cursor agent via @cursor/sdk.
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

let agent;
try {
  agent = await Agent.create({
    apiKey,
    model: { id: modelId },
    local: { cwd },
  });

  console.log(`Agent started: ${agent.agentId}`);

  const run = await agent.send(prompt);
  console.log(`Run started: ${run.id}`);

  for await (const event of run.stream()) {
    if (event.type === "assistant") {
      for (const block of event.message.content) {
        if (block.type === "text" && block.text) {
          process.stdout.write(block.text);
        }
      }
    } else if (event.type === "tool_use") {
      console.log(`\n[tool] ${event.name}`);
    }
  }

  const result = await run.wait();

  if (result.status === "error") {
    console.error(`\nRun failed: ${result.id}`);
    process.exit(2);
  }

  if (result.git?.branches?.length) {
    console.log("\nGit branches:", JSON.stringify(result.git.branches, null, 2));
  }
  console.log(`\nDone: ${result.status} (run ${result.id})`);
  process.exit(0);
} catch (err) {
  if (err instanceof CursorAgentError) {
    console.error(`Cursor agent error: ${err.message}`);
    console.error(`  retryable: ${err.isRetryable}`);
    console.error(`  code:      ${err.code ?? "(none)"}`);
    console.error(`  cause:     ${err.cause ?? "(none)"}`);
    process.exit(1);
  }
  throw err;
} finally {
  await agent?.[Symbol.asyncDispose]();
}
