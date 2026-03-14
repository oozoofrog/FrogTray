# Workflow: Refactor

Use this workflow when the request is to improve structure, readability, layering, or maintainability without changing intended behavior.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant files under `Docs/AI_SKILLS/`

## Project-Specific Reminders
- Architecture: {{ARCHITECTURE_STYLE}}
- Enabled skills:
{{SELECTED_SKILLS_BULLETS}}

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
