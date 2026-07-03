# SHARED SCHEMA KNOWLEDGE BASE

**Generated:** 2026-07-02
**Scope:** `packages/shared/`

## OVERVIEW

Shared JSON schema contracts for trajectory and dataset artifacts. Treat these files as cross-boundary contracts between backend export, docs, fixtures, and downstream consumers.

## WHERE TO LOOK

| Task | Location | Notes |
|---|---|---|
| Trajectory shape | `trajectory_schema.json` | Must preserve required source metadata. |
| Dataset shape | `dataset_schema.json` | Must align with export metadata and dataset card expectations. |
| Backend implementation | `apps/api/app/schemas/`, `apps/api/app/services/exporter.py` | Keep schema docs and exported payloads compatible. |
| Developer docs | `docs/developer/data_schema.md`, `docs/developer/export_format.md` | Update when schema semantics change. |

## CONVENTIONS

- Prefer additive, backward-compatible schema evolution.
- Keep `schema_version` explicit in artifacts and examples.
- Do not remove required RDF provenance fields without coordinated API, migration, export, docs, and tests.
- Use JSON schema to document customer-facing contract intent, not temporary internal test shapes.

## ANTI-PATTERNS

- Do not loosen schemas so missing `source.input_device`, `source.runtime`, `source.simulator`, `source.robot`, or `source.task_name` can pass as training-ready data.
- Do not encode measured KPI fields as guaranteed when upstream systems only provide placeholders.
- Do not claim LeRobot/HDF5 compatibility from schema presence alone; exporter and trainer smoke evidence must support it.

## VALIDATION

```bash
uv run pytest -q apps/api/tests/test_api_contract.py apps/api/tests/test_exporter.py
git diff --check packages/shared docs/developer/data_schema.md docs/developer/export_format.md
```
