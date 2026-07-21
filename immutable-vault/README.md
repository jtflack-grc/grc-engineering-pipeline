# Immutable evidence vault

This optional, credential-dependent stage closes the challenge's explicit `vault upload` criterion. It creates a private, encrypted, versioned S3 bucket with Object Lock enabled and a one-day governance retention period, uploads the signed Week 4 evidence and signature bundles, and verifies the retention metadata.

## Run from an authenticated AWS environment

```bash
cd immutable-vault
terraform init
terraform apply
./upload-and-verify.sh
```

Success ends with `VAULT UPLOAD VERIFIED` and writes a sanitized proof file to `evidence/immutable-vault-upload-summary.json`. Review that file before committing it. It contains object keys, version IDs, hashes, retention mode and expiration, a bucket-name fingerprint, and no AWS account ID or full bucket name.

## Cost and teardown

The uploaded files are only a few kilobytes, but Object Lock prevents their versions from being deleted before retention expires. The default one-day retention minimizes cost. After every `RetainUntilDate` has passed, delete the object versions and run `terraform destroy`. The bucket uses `force_destroy = false` to prevent an accidental attempt to defeat the evidence-retention control.
