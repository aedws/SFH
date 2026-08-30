# SFH repository workflow

- For user-authorized code or documentation changes, completion includes implementation, relevant tests, an explicit commit, push, reuse or creation of a pull request, merge into `main`, and verification of post-merge checks or deployment.
- Keep a pull request unmerged when tests fail, a required external check fails, or the user explicitly asks for review before merge.
- Read-only review, explanation, diagnosis, and status requests do not authorize repository mutations.
- Preserve the modular feature rules documented under `docs/architecture/` and update the wiki when a module contract or player-facing workflow changes.
- When the user requests a progress check, read the authoritative published SFH Notion planning page at `https://wobbly-pawpaw-1ff.notion.site/SFH-6b45b728004082af8a4a811ef0a1c5e9` first, give explicitly confirmed requirements a higher weight than provisional requirements, verify completion against the repository, and update `docs/index.md` plus `docs/development-status.md` with the source and calculation basis.
