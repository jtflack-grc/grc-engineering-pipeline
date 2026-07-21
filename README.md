# GRC Engineering Pipeline

[![GRC gate](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/workflows/grc-gate.yml/badge.svg)](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/workflows/grc-gate.yml)

An end-to-end, evidence-first demonstration of engineered assurance. Terraform defines compliant AWS storage; Rego tests the plan; GitHub Actions blocks noncompliant changes; Cosign protects the resulting evidence; AWS-native controls monitor activity; and OSCAL makes the control claims traversable by an assessor.

The detailed portfolio narrative is in [PORTFOLIO-CASE-STUDY.md](PORTFOLIO-CASE-STUDY.md).

## Pipeline

| Stage | Capability | Proof |
|---|---|---|
| 1 | Terraform implements SC-28, AC-3, CM-6, and AU-3 | [`terraform/`](terraform/) |
| 2 | Rego unit tests and Conftest evaluate the Terraform plan | [`policies/`](policies/), [`evidence/policy-tests/`](evidence/policy-tests/) |
| 3 | Pull requests are gated and fail closed | [green PR](https://github.com/jtflack-grc/grc-engineering-club-week3/pull/1), [blocked PR](https://github.com/jtflack-grc/grc-engineering-club-week3/pull/2) |
| 4 | Gate evidence is hashed and keyless-signed | [`evidence/signed-bundle/`](evidence/signed-bundle/) |
| 5 | CloudTrail and Security Hub provide native monitoring | [`evidence/native-monitoring/`](evidence/native-monitoring/) |
| 6 | OSCAL maps controls to resources and evidence | [`oscal/`](oscal/) |

## Verify locally

Prerequisites: Python 3, `jq`, and `cosign`. Conftest and OPA are needed for the policy checks.

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install compliance-trestle==4.2.0

cd oscal
trestle validate -f component-definitions/grc-engineering-pipeline/component-definition.json
trestle validate -f profiles/grc-engineering-pipeline/profile.json
cd ..

./scripts/verify-evidence.sh evidence/signed-bundle/evidence.tar.gz
```

The two OSCAL commands must report `VALID`; the evidence verifier must end with `CHAIN INTACT`.

Run the policy tests and plan gate:

```bash
opa test policies -v
conftest test evidence/policy-tests/terraform-plan.json --policy policies --namespace compliance.sc28_aws
conftest test evidence/policy-tests/terraform-plan.json --policy policies --namespace compliance.ac3_aws
conftest test evidence/policy-tests/terraform-plan.json --policy policies --namespace compliance.cm6_aws
```

## OSCAL traversal

1. Open the [profile](oscal/profiles/grc-engineering-pipeline/profile.json) and confirm it selects exactly `ac-3`, `au-3`, `cm-6`, and `sc-28` from the pinned NIST catalog.
2. Open the [component definition](oscal/component-definitions/grc-engineering-pipeline/component-definition.json) and find the `sc-28` implemented requirement.
3. Follow its `rel: evidence` link to `evidence/signed-bundle/evidence.tar.gz`.
4. Run the verifier above to confirm the SHA-256 digest and keyless signature.

No AWS deployment is required to review or validate the committed evidence. The optional Terraform deployment and Week 5 native monitoring resources can incur AWS charges; deploy them only in an account you control.
