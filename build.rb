require 'rubygems'
require 'bundler/setup'
require 'rake'
require "highline/import"
require 'digest/md5'

#
# Extract module
#
MODULE  = FileList["module/*.mod"]
SOURCES = FileList["src/**/*.*"]
MODIFIED_FILES = []
Dir.glob(SOURCES) do |file|
	if File.mtime(file) > File.mtime(MODULE[0])
		MODIFIED_FILES.push(file)
	end  
end

if !MODIFIED_FILES.empty?
	puts "Found #{MODIFIED_FILES.size} files that are newer than the module.\nAre you sure you wish to overwrite?"
# TODO: Finish printout
	# if MODIFIED_FILES.size > 10
	# 	input = ask "(Show files?)"
	# 	puts input
	# end
	# Kernel.exit(1)
end

#system "rake", "--rakefile", "extract.rake", "extract"

#
# Move to gff cache
#
TMP_FILES = FileList["tmp/*.*"]
Dir.glob(TMP_FILES) do |file|
	puts Digest::MD5.hexdigest(File.read(file))
end
