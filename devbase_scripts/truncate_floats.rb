#!/usr/bin/env nwn-dsl

# This truncates position floats to a sane width, thus avoiding
# miniscule floating point differences in version control diffs.

PRECISION = 4

count = 0

self.each_by_flat_path do |label, field|
	next unless field.is_a?(Gff::Field)
	next unless field.field_type == :float
	field.field_value =
		("%.#{PRECISION}f" % field.field_value).to_f
	count += 1
end

log "#{count} floats truncated."
