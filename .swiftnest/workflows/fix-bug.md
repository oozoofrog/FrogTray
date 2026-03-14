# Workflow: Fix Bug

Use this workflow when the task is to correct broken behavior, crashes, incorrect state transitions, or regressions.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant files under `Docs/AI_SKILLS/`

## Project-Specific Reminders
- Architecture: MVVM with Repository pattern
- UI framework: SwiftUI
- Networking boundary: APIClient + RemoteRepository
- Persistence boundary: LocalRepository
- Enabled skills:
- `concurrency-rules`
- `ios-architecture`
- `logging-rules`
- `networking-rules`
- `swiftui-rules`
- `testing-rules`

## Execution Steps
1. State the bug in one sentence.
2. Identify the failing layer or boundary first.
3. Confirm the root-cause hypothesis before patching.
4. Implement the root-cause fix, not a symptom-only workaround.
5. Add a regression test when practical.
6. Run the relevant verification commands.

## Verification Checklist
- bug no longer reproduces in the intended flow
- no unrelated behavior changed
- async/state side effects were checked
- regression protection was added when practical

## Final Response
- files changed
- root cause and fix summary
- tests run
- remaining risks or limitations
