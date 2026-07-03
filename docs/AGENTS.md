# DOCS KNOWLEDGE BASE

**Generated:** 2026-07-02
**Scope:** `docs/`

## OVERVIEW

Korean-first documentation for product scope, developer contracts, proof packages, buyer-facing claims, desktop/file-drop usage, partner intake, and published narrative.

## STRUCTURE

```text
docs/
├── developer/       # Source-of-truth implementation docs, worklog, debugging guide
├── partner_intake/  # File-drop request docs, sample drops, intake runbooks
├── desktop/         # Pake/local desktop shell docs
├── buyer/           # Buyer-facing reports and claim-limited narratives
├── proof/           # Frozen proof packages and verifier evidence
├── experiments/     # Experimental HMD/XR notes
└── archive/         # Historical docs; do not treat as current source of truth
```

## WHERE TO LOOK

| Task | Location | Notes |
|---|---|---|
| Project truth | `developer/project_instructions.md` | MVP scope, no-go, primary proof path, claim boundaries. |
| API contracts | `developer/api_spec.md` | Update with API surface changes. |
| Data contracts | `developer/data_schema.md`, `developer/export_format.md` | Update with schema/export changes. |
| Debug flow | `developer/debugging_guide.md` | Update when user-run/debug steps change. |
| Work history | `developer/worklog.md` | Append detailed execution evidence after each task. |
| Partner intake | `partner_intake/` | Keep external/real/hardware claims explicit and limited. |
| Proof packages | `proof/` | Treat as evidence artifacts; verify before citing. |

## CONVENTIONS

- Markdown under `docs/` is Korean by default.
- Keep code identifiers, commands, paths, API names, JSON keys, model names, and package names in English.
- After work, update `docs/developer/worklog.md`; update `Handoff.md` at repo root with compact current state.
- If API, schema, roadmap, frontend scope, user execution steps, or debugging flow changes, update the corresponding developer doc in the same work unit.
- Buyer/partner docs must state limitations and avoid unearned real-world readiness claims.

## ANTI-PATTERNS

- Do not publish customer private data, private task specs, credentials, or unverified partner logs.
- Do not let archive docs override `docs/developer/project_instructions.md`.
- Do not describe simulation-only, digital-twin, generated, or sample-drop evidence as real robot validation.
- Do not claim policy uplift without MVP-2 evidence.
- Do not hide unsupported export, verifier, or HDF5 limitations.

## COMMANDS

```bash
rg "real robot|external partner|policy uplift|hardware readiness" docs
uv run python scripts/scan_rdf_trustpack_html_claims.py --package-dir <proof_package> --write-report
git diff --check docs
```
