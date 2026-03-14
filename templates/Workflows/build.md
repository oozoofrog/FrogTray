# Workflow: Build

Use this workflow when the task is to verify that the project still builds or tests after a change.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`

## Project-Specific Commands
{{BUILD_COMMAND_BLOCK}}

{{TEST_COMMAND_BLOCK}}

## Execution Steps
1. Prefer the configured commands above when they are present.
2. If no explicit command is configured, inspect the repository and determine the correct build/test entrypoint before running anything.
3. Record which command actually ran.
4. Capture the pass/fail result and the first actionable failure if the build breaks.

## Verification Checklist
- build command is recorded exactly
- test command is recorded exactly when run
- failures are summarized by root error, not raw log spam
- if nothing ran, the reason is explicit

## Final Response
- commands run
- result
- first actionable failure, if any
- suggested next step if verification failed
