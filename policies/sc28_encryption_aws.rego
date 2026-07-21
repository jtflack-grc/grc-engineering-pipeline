package compliance.sc28_aws

import rego.v1

resource_address(resource) := address if {
	address := object.get(resource, "address", "")
	address != ""
}

resource_address(resource) := address if {
	object.get(resource, "address", "") == ""
	address := sprintf("%s.%s", [resource.type, resource.name])
}

bucket_id_reference(bucket) := sprintf("%s.id", [resource_address(bucket)])

has_encryption_for_bucket(bucket) if {
	enc := input.configuration.root_module.resources[_]
	enc.type == "aws_s3_bucket_server_side_encryption_configuration"
	refs := enc.expressions.bucket.references
	some ref in refs
	ref == bucket_id_reference(bucket)
}

has_encryption_for_bucket(bucket) if {
	enc := input.configuration.root_module.resources[_]
	enc.type == "aws_s3_bucket_server_side_encryption_configuration"
	refs := enc.expressions.bucket.references
	some ref in refs
	ref == resource_address(bucket)
}

deny contains msg if {
	bucket := input.configuration.root_module.resources[_]
	bucket.type == "aws_s3_bucket"
	not has_encryption_for_bucket(bucket)
	msg := sprintf("SC-28 violation: %s has no matching aws_s3_bucket_server_side_encryption_configuration. Remediation: add server-side encryption configuration referencing this bucket.", [resource_address(bucket)])
}
