# Rendered AI Harness Context

Profile: advanced

Skills: concurrency-rules, ios-architecture, logging-rules, networking-rules, swiftui-rules, testing-rules

Workflows: add-feature, fix-bug, refactor, build, onboarding-review, permissions, networking, review

<!-- AGENTS.md -->

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


<!-- AI_RULES.md -->

# AI Rules for FrogTray

## Purpose
This document defines the mandatory implementation rules for AI agents working in the FrogTray codebase.

Agents must read this file before making changes.

---

## Project Context
- Project name: FrogTray
- Platform: iOS 
- UI framework: SwiftUI
- Architecture style: MVVM with Repository pattern
- Minimum iOS version: iOS 17
- Package manager: Swift Package Manager
- Testing framework: XCTest
- Lint/format tools: SwiftLint, SwiftFormat
- Harness profile: advanced

---

## Global Priorities
When making trade-offs, prefer:
1. Correctness
2. Maintainability
3. Testability
4. Consistency with existing codebase
5. Performance
6. Speed of implementation

Do not optimize prematurely.

## Architecture Rules
- Respect the existing project architecture.
- Do not introduce a new architectural pattern unless explicitly requested.
- UI code must stay in the UI layer.
- Business logic must not live in View code.
- Networking must go through APIClient + RemoteRepository.
- Persistence must go through LocalRepository.
- Dependency boundaries must remain clear.
- Reuse existing patterns before introducing new abstractions.

### Layer Responsibilities
- View:
  - renders state
  - handles user interaction forwarding
  - contains minimal presentation-only logic
- ViewModel / Presentation layer:
  - prepares UI state
  - coordinates async work
  - maps domain results to UI-facing state
- Domain / UseCase layer:
  - contains business rules
  - should remain platform-light where practical
- Repository / Service layer:
  - coordinates API / storage access
- Infrastructure layer:
  - API client
  - database
  - OS integrations
  - system frameworks

## Code Change Scope
- Modify only files necessary for the task.
- Avoid unrelated refactors.
- Do not rename files/types/functions unless necessary.
- If a broader refactor is truly needed, explain why before doing it.
- Prefer minimal, reviewable diffs.

## Naming and Style
- Follow existing naming conventions in the repository.
- Prefer explicit, intention-revealing names.
- Avoid vague names like `Manager`, `Helper`, `Util` unless already established.
- Keep types and functions focused.
- One primary type per file unless local helper types are clearly justified.

## File Size and Complexity
- Prefer files under 300 lines when practical.
- Break up overly large views or view models before they become hard to review.
- Extract subviews/helpers only when they improve clarity.
- Avoid unnecessary abstraction layers.

## SwiftUI / UI Rules
- Views should primarily describe layout and bindings.
- Avoid embedding business decisions directly in SwiftUI `body`.
- If `body` becomes complex, extract subviews or computed properties.
- Keep presentation state explicit.
- Handle loading, success, empty, and error states where relevant.
- Do not trigger heavy work repeatedly from rendering paths.
- Follow existing navigation and presentation patterns.

## Concurrency Rules
- Use structured concurrency by default.
- Prefer `async/await` over callback pyramids where project-compatible.
- UI-facing state updates must happen on the appropriate actor, usually the main actor.
- Support cancellation for user-triggered async flows where relevant.
- Do not use detached tasks unless explicitly justified.
- Avoid race-prone shared mutable state.
- Consider repeated taps / repeated refresh / screen re-entry behavior.

## Error Handling Rules
- No silent failures unless intentionally documented.
- Represent recoverable errors in a user-visible or developer-visible way.
- Prefer typed errors or structured error mapping where established.
- Preserve underlying causes when useful for debugging.
- Do not swallow important errors inside broad `catch` blocks.

## Networking Rules
- All network access must go through APIClient + RemoteRepository.
- Do not call remote APIs directly from Views.
- Parse and map responses in the appropriate layer.
- Handle timeout, cancellation, decoding failure, and server-side failure paths.

## Persistence Rules
- All storage access must go through LocalRepository.
- Avoid leaking storage-specific concerns into UI code.
- Keep persistence writes deliberate and reviewable.
- Consider stale cache and missing data states where relevant.

## State Management Rules
- UI state should be explicit and testable.
- Prefer deterministic state transitions.
- Avoid hidden implicit state mutations.
- Distinguish:
  - initial
  - loading
  - success
  - empty
  - error
  - permission-denied / restricted states when applicable

## Permissions / OS Integration Rules
- Never assume permissions are granted.
- Always handle denied, restricted, and not-determined states where applicable.
- Re-check permission-dependent state after app lifecycle changes if relevant.
- Keep OS framework integrations behind clear boundaries.

## Testing Rules
- New non-trivial logic must include tests.
- Bug fixes should include regression tests when practical.
- Tests should validate behavior, not implementation trivia.
- Prefer deterministic tests.
- Avoid brittle timing-dependent tests unless necessary.
- Mock or fake external dependencies where appropriate.

## Logging / Diagnostics
- Use OSLog for developer diagnostics.
- Do not add noisy logs without purpose.
- Prefer structured logs where supported.
- Never log secrets, tokens, raw personal data, or protected health data.

## Security / Privacy
- Do not hardcode secrets.
- Do not expose tokens or credentials in logs.
- Follow least-privilege access to APIs and device capabilities.
- Treat user privacy-sensitive data carefully.
- Respect App Privacy disclosure and least-privilege data handling.

## Performance
- Do not move expensive work onto the main thread.
- Avoid unnecessary recomputation in rendering paths.
- Avoid excessive location / sensor usage unless required.
- Prefer measured optimization over speculative optimization.

## Forbidden Patterns
- No force unwrap in production code unless explicitly justified and truly safe.
- No networking directly inside View code.
- No persistence access directly inside View code.
- No unrelated refactor during feature implementation.
- No dead code left behind.
- No commented-out code in final output unless requested.
- No fake placeholders presented as complete implementation.

## Profile-Specific Guidance
- Require an explicit risks/limitations section.
- Be strict about state transitions, privacy, and performance-sensitive paths.
- Add regression tests for bug fixes and emphasize actor/thread correctness.

## Required Delivery Format for Agent Responses
For straightforward tasks:
1. Inspect relevant code and constraints first.
2. Implement directly when the request is clear.
3. Finish with:
   - files changed
   - behavior summary
   - tests added/updated or not run
   - risks / limitations
   - any rule deviations, if any

For ambiguous or high-risk tasks:
1. Applicable rules summary
2. Planned file changes
3. Short implementation strategy
4. Test plan
5. Then implement and finish with the same post-implementation summary.


<!-- AI_WORKFLOWS.md -->

# AI Workflows for FrogTray

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
- Verify privacy, performance, concurrency safety, and regression protection before finishing.


<!-- AI_PROMPT_ENTRY.md -->

# AI Prompt Entry Template for FrogTray

You are working on the FrogTray iOS codebase.

If `AGENTS.md` exists, treat it as the canonical Codex entrypoint.

Before doing implementation:
1. Read `Docs/AI_RULES.md`
2. Read `Docs/AI_WORKFLOWS.md`
3. Read the relevant files under `Docs/AI_SKILLS/` for this task

Default behavior:
1. Inspect the relevant code first
2. Implement directly when the request is straightforward
3. Provide a brief plan first only when the task is ambiguous, risky, or explicitly asks for planning
4. Keep the diff minimal and reviewable
5. Perform a self-review against the rules

Constraints:
- Follow the established architecture: MVVM with Repository pattern
- Use SwiftUI
- Networking must go through APIClient + RemoteRepository
- Persistence must go through LocalRepository
- Avoid unrelated refactors
- Do not place business logic in View code
- Add tests for non-trivial logic
- Keep the diff minimal and reviewable

Output format:
1. Files changed
2. Behavior summary
3. Tests added/updated or not run
4. Self-review
5. Risks / limitations

For ambiguous or high-risk tasks, include a short plan before implementation:
1. Applicable rules
2. Strategy
3. Files to change
4. Test plan


<!-- AI_SKILLS/concurrency-rules.md -->

# Concurrency Rules

Apply this skill whenever async work, task orchestration, cancellation, or actor correctness is involved.

- Prefer structured concurrency.
- Use `async/await` when consistent with the codebase.
- UI-facing state changes should happen on the correct actor.
- Support cancellation for user-triggered async operations where relevant.
- Consider re-entrancy and repeated invocation behavior.
- Verify `Sendable` boundaries when values move across actors or tasks.
- Do not call actor-isolated APIs from synchronous nonisolated contexts.
- Be explicit about `nonisolated` async behavior when execution semantics matter.
- Audit `preconcurrency` or legacy imports before suppressing concurrency diagnostics.
- Prefer predictable state transitions over ad hoc async mutation.


<!-- AI_SKILLS/ios-architecture.md -->

# iOS Architecture Rules

Apply this skill whenever the task touches app structure, screen composition, or responsibility boundaries.

- Preserve the current architectural style: MVVM with Repository pattern
- Keep Views presentation-focused.
- Keep business logic out of Views.
- Keep API and persistence concerns out of Views.
- Prefer dependency injection over hidden globals.
- Reuse existing abstractions before creating new ones.
- Avoid generic manager/helper types unless already established.


<!-- AI_SKILLS/logging-rules.md -->

# Logging Rules

Apply this skill whenever diagnostic logs or telemetry-related code is added or changed.

- Use OSLog consistently.
- Log meaningful diagnostic context only.
- Prefer structured logs when available.
- Never log secrets, access tokens, private user content, or protected health data.
- Keep logging noise low.


<!-- AI_SKILLS/networking-rules.md -->

# Networking Rules

Apply this skill whenever API calls, request/response modeling, retries, or remote sync behavior are involved.

- Route network access through APIClient + RemoteRepository.
- Keep transport models separate from UI-facing models when possible.
- Handle decoding failures explicitly.
- Handle server error and transport error distinctly if project style supports it.
- Consider timeout, retry, cancellation, and stale data behavior.
- Keep authentication/token logic consistent with existing project conventions.


<!-- AI_SKILLS/swiftui-rules.md -->

# SwiftUI Rules

Apply this skill whenever the task touches SwiftUI screens or UI state.

- Views should primarily describe UI.
- Avoid embedding heavy logic directly in `body`.
- Prefer explicit screen states.
- Extract subviews when complexity meaningfully decreases.
- Preserve existing navigation and presentation patterns.
- Avoid repeated side effects triggered by rerendering.


<!-- AI_SKILLS/testing-rules.md -->

# Testing Rules

Apply this skill whenever logic changes are introduced.

- New non-trivial logic requires tests.
- Prefer behavior-oriented tests.
- Use deterministic inputs and assertions.
- Mock or fake external dependencies.
- Test state transitions for view models/presenters.
- Add regression tests for bug fixes where practical.


<!-- workflows/add-feature.md -->

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


<!-- workflows/fix-bug.md -->

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


<!-- workflows/refactor.md -->

# Workflow: Refactor

Use this workflow when the request is to improve structure, readability, layering, or maintainability without changing intended behavior.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant files under `Docs/AI_SKILLS/`

## Project-Specific Reminders
- Architecture: MVVM with Repository pattern
- Enabled skills:
- `concurrency-rules`
- `ios-architecture`
- `logging-rules`
- `networking-rules`
- `swiftui-rules`
- `testing-rules`

## Execution Steps
1. State why the refactor is needed.
2. Confirm that behavior should stay unchanged unless the user asked otherwise.
3. Keep the scope narrow and local.
4. Preserve public interfaces unless the task requires changes.
5. Update tests only as needed to protect existing behavior.
6. Run the relevant verification commands.

## Verification Checklist
- public behavior stayed unchanged unless explicitly requested
- file/type movement improved clarity rather than adding abstraction
- tests still cover the important behavior
- diff stayed narrow

## Final Response
- files changed
- before/after structure summary
- tests run
- remaining risks or follow-up items


<!-- workflows/build.md -->

# Workflow: Build

Use this workflow when the task is to verify that the project still builds or tests after a change.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`

## Project-Specific Commands
Build command is not configured.
Discover the correct workspace/project, scheme, and destination before running a build.

Test command is not configured.
Discover the correct test entrypoint before running tests.

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


<!-- workflows/onboarding-review.md -->

# Workflow: Onboarding Review

Use this workflow immediately after SwiftNest onboarding to verify that the generated config, selected skills, and enabled workflows match the real repository.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. `config/project.yaml`
5. Relevant files under `Docs/AI_SKILLS/`

## Review Goals
1. Confirm that `config/project.yaml` reflects the current repository instead of an inferred idealized setup.
2. Confirm that the selected profile, skills, and workflows match the real codebase.
3. Update generated docs if the current SwiftNest setup is incomplete or inaccurate.

## Repository Reality Check
1. Inspect the top-level Xcode workspace/project or Swift package entrypoints.
2. Confirm the actual build and test commands for the repository.
3. Identify the real UI framework, architecture boundaries, and any domain-specific frameworks.
4. Note any feature areas that require additional rules, such as permissions, networking, HealthKit, or logging.

## Config Audit
Check these fields against the repository:
- `project_name`
- `optional_watchos_line`
- `ui_framework`
- `architecture_style`
- `min_ios_version`
- `package_manager`
- `test_framework`
- `lint_tools`
- `network_layer_name`
- `persistence_layer_name`
- `logging_system`
- `privacy_requirements`
- `preferred_file_line_limit`
- `healthkit_layer_name`
- `build_command`
- `test_command`

## Skill Audit
1. Confirm the current skill list matches the codebase.
2. Add missing skills when the repository clearly needs them.
3. Remove or de-prioritize skills that do not apply to the current project.

## Workflow Audit
1. Confirm the enabled workflows match how work is actually performed in this repository.
2. Recommend optional workflows such as `permissions`, `networking`, or `review` when they are relevant.
3. Keep `onboarding-review` available as the entry workflow for future onboarding refreshes.

## Regenerate If Needed
If config, skills, or workflows need to change:
1. Update `config/project.yaml`.
2. Re-run `swiftnest onboard` or `swiftnest init` with explicit profile, skills, or workflows.
3. Re-render `.swiftnest/` outputs if the selected workflows changed.

## Final Response
- confirmed assumptions about the repository
- changes made to config, skills, or workflows
- recommended additional workflows or skills
- remaining uncertainties or follow-up checks


<!-- workflows/permissions.md -->

# Workflow: Permissions

Use this workflow when the task touches device permissions such as location, notifications, camera, microphone, or HealthKit.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant permission-related skills under `Docs/AI_SKILLS/`

## Project-Specific Reminders
- Never assume authorization has already been granted.
- Enabled skills:
- `concurrency-rules`
- `ios-architecture`
- `logging-rules`
- `networking-rules`
- `swiftui-rules`
- `testing-rules`

## Execution Steps
1. Enumerate all permission states relevant to the task.
2. Separate explanation UI, request trigger, and active feature behavior.
3. Handle denied, restricted, not-determined, and authorized states explicitly.
4. Consider app foreground re-entry and stale permission state.
5. Add state transition tests where practical.

## Verification Checklist
- denied and restricted paths are handled
- success path still works after the permission grant
- lifecycle re-entry was considered
- tests or manual checks cover the state transitions

## Final Response
- permission states handled
- files changed
- verification performed
- remaining edge cases


<!-- workflows/networking.md -->

# Workflow: Networking

Use this workflow when the task changes API requests, response mapping, retries, or remote repository behavior.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant networking skills under `Docs/AI_SKILLS/`

## Project-Specific Reminders
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
1. Confirm the integration point and the layer that owns the change.
2. Define request, response, and mapping boundaries clearly.
3. Handle timeout, cancellation, decoding failure, and server-side failure.
4. Keep API models from leaking into unrelated layers.
5. Add repository/service tests where practical.

## Verification Checklist
- request/response mapping is isolated
- error cases are surfaced correctly
- cancellation and retry behavior were considered
- tests or manual checks cover the changed integration point

## Final Response
- files changed
- API behavior summary
- tests run
- remaining risks or compatibility notes


<!-- workflows/review.md -->

# Workflow: Review

Use this workflow when the task is to review code changes rather than implement new code.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant skills for the changed surface area

## Review Priorities
1. correctness regressions
2. state/concurrency hazards
3. architecture boundary violations
4. missing tests
5. maintainability risks

## Review Steps
1. Identify the changed surface area first.
2. Prioritize behavioral risk over style comments.
3. Check whether the change violates any project constraints.
4. Check whether tests exist for the non-trivial logic.
5. Report findings first, ordered by severity.

## Final Response
- findings first
- open questions or assumptions second
- change summary only after findings
