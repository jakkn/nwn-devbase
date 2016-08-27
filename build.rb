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
YMLS = FileList[SOURCE_DIR+"/**/*.*"]
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
	modified_files = []
	Dir.glob(YMLS) do |file|
		if File.mtime(file) > File.mtime(MODULE)
			modified_files.push(file)
		end
	end
	
	if !modified_files.empty?
		puts "Found #{modified_files.size} files that are newer than the module.\nAre you sure you wish to overwrite?"
	# TODO: Finish printout
		# if modified_files.size > 10
		# 	input = ask "(Show files?)"
		# 	puts input
		# end
		# Kernel.exit(1)
	end
end

#system "rake", "--rakefile", "extract.rake", "extract"

#
# Update cache with content of temp storage
#
def update_cache_gff()
	remove_deleted_files()
	add_new_files()
end

def remove_deleted_files()
	return if GFFS.empty?
	GFFS.each do |file|
		FileUtils.rm(file) if !File.exists?(TMP_DIR+"/"+File.basename(file))
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
# Kernel.exit(1)

init()
update_cache_gff()