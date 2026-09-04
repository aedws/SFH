# SFH repository workflow

- For user-authorized code or documentation changes, completion includes implementation, relevant tests, an explicit commit, push, reuse or creation of a pull request, merge into `main`, and verification of post-merge checks or deployment.
- Keep a pull request unmerged when tests fail, a required external check fails, or the user explicitly asks for review before merge.
- Read-only review, explanation, diagnosis, and status requests do not authorize repository mutations.
- Preserve the modular feature rules documented under `docs/architecture/` and update the wiki when a module contract or player-facing workflow changes.
- Keep release notes compressed by calendar day: use one outer `sfh-day` block per date in `docs/index.md` and `docs/development-status.md`, and append individual update topics as nested `sfh-bundle` blocks inside that day.
- Keep planner-facing default search rankings and quick-search groups in `docs/assets/search-priorities.json`; add new major systems there when their planning priority warrants discovery before a query is typed.
- When the user requests a progress check, read the authoritative published SFH Notion planning page at `https://wobbly-pawpaw-1ff.notion.site/Master-GDD-2026-09-02-04-14-00-3ce5b728004081bfa94fe42e4ed48767` first, give explicitly confirmed requirements a higher weight than provisional requirements, verify completion against the repository, and update `docs/index.md` plus `docs/development-status.md` with the source and calculation basis.
- Standing user authorization: for every future implementation, when a new enumerated gameplay or balance list is required, extend the shared Google Sheet without requesting separate approval. Keep row 1 as variable names, row 2 as Korean descriptions, row 3 onward as data, and preserve the live-test to locked-CSV workflow, Web payload, release metadata, and validation. Do not add Sheet structure when no new list is needed.
