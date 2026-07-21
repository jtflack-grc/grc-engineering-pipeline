# GRC Engineering Club Week 5: Native AWS Control Monitoring

Week 5 turns on native AWS monitoring services and captures evidence from the cloud control plane itself.

The build provisions:

- A multi-region AWS CloudTrail trail for management events
- CloudTrail log file validation
- A private encrypted S3 bucket for CloudTrail delivery
- AWS Security Hub with the NIST 800-53 Rev. 5 standard enabled
- Evidence capture scripts
- A Week 4-style evidence verification workflow using SHA-256 and Cosign keyless signing

The goal is to show how native cloud telemetry can support GRC evidence, continuous monitoring, and audit readiness without relying only on Terraform plan evidence.

## Controls demonstrated

| Control area | Implementation |
|---|---|
| AU-2 Event Logging | CloudTrail management events enabled |
| AU-10 Non-repudiation | CloudTrail log file validation enabled |
| AU-12 Event Generation | Multi-region CloudTrail configured |
| RA-5 Vulnerability Monitoring | Security Hub findings captured |
| SI-4 System Monitoring | Security Hub NIST 800-53 Rev. 5 standard enabled |

## Evidence approach

Raw AWS evidence was captured locally during the live run, including CloudTrail status, Security Hub enabled standards, Terraform outputs, and Security Hub findings.

Those raw files were not published because native AWS findings can include account IDs, ARNs, IAM role names, subnet IDs, security group IDs, bucket names, workload tags, and other infrastructure metadata.

The public repo keeps sanitized evidence summaries instead:

- `evidence/security-hub-findings-summary.json`
- `evidence/cloudtrail-status-summary.json`
- `evidence/verify-native-findings-chain-intact.txt`
- `evidence/verify-native-findings-tamper-failed.txt`

This preserves the control evidence story without publishing cloud reconnaissance data.

## Evidence chain

The sanitized Security Hub findings summary is signed through a GitHub Actions workflow using Cosign keyless signing. The original raw findings were signed during the live run but are not published.

The verification script checks:

1. SHA-256 integrity
2. Cosign signature authenticity
3. GitHub Actions OIDC identity
4. Tamper detection

Successful verification produced:

```text
Verified OK
CHAIN INTACT
```

A one-byte tamper test failed as expected with a SHA-256 mismatch and non-zero exit code.

## Cost and teardown

This week intentionally touched billable AWS services. The live AWS resources were destroyed after evidence capture.

Post-teardown checks confirmed:

- Terraform state was empty
- No Week 5 CloudTrail trail remained
- Security Hub was no longer subscribed for the account

## What this proves

Week 1 showed compliant infrastructure.

Week 2 added policy-as-code.

Week 3 enforced controls in CI.

Week 4 signed evidence for chain of custody.

Week 5 adds native cloud monitoring: the cloud account itself reports control findings, and those findings are treated as governed evidence.

This is the difference between “we configured it correctly once” and “we can show what the cloud control plane observed.”
