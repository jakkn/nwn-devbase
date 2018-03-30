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
require 'optparse'

# Show usage on no arguments
ARGV << '-h' if ARGV.empty?

# Parse script arguments
options = {}
OptionParser.new do |opts|
  opts.banner ="Usage:
    ruby build.rb [options] extract\t\t\tExtract .mod to src/
    ruby build.rb [options] pack\t\t\tPack src/ into .mod
    ruby build.rb [options] clean\t\t\tClean cache folder
    ruby build.rb [options] compile [file]\t\tCompile nss to ncs
    ruby build.rb [options] resman\t\t\tCreate/refresh resman symlinks
    ruby build.rb [options] verify [file]\t\tVerify YAML
  
Options:"

  opts.on("-v", "--[no-]verbose", "Turn on debug logging") do |v|
    options[:verbose] = v
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Cross-platform way of finding an executable in the $PATH.
# Source: https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
# which('ruby') #=> /usr/bin/ruby
def which(cmd)
  exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exts.each { |ext|
      exe = File.join(path, "#{cmd}#{ext}")
      return exe if File.executable?(exe) && !File.directory?(exe)
    }
  end
  return nil
end

# Returns the name of a file if it exists, or nil
# Used in ORing files
def file_exists(file)
  return nil unless File.exist?(file)
  return file
end

$stdout.sync = true # Disable stdout buffering
VERBOSE=options[:verbose]
START_TIME = Time.now
PROGRAM_ROOT = File.expand_path __dir__
HOME_DIR = file_exists("#{PROGRAM_ROOT}/homedir") || "#{PROGRAM_ROOT}/server"
INSTALL_DIR = file_exists("#{PROGRAM_ROOT}/installdir") || file_exists("#{PROGRAM_ROOT}/NWN") || ENV["NWN_INSTALLDIR"]
MODULE_DIR = "#{HOME_DIR}/modules"
CACHE_DIR = "#{PROGRAM_ROOT}/cache"
TMP_CACHE_DIR = "#{CACHE_DIR}/tmp"
GFF_CACHE_DIR = "#{CACHE_DIR}/gff"
NSS_DIR = "#{PROGRAM_ROOT}/src/nss"
ALL_NSS = "*.nss"
SOURCES = FileList["#{PROGRAM_ROOT}/src/**/*.*"]
NSS_COMPILER = ENV["NSS_COMPILER"] || "nwnsc"
ERF_UTIL = "nwn_erf"
GFF_UTIL = "nwn-gff"

def find_modfile()
  mod = FileList["#{MODULE_DIR}/*.mod"][0]
  return (mod.nil? || mod == "") ? "#{MODULE_DIR}/module.mod" : mod
end

MODULE_FILE = find_modfile

if VERBOSE
  puts "[DEBUG] Current environment:
  START_TIME: #{START_TIME}
  PROGRAM_ROOT: #{PROGRAM_ROOT}
  HOME_DIR: #{HOME_DIR}
  NSTALL_DIR: #{INSTALL_DIR}
  MODULE_DIR: #{MODULE_DIR}
  CACHE_DIR: #{CACHE_DIR}
  TMP_CACHE_DIR: #{TMP_CACHE_DIR}
  GFF_CACHE_DIR: #{GFF_CACHE_DIR}
  NSS_DIR: #{NSS_DIR}
  ALL_NSS: #{ALL_NSS}
  MODULE_FILE: #{MODULE_FILE}
  NSS_COMPILER: #{NSS_COMPILER}
  ERF_UTIL: #{ERF_UTIL}
  GFF_UTIL: #{GFF_UTIL}"
end

def verify_executables()
  abort "[ERROR] Cannot find #{ERF_UTIL} (needed for packing and extracting). Is it on your PATH?\n[ERROR] Aborting." unless which("#{ERF_UTIL}")
  abort "[ERROR] Cannot find #{GFF_UTIL} (needed for gff <=> yml conversion). Is it on your PATH?\n[ERROR] Aborting." unless which("#{GFF_UTIL}")
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
    abort "[ERROR] No module file found in folder \"#{MODULE_DIR}/\".\n[ERROR] Aborting."
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

  puts "[INFO] Extracting #{modfile}."
  Dir.chdir(TMP_CACHE_DIR) do
    tmp_files = FileList["#{TMP_CACHE_DIR}/*"]
    FileUtils.rm tmp_files
    exit_code = system "#{ERF_UTIL} -x -f #{modfile}"
    if !exit_code
      abort "[ERROR] Something went wrong while extracting #{modfile}.\n[ERROR] Aborting."
    end
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
      Kernel.exit(1) unless input.downcase == "y"
    end
  end

  puts "[INFO] Building #{modfile}"
  exit_code = system "#{ERF_UTIL}", "-e", "MOD", "-c", "#{TMP_CACHE_DIR}", "-f", "#{modfile}"
  if !exit_code
    abort "[ERROR] Something went wrong while building #{modfile}.\n[ERROR] Aborting."
  end
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
  puts "[INFO] Converting from gff to yml (this may take a while)..."

  remove_deleted_files(GFF_CACHE_DIR, SOURCES.sub(/\.yml$/, ''))
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/extract.rake"
  update_files_based_on_timestamp(FileList["#{GFF_CACHE_DIR}/*.nss"], "src/nss")
end

def update_gffs()
  puts "[INFO] Converting from yml to gff (this may take a while)..."

  gffs = FileList["#{GFF_CACHE_DIR}/*"].exclude(/\.ncs$/)
  srcs = FileList["src/**/*.*"].sub(/\.yml$/, '')
  gffs.each do |gff|
    FileUtils.rm(gff) unless srcs.detect{|src| File.basename(gff) == File.basename(src)}
  end
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/pack.rake"
  return update_files_based_on_timestamp(FileList["src/nss/*"], GFF_CACHE_DIR)
end

# Compile nss scripts. Module file not parsed for hak includes at the time of writing.
# Valid targets are any nss file names, including wildcards to process multiple files.
def compile_nss(modfile, target=ALL_NSS)
  puts "[INFO] Compiling nss #{target}"
  Dir.chdir(NSS_DIR) do
    exit_code = system "#{NSS_COMPILER} -qo -n #{INSTALL_DIR} -b #{GFF_CACHE_DIR} -y #{target}"
    if exit_code == nil
      puts "[ERROR]\tThe compiler at \"#{NSS_COMPILER}\" does not exist. Nothing was compiled.\n\tPlease set the NSS_COMPILER environment variable."
    elsif !exit_code
      puts "[ERROR]\tSomething went wrong during nss compilation. Check the compiler output."
    end
  end
end

def create_resman_symlinks
  system "rake", "--rakefile", "#{PROGRAM_ROOT}/symlink.rake"
end

def extract_all()
  verify_executables
  init_directories()
  extract_module(MODULE_FILE)
  update_cache(TMP_CACHE_DIR, GFF_CACHE_DIR)
  update_sources()

  elapsed_time = Time.now - START_TIME
  puts "[INFO] Done.\nTotal time: #{elapsed_time} seconds."
end

def pack_all()
  verify_executables
  init_directories()
  should_compile = update_gffs()
  compile_nss(MODULE_FILE) if should_compile
  update_cache(GFF_CACHE_DIR, TMP_CACHE_DIR)
  pack_module(MODULE_FILE)

  elapsed_time = Time.now - START_TIME
  puts "[INFO] Done.\nTotal time: #{elapsed_time} seconds."
end

def clean()
  FileUtils.rm_r Dir.glob("#{CACHE_DIR}/*")
end

# Verify the target YAML file. Throws an error when YAML parsing fails.
# Defaults to check all project yml files if no target specified.
def verify_yaml(target="src/**/*.yml")
  puts "[INFO] Verifying yaml"
  ymls=FileList[target]
  if OS.windows?
    puts "[INFO] This may take a while due to the lack of multithreading support on windows in the Parrallel gem..." unless ymls.size < 10
    ymls.each do |file|
      puts "[DEBUG] Verifying: #{file}" if VERBOSE
      YAML.load_file(file)
    end
  else
    Parallel.map(ymls) do |file|
      YAML.load_file(file)
      puts "[DEBUG] Verifying: #{file}" if VERBOSE
    end
  end
  puts "[INFO] Verification done. No errors detected."
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
end
