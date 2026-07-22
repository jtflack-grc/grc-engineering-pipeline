#!/usr/bin/env bash
# Verifies that the control claim, signed evidence, and preservation record form one consistent graph.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="$ROOT/oscal/profiles/grc-engineering-pipeline/profile.json"
COMPONENT="$ROOT/oscal/component-definitions/grc-engineering-pipeline/component-definition.json"
EVIDENCE="$ROOT/evidence/signed-bundle/generated-evidence.tar.gz"
SIGNATURE="$ROOT/evidence/signed-bundle/generated-evidence.sig.bundle"
VAULT_SUMMARY="$ROOT/evidence/immutable-vault-upload-summary.json"
EXPECTED_CONTROLS='["ac-3","au-3","cm-6","sc-28"]'
EXPECTED_REPOSITORY="jtflack-grc/grc-engineering-pipeline"
EXPECTED_WORKFLOW_REF="jtflack-grc/grc-engineering-pipeline/.github/workflows/generate-signed-evidence.yml@refs/heads/main"

fail() {
  echo "ASSURANCE GRAPH FAILED: $*" >&2
  exit 1
}

for command in jq tar sha256sum realpath; do
  command -v "$command" >/dev/null 2>&1 || fail "$command is required"
done

for file in "$PROFILE" "$COMPONENT" "$EVIDENCE" "$SIGNATURE" "$VAULT_SUMMARY"; do
  [[ -f "$file" ]] || fail "required file not found: $file"
done

profile_controls="$(jq -c '[.profile.imports[]."include-controls"[]."with-ids"[]] | unique | sort' "$PROFILE")"
[[ "$profile_controls" == "$EXPECTED_CONTROLS" ]] || fail "OSCAL profile controls do not match the four claimed controls"

component_controls="$(jq -c '[.["component-definition"].components[]."control-implementations"[]."implemented-requirements"[]."control-id"] | unique | sort' "$COMPONENT")"
[[ "$component_controls" == "$EXPECTED_CONTROLS" ]] || fail "OSCAL component controls do not match the profile"

mapfile -t evidence_hrefs < <(
  jq -r '.["component-definition"].components[]."control-implementations"[]."implemented-requirements"[] |
    .links[] | select(.rel == "evidence") | .href' "$COMPONENT"
)
[[ "${#evidence_hrefs[@]}" -eq 4 ]] || fail "expected one evidence link for each of four controls"

component_dir="$(dirname "$COMPONENT")"
canonical_evidence="$(realpath "$EVIDENCE")"
for href in "${evidence_hrefs[@]}"; do
  resolved="$(realpath -m "$component_dir/$href")"
  [[ "$resolved" == "$canonical_evidence" ]] || fail "OSCAL evidence link does not resolve to the canonical archive: $href"
done

"$ROOT/scripts/verify-evidence.sh" "$EVIDENCE"

manifest="$(mktemp)"
trap 'rm -f "$manifest"' EXIT
tar -xOf "$EVIDENCE" generated-evidence/manifest.json > "$manifest"

jq -e --arg repository "$EXPECTED_REPOSITORY" --arg workflow_ref "$EXPECTED_WORKFLOW_REF" --argjson controls "$EXPECTED_CONTROLS" '.repository == $repository and
   .ref == "refs/heads/main" and
   .workflow_ref == $workflow_ref and
   .conclusion == "pass" and
   (.controls | unique | sort) == $controls and
   (.commit | test("^[0-9a-f]{40}$")) and
   (.run_id | test("^[0-9]+$")) and
   (.inputs.terraform_plan_sha256 | test("^[0-9a-f]{64}$")) and
   (.inputs.policy_set_sha256 | test("^[0-9a-f]{64}$"))' "$manifest" >/dev/null || fail "signed manifest provenance or control results are inconsistent"

archive_sha="$(sha256sum "$EVIDENCE" | awk '{print $1}')"
signature_sha="$(sha256sum "$SIGNATURE" | awk '{print $1}')"

jq -e --arg archive_sha "$archive_sha" --arg signature_sha "$signature_sha" '.upload_verified == true and
   .remote_integrity_verified == true and
   .retention_requested_days >= 30 and
   (.objects | length) == 2 and
   (any(.objects[]; (.key | endswith("/generated-evidence.tar.gz")) and .sha256 == $archive_sha)) and
   (any(.objects[]; (.key | endswith("/generated-evidence.sig.bundle")) and .sha256 == $signature_sha)) and
   (all(.objects[]; (.version_id | length) > 0)) and
   (all(.objects[]; .remote_integrity_verified == true)) and
   (all(.objects[]; .content_length > 0)) and
   (all(.objects[]; .retention.Mode == "GOVERNANCE")) and
   (all(.objects[]; (.retention.RetainUntilDate | length) > 0))' "$VAULT_SUMMARY" >/dev/null || fail "vault proof does not match the committed archive and signature"

echo "ASSURANCE GRAPH VERIFIED"
