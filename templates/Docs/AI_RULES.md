# AI Rules for {{PROJECT_NAME}}

## Purpose
This document defines the mandatory implementation rules for AI agents working in the {{PROJECT_NAME}} codebase.

Agents must read this file before making changes.

---

## Project Context
- Project name: {{PROJECT_NAME}}
- Platform: iOS {{OPTIONAL_WATCHOS_LINE}}
- UI framework: {{UI_FRAMEWORK}}
- Architecture style: {{ARCHITECTURE_STYLE}}
- Minimum iOS version: {{MIN_IOS_VERSION}}
- Package manager: {{PACKAGE_MANAGER}}
- Testing framework: {{TEST_FRAMEWORK}}
- Lint/format tools: {{LINT_TOOLS}}
- Harness profile: {{HARNESS_PROFILE}}

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
- Networking must go through {{NETWORK_LAYER_NAME}}.
- Persistence must go through {{PERSISTENCE_LAYER_NAME}}.
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
- Prefer files under {{PREFERRED_FILE_LINE_LIMIT}} lines when practical.
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
- All network access must go through {{NETWORK_LAYER_NAME}}.
- Do not call remote APIs directly from Views.
- Parse and map responses in the appropriate layer.
- Handle timeout, cancellation, decoding failure, and server-side failure paths.

## Persistence Rules
- All storage access must go through {{PERSISTENCE_LAYER_NAME}}.
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
- Use {{LOGGING_SYSTEM}} for developer diagnostics.
- Do not add noisy logs without purpose.
- Prefer structured logs where supported.
- Never log secrets, tokens, raw personal data, or protected health data.

## Security / Privacy
- Do not hardcode secrets.
- Do not expose tokens or credentials in logs.
- Follow least-privilege access to APIs and device capabilities.
- Treat user privacy-sensitive data carefully.
- Respect {{PRIVACY_REQUIREMENTS}}.

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
{{PROFILE_GUIDANCE}}

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
