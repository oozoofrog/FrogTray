# AI Workflows for {{PROJECT_NAME}}

This document defines standard execution workflows for AI agents.

Scaffolded workflow entry files may also be generated under `.swiftnest/workflows/`. When present, treat those files as the task-specific execution entrypoints derived from this document.

## Workflow: Add Feature
1. Read `Docs/AI_RULES.md` and relevant `Docs/AI_SKILLS/*` files.
2. Summarize applicable rules.
3. Inspect existing implementation patterns before proposing new ones.
4. Propose a minimal implementation strategy.
5. Identify files to modify.
6. Implement in correct layer order:
   - model/domain
   - repository/service
   - presentation/viewmodel
   - view
7. Add/update tests.
8. Review actor isolation, `Sendable` boundaries, and legacy import risks for async code paths.
9. Summarize changes and remaining risks.

## Workflow: Fix Bug
1. State the bug in one sentence.
2. Identify the likely failing layer.
3. Describe the root cause hypothesis.
4. Confirm impacted state transitions / user flows.
5. Implement root-cause fix, not symptom-only patch.
6. Add regression test when practical.
7. Review for side effects, including cross-actor access and non-`Sendable` value movement.
8. Summarize what changed and why.

## Workflow: Refactor
1. Explain why refactor is needed.
2. Confirm no feature behavior should change unless stated.
3. Keep scope narrow.
4. Preserve public interfaces unless required.
5. Add/update tests to protect behavior.
6. Summarize before/after structure.

## Workflow: Permissions-Related Feature
1. Identify all relevant permission states.
2. Separate explanation UI, permission request trigger, and active feature behavior.
3. Handle denied/restricted/notDetermined/authorized states.
4. Consider app foreground re-entry.
5. Add state transition tests where practical.

## Workflow: Networking Change
1. Confirm API integration point.
2. Define request/response mapping clearly.
3. Handle decoding error, network failure, cancellation, and server-side failure.
4. Avoid leaking API models into unrelated layers.
5. Add repository/service tests where practical.

## Final Self-Review Checklist
- no force unwrap introduced
- no unrelated file changes
- no business logic moved into View
- async state updates are actor-safe
- actor isolation and `Sendable` boundaries were checked for changed async code
- `preconcurrency` imports or legacy APIs were reviewed when diagnostics were involved
- errors are not silently swallowed
- tests cover the intended behavior
- implementation matches existing project conventions

## Profile-Specific Review Additions
{{WORKFLOW_GUIDANCE}}
