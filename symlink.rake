require 'fileutils'
require 'set'

task :default => :symlinks

GFF_SOURCES = FileList["cache/gff/*.*"]
RESMAN_DIRS = Set.new.merge GFF_SOURCES.pathmap("%{.*,*}x") { |ext|
	ext.delete('.')
}
RESMAN_SYMLINKS = GFF_SOURCES.pathmap("resman/%{\.,}x/%f")

desc 'Create resman dir tree and symbolic links to files in cache/gff'
task :symlinks => [:clean, :folders, :symbolic_links]

task :clean do
	FileUtils.rm_r Dir.glob('resman')
end

directory "resman"

desc 'Create resman dir tree'
task :folders => ["resman"] do
	Dir.chdir("resman") do
		RESMAN_DIRS.each do |dir|
			FileUtils.mkdir(dir) unless File.exists?(dir)
		end
	end
end

desc 'Create symbolic links for resman'
multitask :symbolic_links => RESMAN_SYMLINKS

rule( /resman\/*\/*.*/ => ->(f){ source_for_symlink(f) }) do |t|
	FileUtils.symlink("../../#{t.source}", "#{t.name}")
end

def source_for_symlink(dest)
	GFF_SOURCES.detect{|src| File.basename(dest) == File.basename(src)}
end
