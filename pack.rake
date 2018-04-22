require 'nwn/all'
require 'fileutils'
require 'pathname'

task :default => :gff

SRC_DIR = Pathname.new ENV['SRC_DIR']
GFF_CACHE_DIR = Pathname.new ENV['GFF_CACHE_DIR']

YML_SOURCES = FileList[SRC_DIR.join("**/*.yml")].exclude(/n[cs]s$/)
GFF_TARGETS = YML_SOURCES.pathmap("#{GFF_CACHE_DIR}/%n")

directory GFF_CACHE_DIR.to_s

desc 'Convert yml to gff'
task :gff => [GFF_CACHE_DIR.to_s, :yml2gff]

multitask :yml2gff => GFF_TARGETS

rule( /\.(?!yml)[\w]+$/ => ->(f){ source_for_gff(f) }) do |t|
	system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}", "-kg"
	FileUtils.touch "#{t.name}", :mtime => File.mtime("#{t.source}")
end

def source_for_gff(gff)
	YML_SOURCES.detect{|yml| File.basename(gff) == File.basename(yml, ".*")}
end
