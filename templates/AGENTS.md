# AGENTS.md for {{PROJECT_NAME}}

You are working in the {{PROJECT_NAME}} codebase scaffolded by SwiftNest.

## Start Here
- Inspect the relevant code before editing.
- Implement directly when the request is straightforward.
- Provide a brief plan first only when the task is ambiguous, risky, or explicitly asks for planning.
- Keep the diff minimal and reviewable.
- Run or describe verification before finishing.
- If the user asks for a review, lead with findings first.
- Review results must always be provided in Korean unless the user explicitly requests another language.

## Project Context
- Architecture: {{ARCHITECTURE_STYLE}}
- UI framework: {{UI_FRAMEWORK}}
- Networking boundary: {{NETWORK_LAYER_NAME}}
- Persistence boundary: {{PERSISTENCE_LAYER_NAME}}
- Logging system: {{LOGGING_SYSTEM}}
- Harness profile: {{HARNESS_PROFILE}}

## Required Reads
1. Read `Docs/AI_RULES.md`.
2. Read `Docs/AI_WORKFLOWS.md`.
3. Read the relevant files under `Docs/AI_SKILLS/`.
4. When the task matches a workflow below, read the corresponding file under `.swiftnest/workflows/`.

## Enabled Skills
{{SELECTED_SKILLS_BULLETS}}

## Workflow Entry Points
{{WORKFLOW_ROUTING}}

## Build and Test Commands
- Build: {{BUILD_COMMAND_SUMMARY}}
- Test: {{TEST_COMMAND_SUMMARY}}

## Feature Development Expectations
- Keep user-visible behavior, generated docs, and verification guidance aligned.
- Add or update tests for non-trivial CLI/runtime behavior changes.
- If SwiftNest generated repo-local agent bundles under `.agents/skills/`, refresh them through SwiftNest commands instead of editing them by hand.
- Keep diffs minimal and avoid unrelated refactors.

## Completion Expectations
- Summarize files changed.
- Summarize behavior impact.
- Mention tests run or explain why tests were not run.
- Call out risks or limitations briefly.
