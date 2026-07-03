# SCRIPTS KNOWLEDGE BASE

**Generated:** 2026-07-02
**Scope:** `scripts/`

## OVERVIEW

Operational CLIs for RDF proof generation, independent verification, file-drop evaluation, HDF5 export, live/runtime smoke checks, teleop diagnostics, and package claim scans.

## WHERE TO LOOK

| Task | Location | Notes |
|---|---|---|
| File-drop alpha | `rdf_file_drop_evaluator.py`, `verify_rdf_file_drop_evaluator_run.py` | Producer and independent verifier must stay separable. |
| MVP-0/MVP-1 proof | `run_data_trust_layer_proof.py`, `run_mvp0_offline_diagnostics.py`, `run_mvp1_*` | Preserve learning-ready claim boundary. |
| MVP-2 learning evidence | `run_mvp2_*`, `verify_mvp2_package.py` | Do not reuse spent held-out ranges for tuning. |
| HDF5/export | `export_rdf_to_hdf5.py`, `inspect_rdf_hdf5.py` | Trainer/load smoke matters more than file existence. |
| Runtime/teleop diagnostics | `check_rdf_runtime_env.py`, `verify_latest_rdf_recording.py`, `analyze_teleop_calibration.py` | Quest/OpenXR/HMD stays experimental adapter evidence. |
| Public/partner proof | `run_external_robot_data_ingest_eval_v0.py`, `run_rdf_public_dataset_trustpack_generator.py`, `scan_rdf_trustpack_html_claims.py` | Non-claim boundaries are product requirements. |

## CONVENTIONS

- Prefer `argparse`, `main() -> int`, and `if __name__ == "__main__": raise SystemExit(main())`.
- Keep verifier scripts independent from producer service imports when they validate generated packages.
- Generated proof packages must include limitations, provenance, artifact indexes, and reproducible commands.
- Fail closed on missing metadata, malformed JSON, unsupported profiles, forbidden claims, path traversal, and hash drift.
- Use stable JSON output for machine-readable proof reports where possible.

## ANTI-PATTERNS

- Do not make scripts silently repair trust evidence to pass verification.
- Do not let cached `preflight_result.json` override recomputed source evidence.
- Do not delete arbitrary output directories without managed-marker or artifact-root confinement.
- Do not describe generated fixtures as actual external/partner robot logs.
- Do not introduce shell injection risk; API bridge callers expect argv-list safe commands.

## COMMANDS

```bash
uv run python scripts/rdf_file_drop_evaluator.py profiles list --json
uv run python scripts/rdf_file_drop_evaluator.py preflight --input-path <drop> --profile-id <profile> --json
uv run python scripts/rdf_file_drop_evaluator.py evaluate --input-path <drop> --profile-id <profile> --json
uv run python scripts/verify_rdf_file_drop_evaluator_run.py <run_path> --json
uv run python -m compileall -q scripts
uvx ruff check scripts
```
