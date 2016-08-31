require 'rubygems'
require 'bundler/setup'
require 'nwn/all'
require 'fileutils'
require 'set'

task :default => :yml

GFFS = FileList["cache/gff/*.*"].exclude(/\.n[cs]s$/)
YMLS = GFFS.pathmap("src/%{.*,*}x/%f.yml") { |ext|
	ext.delete('.')
}
DIRS = Set.new


directory "cache/gff"
directory "src"

desc 'Create dir tree and convert to yml'
task :yml => [:create_folders, :gff2yml]

desc 'Create dir tree'
task :create_folders => ["src"] do
	DIRS.merge GFFS.pathmap("%{.*,*}x") { |ext|
		ext.delete('.')
	}
	Dir.chdir("src") do
		DIRS.each do |dir|
			FileUtils.mkdir(dir) unless File.exists?(dir)
		end
	end
end

desc 'Convert gff to yml'
multitask :gff2yml => YMLS

rule '.yml' => ->(f){ source_for_yml(f) } do |t|
  system "nwn-gff", "-i", "#{t.source}", "-lg", "-o", "#{t.name}"
end

def source_for_yml(yml_file)
  GFFS.detect{|f| File.basename(f) == File.basename(yml_file, ".*")}
end
