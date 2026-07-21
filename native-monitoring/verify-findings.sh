#!/usr/bin/env bash
set -euo pipefail

FINDINGS_FILE="${1:-evidence/security-hub-findings-summary.json}"

if [[ ! -f "$FINDINGS_FILE" ]]; then
  echo "VERIFY FAILED: findings file not found: $FINDINGS_FILE" >&2
  exit 1
fi

# Prefer sidecars next to the file being checked.
# For tamper tests, allow reuse of the original downloaded sidecars in the current directory.
HASH_FILE="${FINDINGS_FILE}.sha256"
if [[ ! -f "$HASH_FILE" && -f "security-hub-findings-summary.json.sha256" ]]; then
  HASH_FILE="security-hub-findings-summary.json.sha256"
fi

SIG_BUNDLE="${FINDINGS_FILE%.json}.sig.bundle"
if [[ ! -f "$SIG_BUNDLE" && -f "security-hub-findings-summary.sig.bundle" ]]; then
  SIG_BUNDLE="security-hub-findings-summary.sig.bundle"
fi

if [[ ! -f "$HASH_FILE" ]]; then
  echo "VERIFY FAILED: hash sidecar not found. Expected ${FINDINGS_FILE}.sha256 or security-hub-findings-summary.json.sha256" >&2
  exit 1
fi

if [[ ! -f "$SIG_BUNDLE" ]]; then
  echo "VERIFY FAILED: signature bundle not found. Expected ${FINDINGS_FILE%.json}.sig.bundle or security-hub-findings-summary.sig.bundle" >&2
  exit 1
fi

EXPECTED_SHA="$(awk '{print $1}' "$HASH_FILE")"
ACTUAL_SHA="$(sha256sum "$FINDINGS_FILE" | awk '{print $1}')"

echo "1. Integrity: checking SHA-256..."
if [[ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]]; then
  echo "Expected: $EXPECTED_SHA" >&2
  echo "Actual:   $ACTUAL_SHA" >&2
  echo "VERIFY FAILED: SHA-256 mismatch. Findings evidence was changed after signing." >&2
  exit 1
fi
echo "   OK: SHA-256 matches."

echo "2. Authenticity and timeliness: verifying Cosign signature..."

cosign verify-blob \
  --bundle "$SIG_BUNDLE" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "^https://github.com/jtflack-grc/grc-engineering-club-week5/.github/workflows/sign-native-evidence.yml@refs/.*$" \
  "$FINDINGS_FILE"

echo "   OK: Cosign verified the sanitized Security Hub findings summary."
echo "CHAIN INTACT"
