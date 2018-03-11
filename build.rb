#!/usr/bin/ruby
#
# This script is used to extract and pack NWN modules, going from .mod
# to .yml and back, using neverwinter_utils.nim
# (https://github.com/niv/neverwinter_utils.nim) and nwn-lib
# (https://github.com/niv/nwn-lib).
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
# source will overwrite the module on the next attempt to pack without a
# prompt, but it's better than nothing. It is left for the user not to
# mess up.

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'highline/import'
require 'digest/md5'
require 'os'
require 'yaml';
require 'parallel';

# Returns the name of a file if it exists, or nil
# Used in ORing files
def file_exists(file)
  return nil unless File.exist?(file)
  return file
end

DEBUG=false
START_TIME = Time.now
PROGRAM_ROOT = File.expand_path __dir__
HOME_DIR = file_exists("#{PROGRAM_ROOT}/homedir") || file_exists("#{PROGRAM_ROOT}/server")
INSTALL_DIR = file_exists("#{PROGRAM_ROOT}/installdir") || file_exists("#{PROGRAM_ROOT}/NWN") || ENV["NWN_INSTALLDIR"]
MODULE_DIR = "#{HOME_DIR}/modules"
CACHE_DIR = "#{PROGRAM_ROOT}/cache"
TMP_CACHE_DIR = "#{CACHE_DIR}/tmp"
GFF_CACHE_DIR = "#{CACHE_DIR}/gff"
NSS_DIR = "#{PROGRAM_ROOT}/src/nss"
ALL_NSS = "*.nss"
SOURCES = FileList["#{PROGRAM_ROOT}/src/**/*.*"]
NSS_COMPILER = ENV["NSS_COMPILER"] || "nwnsc"

def find_modfile()
  mod = FileList["#{MODULE_DIR}/*.mod"][0]
  return (mod.nil? || mod == "") ? "#{MODULE_DIR}/module.mod" : mod
end

MODULE_FILE = find_modfile

if DEBUG
  puts "DEBUG: #{DEBUG}"
  puts "START_TIME: #{START_TIME}"
  puts "PROGRAM_ROOT: #{PROGRAM_ROOT}"
  puts "HOME_DIR: #{HOME_DIR}"
  puts "INSTALL_DIR: #{INSTALL_DIR}"
  puts "MODULE_DIR: #{MODULE_DIR}"
  puts "CACHE_DIR: #{CACHE_DIR}"
  puts "TMP_CACHE_DIR: #{TMP_CACHE_DIR}"
  puts "GFF_CACHE_DIR: #{GFF_CACHE_DIR}"
  puts "NSS_DIR: #{NSS_DIR}"
  puts "ALL_NSS: #{ALL_NSS}"
  puts "MODULE_FILE: #{MODULE_FILE}"
  puts "NSS_COMPILER: #{NSS_COMPILER}"
end

# Initialize environment
def init_directories()
  FileUtils.mkdir_p(MODULE_DIR)
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
  unless File.exist?(modfile)
    puts "No module file found in folder \"#{MODULE_DIR}/\".\nExiting."
    Kernel.exit(1)
  end

  modified_files = []
  SOURCES.each do |file|
    modified_files.push(file) if File.mtime(file) > File.mtime(modfile)
  end

  unless modified_files.empty?
    puts modified_files
    input = ask "The above #{modified_files.size} files have newer timestamps than the module.\nAre you sure you wish to overwrite? [y/N]"
    STDOUT.flush
    Kernel.exit(1) unless input.downcase == "y"
  end

  puts "Extracting module."
  STDOUT.flush
  Dir.chdir(TMP_CACHE_DIR) do
    tmp_files = FileList["#{TMP_CACHE_DIR}/*"]
    FileUtils.rm tmp_files
    system "nwn_erf -x -f #{modfile}"
  end
end

# Pack the given .mod file.
# To avoid overwriting a modified .mod file the module time stamp is
# compared with SOURCES time stamps, and if the module is newest the user
# will be prompted to proceed.
# +modfile+:: path to the module file
def pack_module(modfile)
  if File.exist?(modfile)
    modified_files = []
    SOURCES.each do |file|
      modified_files.push(file) if File.mtime(file) > File.mtime(modfile)
    end

    if modified_files.empty?
      input = ask "#{modfile} has a newer timestamp than the sources it will be built from.\nAre you sure you wish to overwrite? [y/N]"
      STDOUT.flush
      Kernel.exit(1) unless input.downcase == "y"
    end
  end

  puts "Building module: #{modfile}"
  STDOUT.flush
  system "nwn_erf", "-e", "MOD", "-c", "#{TMP_CACHE_DIR}", "-f", "#{modfile}"
end

# Update target_dir with content from source_dir based on md5 digest.
def update_cache(source_dir, target_dir)
  target_files = FileList["#{target_dir}/*.*"]
  remove_deleted_files(source_dir, target_files)

  source_files = FileList["#{source_dir}/*.*"]
  update_files_based_on_digest(source_files, target_dir)
end

# Delete files in target_files list that do not exist in source_dir
def remove_deleted_files(source_dir, target_files)
  return if target_files.empty?
  target_files.each do |file|
    FileUtils.rm(File.exist?(file) ? file : file + ".yml") unless File.exist?("#{source_dir}/"+File.basename(file))
  end
end

# Update all source_files that have a different digest than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_digest(source_files, target_dir)
  source_files.each do |file|
    if !File.exist?("#{target_dir}/"+File.basename(file))
      FileUtils.cp(file, target_dir)
    else
      tmp_digest = Digest::MD5.hexdigest(File.open(file, "rb") { |f| f.read })
      gff_digest = Digest::MD5.hexdigest(File.open("#{target_dir}/"+File.basename(file), "rb") { |f| f.read })
      FileUtils.cp(file, target_dir) if tmp_digest != gff_digest
    end
  end
end

# Update all source_files that have a different time stamp than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_timestamp(source_files, target_dir)
  FileUtils.mkdir_p(target_dir) unless File.exist?(target_dir)
  files_updated = false
  source_files.each do |file|
    if !File.exist?("#{target_dir}/"+File.basename(file))
      FileUtils.cp(file, target_dir)
      files_updated = true
    elsif File.mtime(file) > File.mtime("#{target_dir}/"+File.basename(file))
      FileUtils.cp(file, target_dir)
      files_updated = true
    end
  end
  return files_updated
end

def update_sources()
  puts "Converting from gff to yml (this may take a while)..."
  STDOUT.flush

  remove_deleted_files(GFF_CACHE_DIR, SOURCES.sub(/\.yml$/, ''))
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/extract.rake"
  update_files_based_on_timestamp(FileList["#{GFF_CACHE_DIR}/*.nss"], "src/nss")
end

def update_gffs()
  puts "Converting from yml to gff (this may take a while)..."
  STDOUT.flush

  gffs = FileList["#{GFF_CACHE_DIR}/*"].exclude(/\.ncs$/)
  srcs = FileList["src/**/*.*"].sub(/\.yml$/, '')
  gffs.each do |gff|
    FileUtils.rm(gff) unless srcs.detect{|src| File.basename(gff) == File.basename(src)}
  end
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/pack.rake"
  return update_files_based_on_timestamp(FileList["src/nss/*"], GFF_CACHE_DIR)
end

# Compile nss scripts. Module file not parsed for hak includes at the time of writing.
# Valid targets are any nss file name, 
def compile_nss(modfile, target=ALL_NSS)
  puts "Compiling #{target}" if DEBUG
  STDOUT.flush

  Dir.chdir(NSS_DIR) do
    system "#{NSS_COMPILER} -qo -n #{INSTALL_DIR} -b #{GFF_CACHE_DIR} -y #{target}"
  end
end

def create_resman_symlinks
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/symlink.rake"
end

def extract_all()
  init_directories()
  extract_module(MODULE_FILE)
  update_cache(TMP_CACHE_DIR, GFF_CACHE_DIR)
  update_sources()

  elapsed_time = Time.now - START_TIME
  puts "Done.\nTotal time: #{elapsed_time} seconds."
end

def pack_all()
  init_directories()
  should_compile = update_gffs()
  compile_nss(MODULE_FILE) if should_compile
  update_cache(GFF_CACHE_DIR, TMP_CACHE_DIR)
  pack_module(MODULE_FILE)

  elapsed_time = Time.now - START_TIME
  puts "Done.\nTotal time: #{elapsed_time} seconds."
end

def clean()
  FileUtils.rm_r Dir.glob("#{CACHE_DIR}/*")
end

# Verify the target YAML file. Throws an error when YAML parsing fails.
# Defaults to check all project yml files if no target specified.
def verify_yaml(target="src/**/*.yml")
  puts "Verifying yaml"
  STDOUT.flush
  ymls=FileList[target]
  if OS.windows?
    puts "This may take a while due to the lack of multithreading support on windows in the Parrallel gem..." unless ymls.size < 10
    STDOUT.flush
    ymls.each do |file|
      YAML.load_file(file)
    end
  else
    Parallel.map(ymls) do |file|
      YAML.load_file(file)
    end
  end
end

command = ARGV.shift
case command
when "extract"
  extract_all
when "pack"
  pack_all
when "clean"
  clean
when "compile"
  target = ARGV.shift || ALL_NSS
  compile_nss(MODULE_FILE, target)
when "resman"
  create_resman_symlinks
when "verify"
  target = ARGV.shift || "src/**/*.yml"
  verify_yaml(target)
else
  puts "Usage: build.rb ACTION"
  puts "\nACTIONs:\n\textract\n\tpack\n\tclean\n\tcompile\n\tresman\nverify"
end
