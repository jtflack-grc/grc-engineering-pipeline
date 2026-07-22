# Signed evidence provenance

- Source repository: [`jtflack-grc/grc-engineering-pipeline`](https://github.com/jtflack-grc/grc-engineering-pipeline)
- Workflow run: [`29884555352`](https://github.com/jtflack-grc/grc-engineering-pipeline/actions/runs/29884555352)
- Source ref: `refs/heads/main`
- Source commit: `2f91c47504581d36dc184809658fdbf9730ad13d`
- Workflow identity: `jtflack-grc/grc-engineering-pipeline/.github/workflows/generate-signed-evidence.yml@refs/heads/main`
- GitHub artifact name: `signed-grc-evidence-29884555352`
- GitHub artifact ID: `8516047549`
- GitHub artifact digest: `sha256:d8360b46e64bacb9b39805f7a37134ee2d442e612ce3f9778c30b3bf66e0b907`
- Evidence archive digest: `sha256:6a13f1e45868659816e8d5e445d4192856a58ea368e6b4d5cd509d6de2cd9f8a`
- Captured at: `2026-07-22T01:58:50Z`
- Controls: `ac-3`, `au-3`, `cm-6`, `sc-28`

The GitHub artifact digest covers the downloaded ZIP. The evidence archive digest covers `generated-evidence.tar.gz` and is independently checked before Cosign verification. The archive contains the exact Terraform plan, policy set, tool versions, per-control results, and manifest used by the signing run.
