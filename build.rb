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

#
# Initialize environment
#
def init_directories()
	FileUtils.mkdir_p(TMP_CACHE_DIR)
	FileUtils.mkdir_p(GFF_CACHE_DIR)
end

#
# Extract module
#
def extract_module()
	if MODULE.nil? || MODULE == ""
		puts "No module file found."
		puts "Exiting."
		Kernel.exit(1)
	end

	modified_files = []
	SOURCES.each do |file|
		modified_files.push(file) if File.mtime(file) > File.mtime(MODULE)
	end
	
	unless modified_files.empty?
		puts modified_files
		input = ask "The above #{modified_files.size} files have newer timestamps than the module.\nAre you sure you wish to overwrite? [Y/n]"
		Kernel.exit(1) unless input.downcase == "y"
	end
	
	Dir.chdir(TMP_CACHE_DIR) do
		system "nwn-erf", "-x", "-f", "../../"+MODULE
	end
end


#
# Update cache with content of tmp storage
#
def update_cache_gff()
	remove_deleted_files(TMP_CACHE_DIR, GFFS)
	update_files_based_on_digest(TMP_FILES, GFF_CACHE_DIR)
end

#
# Delete files in target_files list that do not exist in source_dir
#
def remove_deleted_files(source_dir, target_files)
	return if target_files.empty?
	target_files.each do |file|
		FileUtils.rm(File.exists?(file) ? file : file + ".yml") unless File.exists?(source_dir+"/"+File.basename(file))
	end
end

# 
# Update all source_files that have a different digest than the corresponding
# file in target_dir. New files are copied over.
# 
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

# 
# Update all source_files that have a different time stamp than the corresponding
# file in target_dir. New files are copied over.
# 
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
	extract_module()
	update_cache_gff()
	update_sources()
end

extract_all
# Kernel.exit(0)
