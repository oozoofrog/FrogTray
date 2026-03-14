# Workflow: Add Feature

Use this workflow when adding a new product capability or expanding an existing user flow.

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
1. Inspect the current implementation patterns for the affected area.
2. Define the minimum user-visible behavior change.
3. Identify the layer order for the change:
   - model/domain
   - repository/service
   - presentation/viewmodel
   - view
4. Implement the smallest reviewable diff that satisfies the behavior.
5. Add or update tests for non-trivial logic.
6. Run the relevant verification commands.

## Verification Checklist
- new behavior is reachable through the intended UI flow
- no unrelated refactor slipped in
- actor/state transition risks were checked for async work
- build and tests were run or explicitly skipped with reason

## Final Response
- files changed
- behavior summary
- tests run
- risks or limitations
