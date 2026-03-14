# AGENTS.md for FrogTray

You are working in the FrogTray codebase scaffolded by SwiftNest.

## Start Here
- Inspect the relevant code before editing.
- Implement directly when the request is straightforward.
- Provide a brief plan first only when the task is ambiguous, risky, or explicitly asks for planning.
- Keep the diff minimal and reviewable.
- Run or describe verification before finishing.
- If the user asks for a review, lead with findings first.
- Review results must always be provided in Korean unless the user explicitly requests another language.

## Project Context
- Architecture: MVVM with Repository pattern
- UI framework: SwiftUI
- Networking boundary: APIClient + RemoteRepository
- Persistence boundary: LocalRepository
- Logging system: OSLog
- Harness profile: advanced

## Required Reads
1. Read `Docs/AI_RULES.md`.
2. Read `Docs/AI_WORKFLOWS.md`.
3. Read the relevant files under `Docs/AI_SKILLS/`.
4. When the task matches a workflow below, read the corresponding file under `.swiftnest/workflows/`.

## Enabled Skills
- `concurrency-rules`
- `ios-architecture`
- `logging-rules`
- `networking-rules`
- `swiftui-rules`
- `testing-rules`

## Workflow Entry Points
- `add-feature`: Use for new features or visible behavior additions. Read `.swiftnest/workflows/add-feature.md`.
- `fix-bug`: Use for bug fixes and regression repairs. Read `.swiftnest/workflows/fix-bug.md`.
- `refactor`: Use for structure-only changes that preserve behavior. Read `.swiftnest/workflows/refactor.md`.
- `build`: Use for build or test verification work. Read `.swiftnest/workflows/build.md`.
- `onboarding-review`: Use after onboarding to verify config, selected skills, and workflows against the real repository. Read `.swiftnest/workflows/onboarding-review.md`.
- `permissions`: Use when device authorization states are part of the task. Read `.swiftnest/workflows/permissions.md`.
- `networking`: Use for request/response and remote repository changes. Read `.swiftnest/workflows/networking.md`.
- `review`: Use for findings-first code review tasks. Read `.swiftnest/workflows/review.md`.

## Build and Test Commands
- Build: not configured; inspect the repository build entrypoint first
- Test: not configured; inspect the repository test entrypoint first

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
