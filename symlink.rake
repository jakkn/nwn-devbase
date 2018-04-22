require 'fileutils'
require 'set'
require 'pathname'

task :default => :symlinks

RESMAN_DIR = Pathname.new ENV['RESMAN_DIR']
GFF_CACHE_DIR = Pathname.new ENV['GFF_CACHE_DIR']

GFF_SOURCES = FileList[GFF_CACHE_DIR.join("*.*")]
RESMAN_DIRS = Set.new.merge GFF_SOURCES.pathmap("%{.*,*}x") { |ext|
	ext.delete('.')
}
RESMAN_SYMLINKS = GFF_SOURCES.pathmap("#{RESMAN_DIR}/%{\.,}x/%f")

desc 'Create resman dir tree and symbolic links to files in cache/gff'
task :symlinks => [:clean, :folders, :symbolic_links]

task :clean do
	FileUtils.rm_r Dir.glob(RESMAN_DIR)
end

directory RESMAN_DIR.to_s

desc 'Create resman dir tree'
task :folders => [RESMAN_DIR.to_s] do
	Dir.chdir(RESMAN_DIR) do
		RESMAN_DIRS.each do |dir|
			FileUtils.mkdir(dir) unless File.exist?(dir)
		end
	end
end

desc 'Create symbolic links for resman'
multitask :symbolic_links => RESMAN_SYMLINKS

rule( /resman\/*\/*.*/ => ->(f){ source_for_symlink(f) }) do |t|
	FileUtils.symlink("#{t.source}", "#{t.name}")
end

def source_for_symlink(dest)
	GFF_SOURCES.detect{|src| File.basename(dest) == File.basename(src)}
end
