# HealthKit Rules

Apply this skill whenever HealthKit authorization, queries, workout data, or health-related UI flows are involved.

- Keep HealthKit access isolated behind {{HEALTHKIT_LAYER_NAME}}.
- Separate permission explanation UI from authorization request execution.
- Never assume authorization success.
- Re-check relevant authorization-dependent state when app becomes active if needed.
- Handle denied/restricted/notDetermined/authorized states explicitly.
- Keep HealthKit queries out of View code.
- Treat health-related data as privacy-sensitive.
