require 'nwn/all'
require 'fileutils'
require 'set'

task :default => :yml

FLAT_LAYOUT = ENV['flat'] == "true"

GFF_SOURCES = FileList["cache/gff/*.*"].exclude(/\.n[cs]s$/)
YML_TARGETS = FLAT_LAYOUT ? GFF_SOURCES.pathmap("src/%f.yml") : GFF_SOURCES.pathmap("src/%{.*,*}x/%f.yml") { |ext| ext.delete('.') }
DIRS = Set.new.merge GFF_SOURCES.pathmap("%{.*,*}x") { |ext| ext.delete('.') }

desc 'Create dir tree and convert to yml'
task :yml => [:create_folders, :gff2yml]

directory "src"

desc 'Create dir tree'
task :create_folders => ["src"] do
	Dir.chdir("src") do
		DIRS.each do |dir|
			FileUtils.mkdir(dir) unless File.exists?(dir)
		end
	end unless FLAT_LAYOUT
end

desc 'Convert gff to yml'
multitask :gff2yml => YML_TARGETS

rule '.yml' => ->(f){ source_for_yml(f) } do |t|
	system "nwn-gff", "-i", "#{t.source}", "-lg", "-o", "#{t.name}", "-r", "scripts/truncate_floats.rb"
	FileUtils.touch "#{t.name}", :mtime => File.mtime("#{t.source}")
end

def source_for_yml(yml)
	GFF_SOURCES.detect{|gff| File.basename(gff) == File.basename(yml, ".*")}
end
