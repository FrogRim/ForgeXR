# API KNOWLEDGE BASE

**Generated:** 2026-07-02
**Scope:** `apps/api/`

## OVERVIEW

FastAPI backend for Robot Data Forge data contracts, collection sessions, evaluation, curation, dataset export, admin KPIs, and file-drop command bridging.

## STRUCTURE

```text
apps/api/
├── app/main.py          # FastAPI composition root
├── app/routers/         # OpenAPI request/response routes
├── app/models/          # SQLAlchemy persistence models
├── app/schemas/         # Pydantic API contracts
├── app/services/        # ForgeEval, ForgeCurate, export, proof, sync, usability
├── app/adapters/        # IsaacLab primary and MockSim fallback adapters
├── app/collectors/      # Recorder and OpenXR metadata helpers
├── alembic/             # DB migrations
└── tests/               # pytest regression and proof tests
```

## WHERE TO LOOK

| Task | Location | Notes |
|---|---|---|
| API registration | `app/main.py` | Add routers here only after schema/model/service surfaces exist. |
| Request surface | `app/routers/*.py` | Keep errors explicit and OpenAPI-visible. |
| DB model changes | `app/models/`, `alembic/versions/` | Include Alembic migration for schema changes. |
| API schemas | `app/schemas/` | Keep response shape aligned with frontend `apps/web/lib/types.ts`. |
| Evaluation | `app/services/evaluator.py` | Preserve failure taxonomy and quality/usability separation. |
| Curation | `app/services/curator.py` | Accepted/rejected reasons are product evidence. |
| Export/card | `app/services/exporter.py`, `app/services/dataset_card.py` | Never hide limitations for simulation/generated data. |
| Adapter selection | `app/adapters/factory.py` | `IsaacLabAdapter` primary; `MockSimAdapter` fallback must be explicit. |
| File-drop bridge | `app/routers/file_drop.py` | Local constrained CLI runner; no UI-owned verdicts. |

## CONVENTIONS

- Keep SQLAlchemy model, Pydantic schema, router response, and tests in one change when API contracts move.
- Required trajectory source metadata cannot be optional in accepted/exported data.
- Unsupported export formats must fail clearly, not degrade to placeholder success.
- File-drop subprocess calls must remain argv-list, `shell=False`, repo-root confined, timeout/cap protected, and verifier-source-of-truth.
- Tests live under `apps/api/tests`; root pytest config already sets `pythonpath = ["apps/api"]`.

## ANTI-PATTERNS

- Do not merge operator outcome and evaluator success into one flag.
- Do not mark replay/action gates or trainer smoke as passed unless evidence exists.
- Do not weaken rejection reasons to make curation pass.
- Do not make `MockSimAdapter` look like primary Isaac evidence.
- Do not add production auth, billing, reward, or real robot control.

## COMMANDS

```bash
uv run pytest -q apps/api/tests
uv run pytest -q apps/api/tests/test_api_contract.py
uv run pytest -q apps/api/tests/test_evaluator.py apps/api/tests/test_curator.py
uv run python -m compileall -q apps/api/app apps/api/tests scripts
uvx ruff check scripts apps/api
DATABASE_URL=sqlite:///./rdf_dev.db uv run uvicorn app.main:app --app-dir apps/api --reload
```
