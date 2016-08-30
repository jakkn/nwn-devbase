require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'highline/import'
require 'digest/md5'

MODULE_DIR = "module"
SOURCE_DIR = "src"
TMP_DIR = "cache/tmp"
GFFS_CACHE_DIR = "cache/gff"
MODULE  = FileList[MODULE_DIR+"/*.mod"][0]
SOURCES = FileList[SOURCE_DIR+"/**/*.*"]
TMP_FILES = FileList[TMP_DIR+"/*.*"]
GFFS = FileList[GFFS_CACHE_DIR+"/*.*"]

#
# Initialize environment
#
def init()
	FileUtils.mkdir_p(SOURCE_DIR)
	FileUtils.mkdir_p(TMP_DIR)
	FileUtils.mkdir_p(GFFS_CACHE_DIR)
end

#
# Extract module
#
def extract_module()
	if MODULE.nil? || MODULE == ""
		puts "No module file found."
		puts "Exiting."
		Kernel.exit(0)
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
	
	Dir.chdir(TMP_DIR) do
		system "nwn-erf", "-x", "-f", "../../"+MODULE
	end
end


#
# Update cache with content of temp storage
#
def update_cache_gff()
	remove_deleted_files(GFFS, TMP_DIR)
	add_new_files()
end

#
# Delete files in files list that do not exist in source_dir
#
# TODO: function name and arguments are confusing.
def remove_deleted_files(files, source_dir)
	return if files.empty?
	files.each do |file|
		FileUtils.rm(File.exists?(file) ? file : file + ".yml") unless File.exists?(source_dir+"/"+File.basename(file))
	end
end

def add_new_files()
	if GFFS.empty?
		TMP_FILES.each do |file|
			FileUtils.cp(file, GFFS_CACHE_DIR)
		end
		return
	end

	TMP_FILES.each do |file|
		if !File.exists?(GFFS_CACHE_DIR+"/"+File.basename(file))
			FileUtils.cp(file, GFFS_CACHE_DIR)
		else
			tmp_digest = Digest::MD5.hexdigest(File.read(file))
			gff_digest = Digest::MD5.hexdigest(File.read(GFFS_CACHE_DIR+"/"+File.basename(file)))
			FileUtils.cp(file, GFFS_CACHE_DIR) if tmp_digest != gff_digest
		end
	end
end

def update_sources()
	list = SOURCES.sub(/\.yml$/, '')
	remove_deleted_files(list, GFFS_CACHE_DIR)
	system "rake", "--rakefile", "extract.rake"
end


# Kernel.exit(1)
# extract_module()
# init()
# update_cache_gff()
update_sources()