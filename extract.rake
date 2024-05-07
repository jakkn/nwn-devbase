require 'nwn/all'
require 'fileutils'
require 'set'
require 'pathname'

def to_forward_slash(path=Pathname.getwd)
  return path.to_s.gsub(File::ALT_SEPARATOR || File::SEPARATOR, File::SEPARATOR)
end

task :default => :yml

FLAT_LAYOUT = ENV['flat'] == "true"
SRC_DIR = Pathname.new ENV['SRC_DIR']
GFF_CACHE_DIR = Pathname.new ENV['GFF_CACHE_DIR']
SCRIPTS_DIR = Pathname.new ENV['SCRIPTS_DIR']
ENCODING = ENV['ENCODING']

GFF_SOURCES = FileList[to_forward_slash GFF_CACHE_DIR.join("*.*")].exclude(/\.n[cs]s$/)
YML_TARGETS = FLAT_LAYOUT ? GFF_SOURCES.pathmap("#{SRC_DIR}/%f.yml") : GFF_SOURCES.pathmap("#{SRC_DIR}/%{.*,*}x/%f.yml") { |ext| ext.delete('.') }
DIRS = Set.new.merge GFF_SOURCES.pathmap("%{.*,*}x") { |ext| ext.delete('.') }

desc 'Create dir tree and convert to yml'
task :yml => [:create_folders, :gff2yml]

directory SRC_DIR.to_s

desc 'Create dir tree'
task :create_folders => [SRC_DIR.to_s] do
	Dir.chdir(to_forward_slash SRC_DIR) do
		DIRS.each do |dir|
			FileUtils.mkdir(dir) unless File.exist?(dir)
		end
	end unless FLAT_LAYOUT
end

desc 'Convert gff to yml'
multitask :gff2yml => YML_TARGETS

rule '.yml' => ->(f){ source_for_yml(f) } do |t|
	system "nwn-gff", "-i", "#{t.source}", "-lg", "-o", "#{t.name}", "--encoding", "#{ENCODING}", "-r", to_forward_slash(SCRIPTS_DIR.join("truncate_floats.rb").to_s)
	FileUtils.touch "#{t.name}", :mtime => File.mtime("#{t.source}")
end

def source_for_yml(yml)
	GFF_SOURCES.detect{|gff| File.basename(gff) == File.basename(yml, ".*")}
end
