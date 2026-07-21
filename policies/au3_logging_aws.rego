package compliance.au3_aws

import rego.v1

planned_resource_by_address[address] := resource if {
	some resource in input.planned_values.root_module.resources
	address := resource.address
}

has_reference(resource, attribute, expected) if {
	refs := object.get(object.get(object.get(resource, "expressions", {}), attribute, {}), "references", [])
	some ref in refs
	ref == expected
}

references_resource(resource, attribute, address) if {
	has_reference(resource, attribute, address)
}

references_resource(resource, attribute, address) if {
	has_reference(resource, attribute, sprintf("%s.id", [address]))
}

logging_route_complete if {
	some resource in input.configuration.root_module.resources
	resource.address == "aws_s3_bucket_logging.primary"
	resource.type == "aws_s3_bucket_logging"
	references_resource(resource, "bucket", "aws_s3_bucket.primary")
	references_resource(resource, "target_bucket", "aws_s3_bucket.log")

	planned := planned_resource_by_address[resource.address]
	object.get(planned.values, "target_prefix", "") != ""
}

deny contains msg if {
	not logging_route_complete
	msg := "AU-3: aws_s3_bucket_logging.primary must route the primary bucket to the dedicated log bucket with a nonempty target prefix."
}
