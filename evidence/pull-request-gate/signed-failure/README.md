# Signed failed-gate evidence

This directory preserves the evidence produced by the deliberately noncompliant [pull request #15](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/15). The SC-28 control failed while AC-3, AU-3, and CM-6 passed. The workflow then bundled, hashed, keyless-signed, verified, and published the evidence before its final enforcement step returned failure.

## Provenance

| Field | Value |
|---|---|
| Workflow run | [`30218444910`](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/30218444910) |
| Pull request | [`#15`](https://github.com/jtflack-grc/grc-engineering-pipeline/pull/15), closed unmerged |
| Workflow ref | `jtflack-grc/grc-engineering-pipeline/.github/workflows/generate-signed-evidence.yml@refs/pull/15/merge` |
| Signed manifest conclusion | `fail` |
| GitHub artifact ID | `8636473694` |
| GitHub artifact digest | `sha256:3231f48f4424da691c5bf0c3663c6b976900ae7d5c57b00199b6f88afa3ff050` |
| Evidence archive SHA-256 | `432d9df1201cfc565145857a7ed164c043a59c221c9426cfb2098ce11c00c760` |
| Cosign bundle SHA-256 | `48c772819ce62fa85a230f68a8dbf98bfb18e468e01cb49ea21fb860b66ed76f` |
| Original artifact retention | Through `2026-10-24T20:11:20Z` |

The committed copies make the proof durable after the GitHub artifact expires. They contain the sanitized Terraform plan, policy sources, tool versions, per-control results, manifest, hash sidecar, and Cosign bundle. They contain no AWS credentials, account identifiers, or raw native-cloud findings.

## Verify

From this directory:

```bash
sha256sum -c generated-evidence.tar.gz.sha256

cosign verify-blob \
  --bundle generated-evidence.sig.bundle \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github.com/jtflack-grc/grc-engineering-pipeline/.github/workflows/generate-signed-evidence.yml@refs/.*$' \
  generated-evidence.tar.gz

tar -xOzf generated-evidence.tar.gz generated-evidence/manifest.json | jq .
```

Expected results:

- SHA-256 reports `generated-evidence.tar.gz: OK`.
- Cosign reports `Verified OK`.
- The manifest reports `conclusion: "fail"`.
- SC-28 contains the missing-encryption remediation message.
- AC-3, AU-3, and CM-6 each report one success.
