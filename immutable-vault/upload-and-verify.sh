#!/usr/bin/env bash
# Deploy the vault first, then run this script from immutable-vault/.
set -euo pipefail

BUNDLE="${1:-../evidence/signed-bundle/generated-evidence.tar.gz}"
SIG_BUNDLE="${2:-../evidence/signed-bundle/generated-evidence.sig.bundle}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
REGION="$(terraform output -raw aws_region)"
BUCKET="$(terraform output -raw bucket_name)"
RUN_TAG="$(date -u +%Y%m%dT%H%M%SZ)"
PREFIX="grc-capstone/${RUN_TAG}"
SUMMARY="../evidence/immutable-vault-upload-summary.json"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

[[ "$RETENTION_DAYS" =~ ^[1-9][0-9]*$ ]] || {
  echo "RETENTION_DAYS must be a positive integer" >&2
  exit 1
}

for file in "$BUNDLE" "$SIG_BUNDLE"; do
  [[ -f "$file" ]] || { echo "Missing evidence file: $file" >&2; exit 1; }
done

RETAIN_UNTIL="$(date -u -d "+${RETENTION_DAYS} days" +%Y-%m-%dT%H:%M:%SZ)"

upload() {
  local file="$1"
  local name key sha size put_json head_json retention_json downloaded version_id
  name="$(basename "$file")"
  key="${PREFIX}/${name}"
  sha="$(sha256sum "$file" | awk '{print $1}')"
  size="$(stat -c '%s' "$file")"
  put_json="$TMP_DIR/${name}.put-object.json"
  head_json="$TMP_DIR/${name}.head-object.json"
  retention_json="$TMP_DIR/${name}.retention.json"
  downloaded="$TMP_DIR/${name}.downloaded"

  aws s3api put-object \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --body "$file" \
    --metadata "sha256=${sha}" \
    --object-lock-mode GOVERNANCE \
    --object-lock-retain-until-date "$RETAIN_UNTIL" \
    > "$put_json"

  version_id="$(jq -er '.VersionId' "$put_json")"

  aws s3api head-object \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --version-id "$version_id" \
    > "$head_json"

  [[ "$(jq -r '.Metadata.sha256' "$head_json")" == "$sha" ]] || {
    echo "Remote metadata hash mismatch for $name" >&2
    return 1
  }
  [[ "$(jq -r '.ContentLength' "$head_json")" == "$size" ]] || {
    echo "Remote content length mismatch for $name" >&2
    return 1
  }

  aws s3api get-object \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --version-id "$version_id" \
    "$downloaded" \
    >/dev/null

  [[ "$(sha256sum "$downloaded" | awk '{print $1}')" == "$sha" ]] || {
    echo "Downloaded object hash mismatch for $name" >&2
    return 1
  }

  aws s3api get-object-retention \
    --region "$REGION" \
    --bucket "$BUCKET" \
    --key "$key" \
    --version-id "$version_id" \
    > "$retention_json"

  jq -n \
    --arg key "$key" \
    --arg version_id "$version_id" \
    --arg sha256 "$sha" \
    --argjson content_length "$size" \
    --slurpfile retention "$retention_json" \
    '{
      key: $key,
      version_id: $version_id,
      sha256: $sha256,
      content_length: $content_length,
      remote_integrity_verified: true,
      retention: $retention[0].Retention
    }'
}

echo "Uploading signed evidence to the private Object Lock vault..."
BUNDLE_RESULT="$(upload "$BUNDLE")"
SIGNATURE_RESULT="$(upload "$SIG_BUNDLE")"

BUCKET_FINGERPRINT="$(printf '%s' "$BUCKET" | sha256sum | cut -c1-16)"
jq -n \
  --arg captured_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg region "$REGION" \
  --arg bucket_fingerprint "$BUCKET_FINGERPRINT" \
  --argjson retention_requested_days "$RETENTION_DAYS" \
  --argjson evidence_bundle "$BUNDLE_RESULT" \
  --argjson signature_bundle "$SIGNATURE_RESULT" \
  '{
    captured_at: $captured_at,
    region: $region,
    bucket_fingerprint: $bucket_fingerprint,
    retention_requested_days: $retention_requested_days,
    upload_verified: true,
    remote_integrity_verified: true,
    objects: [$evidence_bundle, $signature_bundle]
  }' \
  > "$SUMMARY"

jq -e '
  .upload_verified == true and
  .remote_integrity_verified == true and
  all(.objects[]; .remote_integrity_verified == true and .retention.Mode == "GOVERNANCE")
' "$SUMMARY" >/dev/null

echo "VAULT UPLOAD VERIFIED"
echo "REMOTE HASHES VERIFIED"
echo "Sanitized proof written to $SUMMARY"
