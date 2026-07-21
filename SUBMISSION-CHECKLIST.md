# GRC Engineering Club prize submission checklist

Deadline: **July 31, 2026**. Submission endpoint: [cert.grcengclub.com/challenge](https://cert.grcengclub.com/challenge).

## Technical qualification

| Requirement | Public implementation | Public proof | Status |
|---|---|---|---|
| `terraform validate` | [`terraform/`](terraform/), [`native-monitoring/`](native-monitoring/), [`immutable-vault/`](immutable-vault/) | [All three Terraform stages green](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256441) | Complete |
| Conftest | [`policies/`](policies/) | [Green gate](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29831090514), [6/6 OPA evidence](evidence/policy-tests/opa-test-6of6.txt) | Complete |
| `trestle validate` | [`oscal/`](oscal/) | [`trestle-validation.txt`](evidence/oscal-validation/trestle-validation.txt) | Complete |
| Cosign verification | [`scripts/verify-evidence.sh`](scripts/verify-evidence.sh) | [`sc28-traversal.txt`](evidence/oscal-validation/sc28-traversal.txt), [fresh policy signing](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256461), [fresh native signing](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256580) | Complete |
| Vault upload | [`immutable-vault/`](immutable-vault/) | `evidence/immutable-vault-upload-summary.json` after authenticated execution | **Execution pending** |

## Portfolio proof

- [x] Public capstone repository
- [x] Six-stage case study linked at the top of the README
- [x] Green and blocked pull requests linked
- [x] OPA test output linked
- [x] `CHAIN INTACT` output linked
- [x] Trestle `VALID` output linked
- [x] Honest next-steps and learning sections
- [ ] Add the sanitized immutable-vault upload summary after the authenticated run
- [ ] Submit the final repository at the challenge endpoint before July 31
- [ ] Publish the optional LinkedIn post and tag GRC Engineering Club with `#GRCEngClubChallenge`

## Final pre-submission review

Before submitting, verify that all Actions workflows are green, follow every case-study link in a private browser window, confirm no credentials or account identifiers appear in the repository, and ensure the vault proof says `upload_verified: true` with future `RetainUntilDate` values.
