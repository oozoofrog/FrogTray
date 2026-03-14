# Workflow: Networking

Use this workflow when the task changes API requests, response mapping, retries, or remote repository behavior.

## Required Reads
1. `AGENTS.md`
2. `Docs/AI_RULES.md`
3. `Docs/AI_WORKFLOWS.md`
4. Relevant networking skills under `Docs/AI_SKILLS/`

## Project-Specific Reminders
- Networking boundary: {{NETWORK_LAYER_NAME}}
- Persistence boundary: {{PERSISTENCE_LAYER_NAME}}
- Enabled skills:
{{SELECTED_SKILLS_BULLETS}}

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
