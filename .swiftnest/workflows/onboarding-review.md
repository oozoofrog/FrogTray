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
