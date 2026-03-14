# iOS Architecture Rules

Apply this skill whenever the task touches app structure, screen composition, or responsibility boundaries.

- Preserve the current architectural style: MVVM with Repository pattern
- Keep Views presentation-focused.
- Keep business logic out of Views.
- Keep API and persistence concerns out of Views.
- Prefer dependency injection over hidden globals.
- Reuse existing abstractions before creating new ones.
- Avoid generic manager/helper types unless already established.
