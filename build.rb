# This script is used to extract and pack NWN modules, going from .mod
# to .yml and back, using using nwn-lib (https://github.com/niv/nwn-lib).
#
# Rake is used to multithread the gff->yml and yml->gff operations, and
# the script has been optimized to only work on modified resources,
# regardless of whether they were modified in the toolset or as .yml
# files.
#
# Managing which files are updated is is done by caching the resources
# in cache/tmp and cache/gff. The two folders are necessary because time
# stamps alone are not sufficient to determine which files have been
# changed, as extracting a module creates new files with fresh time
# stamps. md5 digests are used to update files from cache/tmp to
# cache/gff, and time stamps govern taking files from cache/gff to yml
# sources and back all the way to mod again. In addition, when time
# stamps are used to update a file the time stamp of the updated file is
# set to that of the source file, otherwise comparing time stamps would
# have no effect (gff to yml to gff would always update all files).
#
# If sources have been modified after the module was updated, the user
# will be prompted to proceed when extracting the module to avoid
# overwriting changes. The same goes for a module with a newer time stamp
# than the latest yml source. This is not a perfect safety net as
# updating the module without extracting it and then updating a yml
# source will overwrite the module without a prompt, but it's better than
# nothing. It is left for the user not to mess up.

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'highline/import'
require 'digest/md5'

TMP_CACHE_DIR = "cache/tmp"
GFF_CACHE_DIR = "cache/gff"
MODULE = FileList["module/*.mod"][0]
SOURCES = FileList["src/**/*.*"]
TMP_FILES = FileList[TMP_CACHE_DIR+"/*.*"]
GFFS = FileList[GFF_CACHE_DIR+"/*.*"]

# Initialize environment
def init_directories()
	FileUtils.mkdir_p(TMP_CACHE_DIR)
	FileUtils.mkdir_p(GFF_CACHE_DIR)
end

# Extract the given .mod file, or exit early if the file does not exist.
# To avoid overwriting modified source files the module time stamp is
# compared with SOURCES time stamps, and if there are positives the user
# will be prompted to proceed with a list of all source files newer than
# the module.
# +modfile+:: module file to extract
def extract_module(modfile)
	if modfile.nil? || modfile == ""
		puts "No module file found."
		puts "Exiting."
		Kernel.exit(1)
	end

	modified_files = []
	SOURCES.each do |file|
		modified_files.push(file) if File.mtime(file) > File.mtime(modfile)
	end

	unless modified_files.empty?
		puts modified_files
		input = ask "The above #{modified_files.size} files have newer timestamps than the module.\nAre you sure you wish to overwrite? [y/N]"
		Kernel.exit(1) unless input.downcase == "y"
	end

	Dir.chdir(TMP_CACHE_DIR) do
		system "nwn-erf", "-x", "-f", "../../"+modfile
	end
end


# Update gff cache with content of tmp storage
def update_cache_gff()
	remove_deleted_files(TMP_CACHE_DIR, GFFS)
	update_files_based_on_digest(TMP_FILES, GFF_CACHE_DIR)
end

# Delete files in target_files list that do not exist in source_dir
def remove_deleted_files(source_dir, target_files)
	return if target_files.empty?
	target_files.each do |file|
		FileUtils.rm(File.exists?(file) ? file : file + ".yml") unless File.exists?(source_dir+"/"+File.basename(file))
	end
end

# Update all source_files that have a different digest than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_digest(source_files, target_dir)
	source_files.each do |file|
		if !File.exists?(target_dir+"/"+File.basename(file))
			FileUtils.cp(file, target_dir)
		else
			tmp_digest = Digest::MD5.hexdigest(File.read(file))
			gff_digest = Digest::MD5.hexdigest(File.read(target_dir+"/"+File.basename(file)))
			FileUtils.cp(file, target_dir) if tmp_digest != gff_digest
		end
	end
end

# Update all source_files that have a different time stamp than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_timestamp(source_files, target_dir)
	source_files.each do |file|
		if !File.exists?(target_dir+"/"+File.basename(file))
			FileUtils.cp(file, target_dir)
		elsif File.mtime(file) > File.mtime(target_dir+"/"+File.basename(file))
			FileUtils.cp(file, target_dir)
		end
	end
end

def update_sources()
	remove_deleted_files(GFF_CACHE_DIR, SOURCES.sub(/\.yml$/, ''))
	system "rake", "--rakefile", "extract.rake"
	update_files_based_on_timestamp(FileList[GFF_CACHE_DIR+"/*.nss"], "src/nss")
end

def extract_all()
	init_directories()
	extract_module(MODULE)
	update_cache_gff()
	update_sources()
end

def pack_all()
	system "rake", "--rakefile", "pack.rake"
	# update_cache_tmp
end

extract_all
# pack_all
# Kernel.exit(0)
