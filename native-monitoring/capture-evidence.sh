#!/usr/bin/env bash
# capture-evidence.sh - capture native AWS control evidence for Week 5.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"

mkdir -p evidence

TRAIL_NAME="$(terraform output -raw cloudtrail_name 2>/dev/null || true)"
BUCKET_NAME="$(terraform output -raw cloudtrail_bucket_name 2>/dev/null || true)"

echo "Capturing Week 5 native AWS evidence from region: $REGION"

if [[ -n "$TRAIL_NAME" ]]; then
  echo "1) Capturing CloudTrail status..."
  aws cloudtrail get-trail-status \
    --name "$TRAIL_NAME" \
    --region "$REGION" \
    > evidence/cloudtrail-status.json

  echo "2) Capturing CloudTrail description..."
  aws cloudtrail describe-trails \
    --trail-name-list "$TRAIL_NAME" \
    --region "$REGION" \
    > evidence/cloudtrail-describe.json
else
  echo "No Terraform CloudTrail output found yet; skipping CloudTrail capture."
fi

echo "3) Capturing Security Hub enabled standards..."
aws securityhub get-enabled-standards \
  --region "$REGION" \
  > evidence/security-hub-enabled-standards.json

echo "4) Capturing Security Hub findings..."
aws securityhub get-findings \
  --region "$REGION" \
  --max-results 50 \
  > evidence/security-hub-findings.json

echo "5) Writing evidence summary..."
jq -n \
  --arg region "$REGION" \
  --arg trail_name "$TRAIL_NAME" \
  --arg bucket_name "$BUCKET_NAME" \
  --arg captured_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --slurpfile trail_status evidence/cloudtrail-status.json \
  --slurpfile enabled_standards evidence/security-hub-enabled-standards.json \
  --slurpfile findings evidence/security-hub-findings.json \
  '{
    captured_at: $captured_at,
    region: $region,
    cloudtrail: {
      trail_name: $trail_name,
      bucket_name: $bucket_name,
      status: ($trail_status[0] // {})
    },
    security_hub: {
      enabled_standards: ($enabled_standards[0] // {}),
      captured_finding_count: (($findings[0].Findings // []) | length)
    }
  }' > evidence/week5-evidence-summary.json

echo
echo "Evidence captured:"
find evidence -maxdepth 1 -type f -print | sort

echo
echo "Security Hub captured finding count (maximum 50):"
jq '.Findings | length' evidence/security-hub-findings.json
