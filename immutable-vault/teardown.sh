#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Object Lock intentionally prevents immediate deletion of retained object versions.
Wait until every RetainUntilDate in evidence/immutable-vault-upload-summary.json
has passed, delete the retained object versions, and then run:

  terraform destroy

Do not try to bypass governance retention merely to accelerate teardown.
EOF
