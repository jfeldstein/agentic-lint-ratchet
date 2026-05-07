import { MissingRuntimeEnvError } from "./errors.mjs";

export function assertRequiredEnv(runtime, requiredEnv, env, hint) {
  const missing = requiredEnv.filter((key) => !env[key]?.trim());
  if (missing.length > 0) {
    throw new MissingRuntimeEnvError(runtime, missing, hint);
  }
}
