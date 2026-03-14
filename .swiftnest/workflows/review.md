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
