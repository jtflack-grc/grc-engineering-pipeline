# Requirements traceability

This matrix maps the original six-week challenge requirements to their implementation, retained evidence, and reproduction path. “Verified” means the implementation and supporting proof are present in this repository or linked to a preserved GitHub execution record. Optional stretch goals are identified rather than represented as mandatory.

## Week 1: Compliant infrastructure

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| Two S3 buckets | [`aws_s3_bucket.primary`](terraform/main.tf) and [`aws_s3_bucket.log`](terraform/main.tf) | [`terraform-plan.json`](evidence/policy-tests/terraform-plan.json) | Inspect the two `aws_s3_bucket` plan resources | Verified |
| AES-256 encryption on both buckets | Two explicit server-side encryption configuration resources | Plan plus SC-28 policy result in the [canonical signed bundle](evidence/signed-bundle/) | Run the SC-28 Conftest command | Verified |
| All four public-access-block settings | Public-access-block resources for both buckets | Plan plus AC-3 result | Run the AC-3 Conftest command | Verified |
| Primary-bucket versioning | `aws_s3_bucket_versioning.primary` | Terraform and plan | `terraform validate`; inspect plan | Verified |
| Required default tags | Provider tags for Project, Environment, ManagedBy, and ComplianceScope | Terraform and CM-6 result | Run the CM-6 Conftest command | Verified |
| Dedicated access logging | Ownership controls, log-delivery ACL, and bucket logging with explicit dependencies | Terraform, plan, and AU-3 result | Run the AU-3 Conftest command | Verified |
| Machine-readable SC-28 attestation | `encryption_algorithm` Terraform output | [`terraform/outputs.tf`](terraform/outputs.tf) | Inspect output or run the credentialed [`verify.sh`](terraform/verify.sh) after deployment | Verified |
| Terraform validates | All three Terraform roots are checked in CI | [Comprehensive validation run](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29832256441) | Run the three-directory validation loop in the README | Verified |

## Week 2: Policy as code

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| SC-28 encryption policy | [`sc28_encryption_aws.rego`](policies/sc28_encryption_aws.rego) | Passing and failing Conftest transcripts | Run SC-28 against the committed plan | Verified |
| AC-3 public-access policy | [`ac3_no_public_aws.rego`](policies/ac3_no_public_aws.rego) | Passing Conftest transcript | Run AC-3 against the committed plan | Verified |
| CM-6 configuration policy | [`cm6_required_tags_aws.rego`](policies/cm6_required_tags_aws.rego) | Passing Conftest transcript | Run CM-6 against the committed plan | Verified |
| Positive and negative unit tests | Four policy test files cover compliant and noncompliant cases | [`opa-test-8of8.txt`](evidence/policy-tests/opa-test-8of8.txt) | `opa test policies -v` | Verified, exceeds 6/6 requirement |
| Real Week 1 plan passes | Committed Terraform plan is evaluated rather than source text | Three original passing transcripts plus canonical four-control bundle | Run the four Conftest commands | Verified |
| Broken SC-28 plan fails with remediation | Negative fixture omits matching encryption | [`conftest-sc28-broken-fail.txt`](evidence/policy-tests/conftest-sc28-broken-fail.txt) | Review the nonzero result and remediation message | Verified |

## Week 3: Pull-request enforcement

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| Run on pull requests to `main` | [`grc-gate.yml`](.github/workflows/grc-gate.yml) | [Green PR](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/7) and [blocked PR](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/15) | Inspect workflow trigger and PR checks | Verified |
| Pinned policy tooling | Checked downloads and immutable Action commit SHAs | Workflow source | Inspect Conftest/OPA checksum steps and `uses` references | Verified, hardened |
| Run every claimed policy | SC-28, AC-3, AU-3, and CM-6 namespaces execute | Canonical manifest and failed-decision manifest | Inspect the manifests or run Conftest | Verified |
| Fail closed | Final enforcement returns nonzero on a failed control | [PR #15](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/15) | Inspect the final failed workflow step | Verified |
| Preserve pass and fail results | Evidence is captured before the final gate decision | [Signed failure proof](evidence/pull-request-gate/signed-failure/) | Verify the archive sidecar and inspect its manifest | Verified |
| Green and red PR demonstrations | Compliant change merged; SC-28 regression closed unmerged | [PR #7](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/7), [PR #15](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/15) | Review their checks and disposition | Verified |
| Branch protection | Required `grc-gate / grc-gate` check blocks merge | Closed negative-control PR | Inspect blocked PR checks | Verified |
| Generate the Terraform plan in CI with AWS OIDC | Optional stretch goal | Committed reviewed plan used instead | Not claimed | Not implemented by design |

## Week 4: Signed, tamper-evident evidence

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| Bundle policy evidence | Workflow packages plan, policy sources, results, hashes, tool versions, and manifest | [`generated-evidence.tar.gz`](evidence/signed-bundle/generated-evidence.tar.gz) | List or extract archive contents | Verified |
| Record SHA-256 digest | Sidecar accompanies every canonical archive | [`generated-evidence.tar.gz.sha256`](evidence/signed-bundle/generated-evidence.tar.gz.sha256) | `sha256sum -c generated-evidence.tar.gz.sha256` | Verified |
| Keyless Cosign signing | GitHub Actions OIDC identity signs each bundle | Canonical and failed-decision Cosign bundles | Run [`verify-evidence.sh`](scripts/verify-evidence.sh) | Verified |
| Verify issuer and workflow identity | Verifier constrains GitHub OIDC issuer and workflow identity | Script and verification transcripts | Run the verifier | Verified |
| Preserve evidence on failed gates | Workflow signs and publishes before final enforcement | [Failed run](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/30218444910), [durable committed proof](evidence/pull-request-gate/signed-failure/) | Verify archive hash; inspect manifest conclusion `fail` | Verified |
| Detect tampering | One-byte changes produce a digest mismatch and nonzero exit | [`verify-tamper-failed.txt`](evidence/pull-request-gate/verify-tamper-failed.txt) | Repeat against a copied archive | Verified |
| Preserve in an immutable vault | Private, encrypted, versioned Object Lock bucket | [`immutable-vault/`](immutable-vault/), [sanitized upload proof](evidence/immutable-vault-upload-summary.json) | Review exact-version retrieval, hashes, and retention | Verified stretch goal |

## Week 5: Native cloud monitoring

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| Multi-region CloudTrail | `aws_cloudtrail.account_trail` | Terraform plus sanitized status summary | Inspect `is_multi_region_trail` and captured status | Verified |
| Management events enabled | CloudTrail event selector includes management events | [`native-monitoring/main.tf`](native-monitoring/main.tf) | Inspect event selector | Verified |
| Encrypted private log bucket | Encryption, versioning, and all four public-access blocks | Terraform | Run Terraform validation | Verified |
| Log-file validation | `enable_log_file_validation = true` | [`cloudtrail-status-summary.json`](evidence/native-monitoring/cloudtrail-status-summary.json) | Inspect Terraform and observed status | Verified |
| Bucket policy scoped with `aws:SourceArn` | Both CloudTrail service statements constrain the exact trail ARN | Terraform IAM policy document | Inspect policy conditions | Verified |
| Security Hub NIST SP 800-53 Rev. 5 | Explicit standards subscription; defaults disabled | Terraform and evidence summary | Inspect standard ARN | Verified |
| Capture real non-empty findings | Live exercise captured 50 findings | [`security-hub-findings-summary.json`](evidence/native-monitoring/security-hub-findings-summary.json) | Confirm `captured_finding_count: 50` | Verified |
| Sign and verify findings evidence | Native-evidence workflow hashes, signs, verifies, and publishes sanitized evidence | [`verify-native-findings-chain-intact.txt`](evidence/native-monitoring/verify-native-findings-chain-intact.txt) | Run [`verify-findings.sh`](native-monitoring/verify-findings.sh) with its sidecars | Verified |
| Tamper test fails | Modified findings summary fails integrity verification | [`verify-native-findings-tamper-failed.txt`](evidence/native-monitoring/verify-native-findings-tamper-failed.txt) | Review nonzero transcript | Verified |
| Teardown after capture | Terraform destroy and post-destroy checks | [`teardown.sh`](native-monitoring/teardown.sh), documented teardown results | Review [`native-monitoring/README.md`](native-monitoring/README.md) | Verified |
| Publish raw cloud findings | Raw evidence was retained privately; sanitized public evidence prevents disclosure of account and infrastructure identifiers | [`native-monitoring/README.md`](native-monitoring/README.md) | Review evidence-handling rationale and reproducible capture code | Deliberately sanitized |

## Week 6: OSCAL and portfolio case study

| Requirement | Implementation | Evidence | Verification | Status |
|---|---|---|---|---|
| Component definition | Pipeline component contains four implemented requirements | [`component-definition.json`](oscal/component-definitions/grc-engineering-pipeline/component-definition.json) | Trestle validation | Verified |
| Exact four-control profile | Profile selects only AC-3, AU-3, CM-6, and SC-28 | [`profile.json`](oscal/profiles/grc-engineering-pipeline/profile.json) | Inspect `with-ids`; Trestle validation | Verified |
| NIST SP 800-53 Rev. 5 source | Both OSCAL documents reference the public NIST catalog | OSCAL documents | Inspect source/import URLs | Verified |
| Plain-language implementation, Terraform props, evidence links | Each requirement explains implementation, names resources, and links canonical proof | Component definition | Inspect all four implemented requirements | Verified |
| Both documents validate | compliance-trestle validates component and profile | [`trestle-validation.txt`](evidence/oscal-validation/trestle-validation.txt) | Run the two README commands | Verified |
| Prove OSCAL-to-evidence traversal | SC-28 link resolves to canonical signed bundle | [`sc28-traversal.txt`](evidence/oscal-validation/sc28-traversal.txt) | Run the assurance-graph verifier | Verified |
| Case study explains six stages and links proof | Evidence-first narrative includes green/red PRs, tests, signing, validation, limitations, and lesson learned | [`PORTFOLIO-CASE-STUDY.md`](PORTFOLIO-CASE-STUDY.md) | Follow each proof link | Verified |
| Full eligibility sequence | Terraform, Conftest, Trestle, Cosign, and vault upload all complete | [`ASSURANCE-CHECKLIST.md`](ASSURANCE-CHECKLIST.md) | Follow the reviewer spot check | Verified |

## Reproduction commands

The exact no-AWS commands and expected results are maintained in the [root README](README.md). Credentialed monitoring and vault procedures are maintained in [`native-monitoring/README.md`](native-monitoring/README.md) and [`immutable-vault/README.md`](immutable-vault/README.md), respectively.
