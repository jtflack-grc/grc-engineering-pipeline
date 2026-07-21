# Evidence index

| Evidence | What it demonstrates |
|---|---|
| [`policy-tests/`](policy-tests/) | Rego unit tests, passing Conftest runs, and the reviewed Terraform plan |
| [`pull-request-gate/`](pull-request-gate/) | Successful chain verification and deliberate tamper rejection |
| [`signed-bundle/`](signed-bundle/) | Original Week 4 evidence archive, SHA-256 sidecar, Cosign bundle, and extracted gate outputs |
| [`native-monitoring/`](native-monitoring/) | Sanitized CloudTrail and Security Hub summaries plus verification results |
| [`oscal-validation/`](oscal-validation/) | Reproducible Trestle validation and OSCAL-to-evidence traversal output |
| `immutable-vault-upload-summary.json` | Sanitized Object Lock upload and retention proof, created after the credential-dependent vault run |

The committed signed bundle contains no AWS credentials or account identifiers. See [`signed-bundle/ARTIFACT-PROVENANCE.md`](signed-bundle/ARTIFACT-PROVENANCE.md) for origin and digest details.
