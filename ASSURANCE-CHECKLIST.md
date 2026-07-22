# Assurance verification checklist

This matrix gives a reviewer a direct path from each assurance capability to its implementation and independently verifiable proof.

## Technical verification

| Capability | Implementation | Evidence | Result |
|---|---|---|---|
| Terraform validation | [`terraform/`](terraform/), [`native-monitoring/`](native-monitoring/), [`immutable-vault/`](immutable-vault/) | [All three Terraform stages green](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256441) | Verified |
| Policy as code | [`policies/`](policies/) | Four Conftest namespaces and [8/8 OPA evidence](evidence/policy-tests/opa-test-8of8.txt) | Verified |
| OSCAL schema validation | [`oscal/`](oscal/) | [`trestle-validation.txt`](evidence/oscal-validation/trestle-validation.txt) | Verified |
| Signed evidence chain | [`scripts/verify-evidence.sh`](scripts/verify-evidence.sh) | [`sc28-traversal.txt`](evidence/oscal-validation/sc28-traversal.txt), [canonical `main` policy signing](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29884555352), [fresh native signing](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256580) | Verified |
| Assurance graph | [`scripts/verify-assurance-graph.sh`](scripts/verify-assurance-graph.sh) | Four-control scope, OSCAL links, signed manifest, workflow identity, committed hashes, and vault proof are checked together | Verified |
| Immutable preservation | [`immutable-vault/`](immutable-vault/) | [`immutable-vault-upload-summary.json`](evidence/immutable-vault-upload-summary.json): canonical archive hash matching the committed sidecar, `upload_verified: true`, version IDs, and recorded GOVERNANCE-retention metadata | Verified |

## Evidence quality

- [x] Six-stage case study is linked at the top of the README
- [x] Passing and blocked pull requests in this capstone repository demonstrate enforcement behavior
- [x] OPA and Conftest results are retained
- [x] `CHAIN INTACT` verification is reproducible
- [x] Trestle `VALID` output is retained
- [x] Sanitized native-monitoring evidence is separated from raw cloud data
- [x] Immutable-vault proof contains hashes and retention metadata without account or bucket identifiers
- [x] Case study includes honest limitations, next steps, and lessons learned

## Reviewer spot check

Run `scripts/verify-assurance-graph.sh`, follow the case-study links in a private browser window, confirm the Actions runs remain visible, and verify that no credentials or cloud-account identifiers are published.
