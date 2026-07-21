package compliance.au3_aws

import rego.v1

compliant_input := {
	"configuration": {"root_module": {"resources": [{
		"address": "aws_s3_bucket_logging.primary",
		"type": "aws_s3_bucket_logging",
		"expressions": {
			"bucket": {"references": ["aws_s3_bucket.primary.id", "aws_s3_bucket.primary"]},
			"target_bucket": {"references": ["aws_s3_bucket.log.id", "aws_s3_bucket.log"]},
		},
	}]}},
	"planned_values": {"root_module": {"resources": [{
		"address": "aws_s3_bucket_logging.primary",
		"type": "aws_s3_bucket_logging",
		"values": {"target_prefix": "access-logs/"},
	}]}},
}

broken_input := {
	"configuration": {"root_module": {"resources": []}},
	"planned_values": {"root_module": {"resources": []}},
}

test_complete_logging_route_passes if {
	count(deny) == 0 with input as compliant_input
}

test_missing_logging_route_denied if {
	count(deny) == 1 with input as broken_input
}
