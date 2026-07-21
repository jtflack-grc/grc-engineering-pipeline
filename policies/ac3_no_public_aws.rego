package compliance.ac3_aws

import rego.v1

bucket_address(bucket) := sprintf("aws_s3_bucket.%s", [bucket.name])

config_address(resource) := object.get(resource, "address", sprintf("%s.%s", [resource.type, resource.name]))

planned_resource_by_address[address] := resource if {
	some resource in input.planned_values.root_module.resources
	address := resource.address
}

references_bucket(resource, bucket) if {
	refs := object.get(object.get(object.get(resource, "expressions", {}), "bucket", {}), "references", [])
	bucket_ref := sprintf("%s.id", [bucket_address(bucket)])
	some ref in refs
	ref == bucket_ref
}

references_bucket(resource, bucket) if {
	refs := object.get(object.get(object.get(resource, "expressions", {}), "bucket", {}), "references", [])
	some ref in refs
	ref == bucket_address(bucket)
}

public_access_block_complete(resource) if {
	planned := planned_resource_by_address[config_address(resource)]
	planned.values.block_public_acls == true
	planned.values.block_public_policy == true
	planned.values.ignore_public_acls == true
	planned.values.restrict_public_buckets == true
}

bucket_has_complete_public_access_block(bucket) if {
	some resource in input.configuration.root_module.resources
	resource.type == "aws_s3_bucket_public_access_block"
	references_bucket(resource, bucket)
	public_access_block_complete(resource)
}

deny contains msg if {
	some bucket in input.configuration.root_module.resources
	bucket.type == "aws_s3_bucket"
	not bucket_has_complete_public_access_block(bucket)

	msg := sprintf(
		"AC-3: %s is missing a matching aws_s3_bucket_public_access_block with block_public_acls, block_public_policy, ignore_public_acls, and restrict_public_buckets all set to true.",
		[bucket_address(bucket)],
	)
}
