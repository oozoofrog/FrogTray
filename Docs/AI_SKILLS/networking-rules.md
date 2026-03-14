# Networking Rules

Apply this skill whenever API calls, request/response modeling, retries, or remote sync behavior are involved.

- Route network access through APIClient + RemoteRepository.
- Keep transport models separate from UI-facing models when possible.
- Handle decoding failures explicitly.
- Handle server error and transport error distinctly if project style supports it.
- Consider timeout, retry, cancellation, and stale data behavior.
- Keep authentication/token logic consistent with existing project conventions.
