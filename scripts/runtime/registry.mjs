import { UnsupportedRuntimeError } from "./errors.mjs";
import { cursorHarness } from "./cursor.mjs";
import { piHarness } from "./pi.mjs";

const DEFAULT_RUNTIME = "cursor";
const harnesses = [cursorHarness, piHarness];
const harnessById = new Map(harnesses.map((harness) => [harness.id, harness]));

export const supportedRuntimes = harnesses.map((harness) => harness.id);

export function resolveHarness(requested) {
  const runtime = requested?.trim() || DEFAULT_RUNTIME;
  const harness = harnessById.get(runtime);
  if (!harness) {
    throw new UnsupportedRuntimeError(runtime, supportedRuntimes);
  }
  return harness;
}
