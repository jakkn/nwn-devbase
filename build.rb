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
def init()
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
# Update cache with content of temp storage
#
def update_cache_gff()
	remove_deleted_files(GFFS, TMP_CACHE_DIR)
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
			FileUtils.cp(file, GFF_CACHE_DIR)
		end
		return
	end

	TMP_FILES.each do |file|
		if !File.exists?(GFF_CACHE_DIR+"/"+File.basename(file))
			FileUtils.cp(file, GFF_CACHE_DIR)
		else
			tmp_digest = Digest::MD5.hexdigest(File.read(file))
			gff_digest = Digest::MD5.hexdigest(File.read(GFF_CACHE_DIR+"/"+File.basename(file)))
			FileUtils.cp(file, GFF_CACHE_DIR) if tmp_digest != gff_digest
		end
	end
end

def update_sources()
	list = SOURCES.sub(/\.yml$/, '')
	remove_deleted_files(list, GFF_CACHE_DIR)
	system "rake", "--rakefile", "extract.rake"
end


# init()
# extract_module()
# update_cache_gff()
# update_sources()
# Kernel.exit(0)
