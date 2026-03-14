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
