#!/usr/bin/env bash
# verify-evidence.sh <bundle.tar.gz>
# Proves an evidence bundle is intact and authentic.
set -euo pipefail

BUNDLE="${1:?usage: verify-evidence.sh <bundle.tar.gz>}"

fail() {
  echo "VERIFY FAILED: $*" >&2
  exit 1
}

[[ -f "$BUNDLE" ]] || fail "bundle not found: $BUNDLE"

# Sidecar lookup:
# Normal CI artifact: evidence.tar.gz + evidence.tar.gz.sha256
# Tamper test: /tmp/tampered.tar.gz can reuse ./evidence.tar.gz.sha256
SIDECAR="${BUNDLE}.sha256"
if [[ ! -f "$SIDECAR" && -f "evidence.tar.gz.sha256" ]]; then
  SIDECAR="evidence.tar.gz.sha256"
fi
[[ -f "$SIDECAR" ]] || fail "SHA-256 sidecar not found. Expected ${BUNDLE}.sha256 or evidence.tar.gz.sha256"

# Signature bundle lookup:
# Normal CI artifact: evidence.tar.gz + evidence.sig.bundle
# Tamper test: /tmp/tampered.tar.gz can reuse ./evidence.sig.bundle
SIG_BUNDLE="${BUNDLE%.tar.gz}.sig.bundle"
if [[ ! -f "$SIG_BUNDLE" && -f "evidence.sig.bundle" ]]; then
  SIG_BUNDLE="evidence.sig.bundle"
fi
[[ -f "$SIG_BUNDLE" ]] || fail "Cosign signature bundle not found. Expected ${BUNDLE%.tar.gz}.sig.bundle or evidence.sig.bundle"

echo "1. Integrity: checking SHA-256..."
EXPECTED_SHA="$(awk '{print $1}' "$SIDECAR")"
ACTUAL_SHA="$(sha256sum "$BUNDLE" | awk '{print $1}')"

if [[ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]]; then
  echo "Expected: $EXPECTED_SHA" >&2
  echo "Actual:   $ACTUAL_SHA" >&2
  fail "SHA-256 mismatch. Evidence was changed after signing."
fi

echo "   OK: SHA-256 matches."

command -v cosign >/dev/null 2>&1 || fail "cosign is not installed or not in PATH"

echo "2. Authenticity and timeliness: verifying Cosign signature bundle..."

OIDC_ISSUER="${COSIGN_OIDC_ISSUER:-https://token.actions.githubusercontent.com}"
IDENTITY_REGEXP="${COSIGN_CERTIFICATE_IDENTITY_REGEXP:-^https://github.com/jtflack-grc/grc-engineering-pipeline/.github/workflows/generate-signed-evidence.yml@refs/heads/main$}"

cosign verify-blob \
  --bundle "$SIG_BUNDLE" \
  --certificate-oidc-issuer "$OIDC_ISSUER" \
  --certificate-identity-regexp "$IDENTITY_REGEXP" \
  "$BUNDLE" \
  > /tmp/cosign-verify-output.txt

cat /tmp/cosign-verify-output.txt

echo "   OK: Cosign verified the bundle."

echo "3. Preservation: checking immutable vault status if configured..."

if [[ -n "${VAULT_BUCKET:-}" && -n "${VAULT_KEY:-}" ]]; then
  command -v aws >/dev/null 2>&1 || fail "aws CLI is required for vault verification"

  RETENTION_JSON="$(aws s3api get-object-retention \
    --bucket "$VAULT_BUCKET" \
    --key "$VAULT_KEY")"

  RETAIN_UNTIL="$(echo "$RETENTION_JSON" | jq -r '.Retention.RetainUntilDate // empty')"
  [[ -n "$RETAIN_UNTIL" ]] || fail "Object Lock retention date not found"

  RETAIN_UNTIL_EPOCH="$(date -d "$RETAIN_UNTIL" +%s)"
  NOW_EPOCH="$(date -u +%s)"

  if (( RETAIN_UNTIL_EPOCH <= NOW_EPOCH )); then
    fail "Object Lock retention date is not in the future: $RETAIN_UNTIL"
  fi

  echo "   OK: Object Lock retention is active until $RETAIN_UNTIL."
else
  echo "   SKIPPED: no vault configured. Set VAULT_BUCKET and VAULT_KEY to verify preservation."
fi

echo "CHAIN INTACT"
