# AI Prompt Entry Template for {{PROJECT_NAME}}

You are working on the {{PROJECT_NAME}} iOS codebase.

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
- Follow the established architecture: {{ARCHITECTURE_STYLE}}
- Use {{UI_FRAMEWORK}}
- Networking must go through {{NETWORK_LAYER_NAME}}
- Persistence must go through {{PERSISTENCE_LAYER_NAME}}
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
