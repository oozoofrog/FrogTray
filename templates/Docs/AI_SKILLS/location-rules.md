# Location Rules

Apply this skill whenever Core Location, running/walking tracking, region monitoring, or location permissions are involved.

- Distinguish authorization status from accuracy authorization where applicable.
- Handle not determined, denied, restricted, authorized when in use, and authorized always.
- Do not assume high accuracy is always available.
- Separate permission request flow from active tracking flow.
- Keep `CLLocationManager` integration away from View code.
- Model degraded location quality explicitly if it affects UX.
- Consider battery impact for continuous tracking.
