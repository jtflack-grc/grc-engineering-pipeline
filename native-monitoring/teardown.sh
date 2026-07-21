#!/usr/bin/env bash
# teardown.sh - capture Week 5 evidence, then destroy native AWS controls.
# Run this the same day you apply to keep cost to pennies.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"

echo "1) Capturing evidence before destroy..."
./capture-evidence.sh || echo "Evidence capture had an issue; continuing to destroy to stop billing."

echo
echo "2) Destroying Week 5 baseline..."
terraform destroy -auto-approve

echo
echo "3) Post-destroy checks..."
echo "CloudTrail trails:"
aws cloudtrail describe-trails --region "$REGION" || true

echo
echo "Security Hub enabled standards:"
aws securityhub get-enabled-standards --region "$REGION" || true

echo
echo "Done. If Security Hub was already enabled before this project, confirm whether it should remain enabled."
echo "If this project enabled it for the first time, Terraform destroy should have removed the NIST subscription and disabled the account resource."
