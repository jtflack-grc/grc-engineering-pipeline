#!/usr/bin/env bash
# Deploy the vault first, then run this script from immutable-vault/.
set -euo pipefail

BUNDLE="${1:-../evidence/signed-bundle/evidence.tar.gz}"
SIG_BUNDLE="${2:-../evidence/signed-bundle/evidence.sig.bundle}"
REGION="$(terraform output -raw aws_region)"
BUCKET="$(terraform output -raw bucket_name)"
RUN_TAG="$(date -u +%Y%m%dT%H%M%SZ)"
PREFIX="grc-capstone/${RUN_TAG}"
SUMMARY="../evidence/immutable-vault-upload-summary.json"

for file in "$BUNDLE" "$SIG_BUNDLE"; do
  [[ -f "$file" ]] || { echo "Missing evidence file: $file" >&2; exit 1; }
done

upload() {
  local file="$1"
  local key="${PREFIX}/$(basename "$file")"
  local sha
  sha="$(sha256sum "$file" | awk '{print $1}')"

  aws s3api put-object \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --body "$file" \
    --metadata "sha256=${sha}" \
    > "/tmp/$(basename "$file").put-object.json"

  local version_id
  version_id="$(jq -r '.VersionId' "/tmp/$(basename "$file").put-object.json")"
  aws s3api get-object-retention \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --version-id "$version_id" \
    > "/tmp/$(basename "$file").retention.json"

  jq -n \
    --arg key "$key" \
    --arg version_id "$version_id" \
    --arg sha256 "$sha" \
    --slurpfile retention "/tmp/$(basename "$file").retention.json" \
    '{key: $key, version_id: $version_id, sha256: $sha256, retention: $retention[0].Retention}'
}

echo "Uploading signed evidence to the private Object Lock vault..."
BUNDLE_RESULT="$(upload "$BUNDLE")"
SIGNATURE_RESULT="$(upload "$SIG_BUNDLE")"

BUCKET_FINGERPRINT="$(printf '%s' "$BUCKET" | sha256sum | cut -c1-16)"
jq -n \
  --arg captured_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg region "$REGION" \
  --arg bucket_fingerprint "$BUCKET_FINGERPRINT" \
  --argjson evidence_bundle "$BUNDLE_RESULT" \
  --argjson signature_bundle "$SIGNATURE_RESULT" \
  '{captured_at: $captured_at, region: $region, bucket_fingerprint: $bucket_fingerprint, upload_verified: true, objects: [$evidence_bundle, $signature_bundle]}' \
  > "$SUMMARY"

jq -e '.objects[] | select(.retention.Mode == "GOVERNANCE") | .retention.RetainUntilDate' "$SUMMARY" >/dev/null
echo "VAULT UPLOAD VERIFIED"
echo "Sanitized proof written to $SUMMARY"
