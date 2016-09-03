require 'rubygems'
require 'bundler/setup'

require 'nwn/all'
require 'fileutils'

task :default => :gff

YML_SOURCES = FileList["src/**/*.yml"].exclude(/n[cs]s$/)
GFF_TARGETS = YML_SOURCES.pathmap("cache/gff/%n")


directory "cache/gff"
directory "src"

desc 'Convert yml to gff'
task :gff => :yml2gff

multitask :yml2gff => GFF_TARGETS

rule( /\.(?!yml)[\w]+$/ => ->(f){ source_for_gff(f) }) do |t|
	system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}", "-kg"
	FileUtils.touch "#{t.name}", :mtime => File.mtime("#{t.source}")
end

def source_for_gff(gff)
	YML_SOURCES.detect{|yml| File.basename(gff) == File.basename(yml, ".*")}
end
