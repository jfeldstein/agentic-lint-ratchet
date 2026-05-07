import { Agent, CursorAgentError } from "@cursor/sdk";
import { assertRequiredEnv } from "./env.mjs";

const CURSOR_SETUP_HINT =
  "CURSOR_API_KEY is required. Add a repository secret named CURSOR_API_KEY (Cursor Dashboard -> Integrations or team service account).";

export const cursorHarness = {
  id: "cursor",
  requiredEnv: ["CURSOR_API_KEY"],
  validateEnv(env) {
    assertRequiredEnv("cursor", this.requiredEnv, env, CURSOR_SETUP_HINT);
  },
  async run({ cwd, prompt, env, stdout, stderr }) {
    const apiKey = env.CURSOR_API_KEY.trim();
    const modelId = env.CURSOR_MODEL || "composer-2";

    let agent;
    try {
      agent = await Agent.create({
        apiKey,
        model: { id: modelId },
        local: { cwd },
      });

      stdout.write(`Agent started: ${agent.agentId}\n`);
      const run = await agent.send(prompt);
      stdout.write(`Run started: ${run.id}\n`);

      for await (const event of run.stream()) {
        if (event.type === "assistant") {
          for (const block of event.message.content) {
            if (block.type === "text" && block.text) {
              stdout.write(block.text);
            }
          }
        } else if (event.type === "tool_use") {
          stdout.write(`\n[tool] ${event.name}\n`);
        }
      }

      const result = await run.wait();

      if (result.status === "error") {
        stderr.write(`\nRun failed: ${result.id}\n`);
        return 2;
      }

      if (result.git?.branches?.length) {
        stdout.write(`\nGit branches: ${JSON.stringify(result.git.branches, null, 2)}\n`);
      }
      stdout.write(`\nDone: ${result.status} (run ${result.id})\n`);
      return 0;
    } catch (err) {
      if (err instanceof CursorAgentError) {
        stderr.write(`Cursor agent error: ${err.message}\n`);
        stderr.write(`  retryable: ${err.isRetryable}\n`);
        stderr.write(`  code:      ${err.code ?? "(none)"}\n`);
        stderr.write(`  cause:     ${err.cause ?? "(none)"}\n`);
        return 1;
      }
      throw err;
    } finally {
      await agent?.[Symbol.asyncDispose]();
    }
  },
};
