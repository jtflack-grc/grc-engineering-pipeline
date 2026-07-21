package compliance.cm6_aws

import rego.v1

required := {"Project", "Environment", "ManagedBy", "ComplianceScope"}

has_key(obj, key) if {
	object.get(obj, key, null) != null
}

taggable(resource) if {
	object.get(resource.values, "tags_all", null) != null
}

taggable(resource) if {
	object.get(resource.values, "tags", null) != null
}

tags_for(resource) := tags if {
	tags := object.get(resource.values, "tags_all", null)
	tags != null
} else := tags if {
	tags := object.get(resource.values, "tags", {})
}

missing_tags(resource) := missing if {
	tags := tags_for(resource)
	missing := {tag | required[tag]; not has_key(tags, tag)}
}

deny contains msg if {
	some resource in input.planned_values.root_module.resources
	taggable(resource)

	missing := missing_tags(resource)
	count(missing) > 0

	msg := sprintf(
		"CM-6: %s is missing required tags: %v. Add Project, Environment, ManagedBy, and ComplianceScope using provider default_tags or explicit resource tags.",
		[resource.address, sort(missing)],
	)
}
