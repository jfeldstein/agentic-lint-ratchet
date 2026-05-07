export class MissingRuntimeEnvError extends Error {
  constructor(runtime, missing, hint) {
    const vars = missing.join(", ");
    super(
      `${runtime} runtime requires environment variables: ${vars}. ${hint}`.trim(),
    );
    this.name = "MissingRuntimeEnvError";
    this.runtime = runtime;
    this.missing = missing;
    this.hint = hint;
  }
}

export class UnsupportedRuntimeError extends Error {
  constructor(runtime, supported) {
    super(
      `Unsupported agent runtime: ${runtime}. Supported agents: ${supported.join(", ")}`,
    );
    this.name = "UnsupportedRuntimeError";
    this.runtime = runtime;
    this.supported = supported;
  }
}
