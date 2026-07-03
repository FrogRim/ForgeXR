# WEB KNOWLEDGE BASE

**Generated:** 2026-07-02
**Scope:** `apps/web/`

## OVERVIEW

Next.js App Router frontend for inspecting RDF tasks, episodes, datasets, admin KPIs, trajectory summaries, and the MVP-5B file-drop alpha surface.

## STRUCTURE

```text
apps/web/
├── app/                 # App Router pages
├── components/common/   # API state, tables, status UI
├── components/dashboard/# KPI display components
├── components/replay/   # Trajectory display helpers
├── lib/api.ts           # FastAPI client functions
├── lib/types.ts         # API-facing TypeScript types
└── styles/globals.css   # Global styling
```

## WHERE TO LOOK

| Task | Location | Notes |
|---|---|---|
| API calls | `lib/api.ts` | Uses `NEXT_PUBLIC_API_BASE_URL` or `http://localhost:8000`. |
| API types | `lib/types.ts` | Mirror FastAPI schemas; avoid invented frontend-only truth fields. |
| Navigation shell | `app/layout.tsx` | Keep app routes discoverable. |
| File-drop UI | `app/file-drop/page.tsx` | Display CLI/verifier evidence; do not compute verdicts. |
| Admin KPIs | `app/admin/page.tsx`, `components/dashboard/` | Show measured/placeholder state honestly. |
| Shared UI states | `components/common/` | Prefer existing status/table patterns. |

## CONVENTIONS

- The backend CLI/verifier owns PASS/FAIL and `VERIFIED`; UI only renders structured evidence and exit codes.
- Keep copy precise: generated/digital-twin/sample data is not actual external partner robot data.
- Use restrained operational UI patterns; this is a data QA tool, not a marketing landing page.
- Match API contract changes with `lib/types.ts` and `lib/api.ts`.
- Frontend has lint/build scripts but no test script in `package.json`.

## ANTI-PATTERNS

- Do not add in-browser trust verdict calculation.
- Do not imply Pake, local browser, or desktop shell rewrites TrustPacks or verifier output.
- Do not claim hardware readiness, live UR/Franka/ROS2 support, external partner evaluation, or policy uplift from the UI.
- Do not introduce new visual systems when existing common components fit.

## COMMANDS

```bash
cd apps/web && npm run dev
cd apps/web && npm run lint
cd apps/web && npm run build
```
