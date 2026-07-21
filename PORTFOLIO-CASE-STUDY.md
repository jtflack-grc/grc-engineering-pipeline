# JT Flack: A GRC Engineering Pipeline, Built in Public

## What this is

I built an end-to-end assurance pipeline that takes an AWS S3 design from “the configuration looks right” to a set of claims another person can verify without relying on me. Terraform implements four NIST SP 800-53 Rev. 5 controls, policy as code tests them, CI blocks regressions, keyless signing protects the evidence, AWS-native services monitor the account, and OSCAL connects each control statement to the exact implementation and signed proof.

## The six-stage pipeline

1. **Compliant infrastructure:** Terraform enables encryption at rest (SC-28), blocks public access (AC-3), enforces versioning and required tags (CM-6), and writes access logs to a dedicated bucket (AU-3).
2. **Policy as code:** Rego unit tests exercise compliant and broken cases; Conftest evaluates the Terraform plan rather than trusting source text.
3. **Enforcement:** The `grc-gate` GitHub Actions check runs on pull requests, records machine-readable results, and fails closed when a control fails.
4. **Chain of custody:** The gate packages its outputs, records a SHA-256 digest, and signs the bundle keylessly with Cosign and GitHub Actions OIDC.
5. **Native monitoring:** CloudTrail and Security Hub capture activity and findings, with sanitized summaries and signed verification evidence.
6. **Auditor traversal:** An OSCAL profile states the four controls in scope; the component definition explains how each is implemented and links to the signed bundle.

## Proof

- **Capstone repository:** [grc-engineering-pipeline](https://github.com/jtflack-grc/grc-engineering-pipeline)
- **Capstone integration:** [pull request #1](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/1)
- **End-to-end green run:** [Terraform + OPA + Conftest + Trestle + Cosign](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29831090514)
- **All Terraform stages validated:** [infrastructure + monitoring + immutable vault](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256441)
- **Fresh signed policy evidence:** [generate, hash, sign, verify, publish](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256461)
- **Fresh signed native evidence:** [validate, hash, sign, verify, publish](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256580)
- **Compliant change accepted:** [green pull request](https://github.com/jtflack-grc/grc-engineering-club-week3/pull/1)
- **Noncompliant change blocked:** [red pull request](https://github.com/jtflack-grc/grc-engineering-club-week3/pull/2)
- **Six of six Rego tests:** [`opa-test-6of6.txt`](evidence/policy-tests/opa-test-6of6.txt)
- **Signed evidence produced:** [Week 4 workflow run](https://github.com/jtflack-grc/grc-engineering-club-week4/actions/runs/29193660339)
- **Chain verified:** [`verify-chain-intact.txt`](evidence/pull-request-gate/verify-chain-intact.txt) and the reproducible [verification script](scripts/verify-evidence.sh)
- **Tampering rejected:** [`verify-tamper-failed.txt`](evidence/pull-request-gate/verify-tamper-failed.txt)
- **OSCAL component:** [`component-definition.json`](oscal/component-definitions/grc-engineering-pipeline/component-definition.json)
- **Four-control OSCAL profile:** [`profile.json`](oscal/profiles/grc-engineering-pipeline/profile.json)
- **OSCAL validation:** [`trestle-validation.txt`](evidence/oscal-validation/trestle-validation.txt)
- **Reproducible evidence generation:** [`generate-signed-evidence.yml`](.github/workflows/generate-signed-evidence.yml)
- **Native monitoring implementation:** [`native-monitoring/`](native-monitoring/)
- **Immutable vault implementation:** [`immutable-vault/`](immutable-vault/)

## One claim, end to end

For SC-28, Terraform configures server-side encryption on both buckets. Rego asserts that the planned resources use an approved encryption algorithm. The pull-request gate records that result and signs the evidence bundle. The OSCAL component names the Terraform resources and links to that exact bundle. Running `scripts/verify-evidence.sh` proves the bundle still has its original digest and was signed by the expected Week 4 GitHub Actions workflow; it ends with `CHAIN INTACT`.

## What I would do next

I would move from this intentionally small demonstration to reusable modules and organization-wide guardrails: remote Terraform state with locking, KMS customer-managed keys, least-privilege deployment roles, protected environments, dependency and IaC scanning, and a longer centrally governed retention policy. I would also generate versioned OSCAL assessment packages from each release, add automated link checking, and schedule signature and retention re-verification.

## What I learned

The non-obvious lesson was that evidence quality is mostly about preserving relationships. A passing test is useful, but a control claim linked to the precise plan, workflow identity, digest, signature, and monitoring record is independently defensible. Keyless signing made that concrete: trust comes from the short-lived workload identity and transparency record, not from a long-lived private key that quietly becomes another control problem.
