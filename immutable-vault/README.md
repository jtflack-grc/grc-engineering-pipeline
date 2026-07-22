# Immutable evidence vault

This credential-dependent stage demonstrates immutable evidence preservation. It creates a private, encrypted, versioned S3 bucket with Object Lock enabled. The upload helper requests 30 days of GOVERNANCE retention by default, uploads the canonical archive and Cosign bundle, retrieves the exact uploaded versions, re-hashes the downloaded bytes, and verifies their retention metadata.

## Run from an authenticated AWS environment

```bash
cd immutable-vault
terraform init
terraform apply
./upload-and-verify.sh
```

Override the per-object retention request when needed:

```bash
RETENTION_DAYS=60 ./upload-and-verify.sh
```

Success ends with both `VAULT UPLOAD VERIFIED` and `REMOTE HASHES VERIFIED`, then writes a sanitized proof file to `evidence/immutable-vault-upload-summary.json`. Review that file before committing it. It contains object keys, version IDs, hashes, content lengths, retention details, a bucket-name fingerprint, and no AWS account ID or full bucket name.

## Cost and teardown

The uploaded files are only a few kilobytes, but Object Lock prevents their versions from being deleted before retention expires. The 30-day default is intentionally long enough to demonstrate meaningful preservation while keeping storage cost negligible. After every `RetainUntilDate` has passed, delete the object versions and run `terraform destroy`. The bucket uses `force_destroy = false` to prevent an accidental attempt to defeat the evidence-retention control.
