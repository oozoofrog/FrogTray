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
{{SELECTED_SKILLS_BULLETS}}

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
