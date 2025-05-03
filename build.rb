#!/usr/bin/env ruby
#
# INTRODUCTION
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
# Managing which files are updated is done by caching the resources
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
# overwriting changes. The same goes for packing a module with a
# newer time stamp than the latest yml source. This is not a perfect
# safety net as updating the module without extracting it and then
# updating a yml resource will overwrite the module on the next
# attempt to pack without a prompt, but it is better than nothing.
# It is left for the user not to mess up.
#
#
# FOLDER STRUCTURE
#
# Two folder structures are supported. Flat folder layout is used if the src
# directory is already flat and contains no subfolders, and can be forced
# with -f. Otherwise the script defaults to subfolder layout.
#
#         flat
# src
# ├── foo.are.yml
# ├── area.gic.yml
# ├── area.git.yml
# ├── module.ifo.yml
# ├── module.jrl.yml
# ├── script1.nss
# └── script2.nss
#
#         subfolders
# src
# ├── are
# │  └── foo.are.yml
# ├── gic
# │  └── area.gic.yml
# ├── git
# │  └── area.git.yml
# ├── ifo
# │  └── module.ifo.yml
# ├── jrl
# │  └── module.jrl.yml
# └── nss
#    ├── script1.nss
#    └── script2.nss
#
#
# CONFIGURATION
#
# Use config.rb to define configurations and compiler arguments.
# See example file config.rb.in.
# Configuration files are read highest priority first, starting with
# project configs and ending with global configs:
# .nwnproject/config.rb
# .nwnproject/config.rb.in
# EXECUTION_DIR/config.rb
# EXECUTION_DIR/config.rb.in
#
# Where EXECUTION_DIR is the PATH from which build.rb
# executes on your system.
#
#
# SCRIPT EXECUTION
#
# The script begins by parsing arguments and setting the environment
# variables, before command execution is carried out in the bottom
# case block.
#
# Notes on using build.rb as a tool on PATH:
#
# The project root is used to locate resources, and may not necessarily
# be the working directory as given by the command $(pwd). For
# instance, one may navigate to src/nss while working on scripts, and
# then run the compile or pack command at which point the project
# root will be ../../ relative to $(pwd). One solution would be to use this
# file's location and simply expect it to be located in the project root.
# This expectation holds as long as this script is used as a build script
# that is part of the project, but fails when one wishes to use the script as
# a command line tool located on the PATH, something that would be
# useful in, for instance, a containerized build environment.
#
# When used as a tool, the tool needs to be able to locate the resources
# where it expects them. To enable this, the tool looks for a directory
# named .nwnproject upwards in the directory tree with the deepest
# level being $(pwd). If not found, $(pwd) is assumed to be the project
# root.

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'highline/import'
require 'digest/md5'
require 'os'
require 'yaml'
require 'parallel'
require 'optparse'
require 'ptools'
require 'pathname'

# Show usage on no arguments
ARGV << '-h' if ARGV.empty?

# Parse script arguments
options = {}
OptionParser.new do |opts|
  opts.banner ="Usage:
    ruby build.rb [options] extract\t\t\tExtract .mod to src/
    ruby build.rb [options] pack\t\t\tPack src/ into .mod
    ruby build.rb [options] pack-only\t\t\tPack src/ into .mod without compiling nss
    ruby build.rb [options] clean\t\t\tClean cache folder
    ruby build.rb [options] compile [file]\t\tCompile nss to ncs
    ruby build.rb [options] resman\t\t\tCreate/refresh resman symlinks
    ruby build.rb [options] verify [file]\t\tVerify YAML
    ruby build.rb [options] init\t\t\tInitialize a new project
    ruby build.rb [options] install\t\t\tAdd to PATH as command 'nwn-build'
    ruby build.rb [options] install-as [cmd]\t\tAdd to PATH as [cmd]
  
Options:"
  opts.on("-f", "--flat", "Assume flat folder layout with no sub directories in src/") do |f|
    options[:flat] = f
  end
  opts.on("-v", "--[no-]verbose", "Turn on debug logging") do |v|
    options[:verbose] = v
  end
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

# Returns the name of a file if it exists, or nil
# Used in ORing files
def file_exists(file)
  return nil unless File.exist?(file)
  return file
end

# Performs a directory search for the folder named '.nwnproject'. The  search starts
# at the given node and looks for the folder in each parent of the given node all the
# way to root.
# Params:
# +path+:: Pathname object describing the search starting path
#
# If found returns the Pathname object describing the '.nwnproject' folder, else nil.
def find_nwnproject(path=Pathname.getwd)
  return path.join(".nwnproject") if path.join(".nwnproject").exist?
  # Count slashes as workaround for broken Pathname.root? with win32-file
  # Ref: https://github.com/chef/win32-file/issues/8
  return nil if path.to_s.scan(/\//).count == 1 || path.root?
  return find_nwnproject(path.parent)
end

def to_forward_slash(path=Pathname.getwd)
  return path.to_s.gsub(File::ALT_SEPARATOR || File::SEPARATOR, File::SEPARATOR)
end

$stdout.sync = true # Disable stdout buffering
VERBOSE = options[:verbose]
START_TIME = Time.now
EXECUTION_DIR = Pathname.new(File.expand_path __dir__)
WORKING_DIR = Pathname.getwd
nwnproject_path = find_nwnproject(WORKING_DIR)
PROJECT_ROOT = nwnproject_path ? nwnproject_path.parent : WORKING_DIR
NWNPROJECT = nwnproject_path || PROJECT_ROOT.join(".nwnproject") # append .nwnproject to project root if not found
PROJECT_USER_CONFIG = file_exists(NWNPROJECT.join("config.rb")) || ""
PROJECT_DEFAULT_CONFIG = file_exists(NWNPROJECT.join("config.rb.in")) || ""
GLOBAL_USER_CONFIG = file_exists(EXECUTION_DIR.join("config.rb")) || ""
GLOBAL_DEFAULT_CONFIG = file_exists(EXECUTION_DIR.join("config.rb.in")) || ""
load(PROJECT_USER_CONFIG) if File.exist?(PROJECT_USER_CONFIG) # Prioritize project user configs by loading first
load(PROJECT_DEFAULT_CONFIG) if File.exist?(PROJECT_DEFAULT_CONFIG) # Load project default configs second
load(GLOBAL_USER_CONFIG) if File.exist?(GLOBAL_USER_CONFIG) # Load global user configs third
load(GLOBAL_DEFAULT_CONFIG) if File.exist?(GLOBAL_DEFAULT_CONFIG) # Load global default configs last
SOURCES = FileList[to_forward_slash SRC_DIR.join("**", "*.*")] # *.* to skip directories
FLAT_LAYOUT = options[:flat] || (SOURCES.size > 0 && Pathname.glob(to_forward_slash SRC_DIR.join("*/")).size == 0) || false # Assume flat layout only on -f or if the source folder contains files but no directories
NSS_DIR = FLAT_LAYOUT ? SRC_DIR : SRC_DIR.join("nss")


if VERBOSE
  puts "[DEBUG] Current environment:
  FLAT_LAYOUT: #{FLAT_LAYOUT}
  START_TIME: #{START_TIME}
  ARGV: #{ARGV}
  EXECUTION_DIR: #{EXECUTION_DIR}
  WORKING_DIR: #{WORKING_DIR}
  NWNPROJECT: #{NWNPROJECT}
  PROJECT_ROOT: #{PROJECT_ROOT}
  PROJECT_USER_CONFIG: #{PROJECT_USER_CONFIG}
  PROJECT_DEFAULT_CONFIG: #{PROJECT_DEFAULT_CONFIG}
  GLOBAL_USER_CONFIG: #{GLOBAL_USER_CONFIG}
  GLOBAL_DEFAULT_CONFIG: #{GLOBAL_DEFAULT_CONFIG}
  HOME_DIR: #{HOME_DIR}
  INSTALL_DIR: #{INSTALL_DIR}
  MODULE_DIR: #{MODULE_DIR}
  MODULE_FILENAME: #{MODULE_FILENAME}
  MODULE_FILE_EXT: #{MODULE_FILE_EXT}
  MODULE_FILE: #{MODULE_FILE}
  CACHE_DIR: #{CACHE_DIR}
  TMP_CACHE_DIR: #{TMP_CACHE_DIR}
  GFF_CACHE_DIR: #{GFF_CACHE_DIR}
  SRC_DIR: #{SRC_DIR}
  NUMBER_OF_SOURCES: #{SOURCES.size}
  NSS_DIR: #{NSS_DIR}
  NSS_BATCHOUTDIR: #{NSS_BATCHOUTDIR}
  NSS_COMPILER: #{NSS_COMPILER}
  COMPILER_ARGS: #{COMPILER_ARGS}
  ERF_UTIL: #{ERF_UTIL}
  GFF_UTIL: #{GFF_UTIL}
  RESMAN_DIR: #{RESMAN_DIR}
  EXTRACT_RAKE: #{EXTRACT_RAKE}
  PACK_RAKE: #{PACK_RAKE}
  SYMLINK_RAKE: #{SYMLINK_RAKE}
  SCRIPTS_DIR: #{SCRIPTS_DIR}
  ENCODING: #{ENCODING}"
end

def verify_executables()
  abort "[ERROR] Cannot find #{ERF_UTIL} (needed for packing and extracting). Is it on your PATH?\n[ERROR] Aborting." unless File.which("#{ERF_UTIL}")
  abort "[ERROR] Cannot find #{GFF_UTIL} (needed for gff <=> yml conversion). Is it on your PATH?\n[ERROR] Aborting." unless File.which("#{GFF_UTIL}")
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
  Dir.chdir(to_forward_slash TMP_CACHE_DIR) do
    tmp_files = FileList[to_forward_slash TMP_CACHE_DIR.join("*")]
    FileUtils.rm tmp_files
    exit_code = system "#{ERF_UTIL}", "-x", "-f", "#{modfile}"
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
  target_files = FileList[to_forward_slash target_dir.join("*.*")]
  remove_deleted_files(source_dir, target_files)

  source_files = FileList[to_forward_slash source_dir.join("*.*")]
  update_files_based_on_digest(source_files, target_dir)
end

# Delete files in target_files list that do not exist in source_dir
def remove_deleted_files(source_dir, target_files)
  return if target_files.empty?
  target_files.each do |file|
    FileUtils.rm(File.exist?(file) ? file : file + ".yml") unless File.exist?(source_dir.join(File.basename(file)))
  end
end

# Update all source_files that have a different digest than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_digest(source_files, target_dir)
  source_files.each do |file|
    if !File.exist?(target_dir.join(File.basename(file)))
      FileUtils.cp(file, target_dir)
    else
      tmp_digest = Digest::MD5.hexdigest(File.open(file, "rb") { |f| f.read })
      gff_digest = Digest::MD5.hexdigest(File.open(target_dir.join(File.basename(file)), "rb") { |f| f.read })
      FileUtils.cp(file, target_dir) if tmp_digest != gff_digest
    end
  end
end

# Update all source_files that have a different time stamp than the corresponding
# file in target_dir. New files are copied over.
def update_files_based_on_timestamp(source_files, target_dir)
  FileUtils.mkdir_p(target_dir)
  files_updated = false
  source_files.each do |file|
    if !File.exist?(target_dir.join(File.basename(file)))
      FileUtils.cp(file, target_dir)
      files_updated = true
    elsif File.mtime(file) > File.mtime(target_dir.join(File.basename(file)))
      FileUtils.cp(file, target_dir)
      files_updated = true
    end
  end
  return files_updated
end

def update_sources()
  puts "[INFO] Converting from gff to yml (this may take a while)..."
  remove_deleted_files(GFF_CACHE_DIR, SOURCES.sub(/\.yml$/, ''))
  system "rake", "--rakefile", EXTRACT_RAKE.to_s, "flat=#{FLAT_LAYOUT}", "SRC_DIR=#{SRC_DIR}", "GFF_CACHE_DIR=#{GFF_CACHE_DIR}", "SCRIPTS_DIR=#{SCRIPTS_DIR}", "ENCODING=#{ENCODING}"
  update_files_based_on_timestamp(FileList[to_forward_slash GFF_CACHE_DIR.join("*.nss")], NSS_DIR)
end

def update_gffs()
  puts "[INFO] Converting from yml to gff (this may take a while)..."

  gffs = FileList[to_forward_slash GFF_CACHE_DIR.join("*")].exclude(/\.ncs$/)

  gffs.each do |gff|
    # extension is a name of the subfolder
    type = File.extname(gff).delete('.')
    # remove from gff cache if there is no associated file in src directory
    # (taking into account subfolder with type and that nss files don't have an yml extension)
    unless File.exist?(SRC_DIR.join(type, "#{File.basename(gff)}#{unless type == "nss" then ".yml" end }"))
      puts "[INFO] %s removed from cache since it doesn't have a source" % File.basename(gff)
      FileUtils.rm(gff)
    end
  end

  system "rake", "--rakefile", PACK_RAKE.to_s, "SRC_DIR=#{SRC_DIR}", "GFF_CACHE_DIR=#{GFF_CACHE_DIR}", "ENCODING=#{ENCODING}"

  return update_files_based_on_timestamp(FileList[to_forward_slash NSS_DIR.join("*.nss")], GFF_CACHE_DIR)
end

# Compile nss scripts. Module file not parsed for hak includes at the time of writing.
# Valid targets are any nss file names or directories.
def compile_nss(modfile, target="#{NSS_DIR}")
  puts "[INFO] Compiling nss"
  FileUtils.mkdir_p(NSS_BATCHOUTDIR)

  command = [NSS_COMPILER,  *COMPILER_ARGS, *target]
  puts "[DEBUG] #{command.join(" ")}" if VERBOSE # Print the command line we are using to compile
  exit_code = system *command # Execute the printed commmand
  if exit_code == nil # unknown command
    abort "[ERROR] The compiler at \"#{NSS_COMPILER}\" does not exist. Nothing was compiled.\n\tPlease set the NSS_COMPILER environment variable.\n[ERROR] Aborting."
  elsif !exit_code # nonzero exit
    abort "[ERROR] Something went wrong during nss compilation. Check the compiler output.\n[ERROR] Aborting."
  end
end

def create_resman_symlinks
  system "rake", "--rakefile", SYMLINK_RAKE.to_s, "RESMAN_DIR=#{RESMAN_DIR}", "GFF_CACHE_DIR=#{GFF_CACHE_DIR}"
end

def init_nwnproject()
  # Create .nwnproject folder
  target=WORKING_DIR.join(".nwnproject")
  puts "[INFO] Creating #{target.to_s}"
  puts "[INFO] #{target.to_s} already exists" if target.exist?
  target.mkdir unless target.exist?
  # Put .gitignore in folder to have something to check in, and ignore cache folder
  gitignore = target.join(".gitignore")
  puts "[INFO] Creating #{gitignore}"
  File.write(gitignore, "cache\n", mode: 'a') unless qgrep("^cache$", gitignore)
  # Prompt to configure module filename
  input_filename = ask "Module filename (#{File.basename MODULE_FILE}):"
  input_filename = File.basename MODULE_FILE if input_filename.to_s.empty?
  config = NWNPROJECT.join("config.rb.in")
  File.write(config, "#!/usr/bin/env ruby\n\n") unless config.exist?
  File.write(config, "MODULE_FILENAME ||= \"#{input_filename}\"\n", mode: 'a') unless qgrep("^MODULE_FILENAME", config)
  # Prompt to create ./server/modules dir
  create_moduledir = ask "Create default module directory (#{MODULE_DIR})? [Y/n]:"
  if create_moduledir.empty? || create_moduledir.downcase[0] == "y"
    FileUtils.mkdir_p(MODULE_DIR)
    gitignore=WORKING_DIR.join(".gitignore")
    File.write(gitignore, "server\n", mode: 'a') unless qgrep("^server$", gitignore)
  end
end

# Quiet grep that returns a boolean indicating if pattern matches anywhere in file. 
def qgrep(pattern, file)
  return file.exist? && File.open(file).grep(/#{pattern}/).any?
end

def install_devbase(cmd="nwn-build")
  abort "[INFO] The command #{cmd} already exists on PATH." if File.which(cmd)
  abort "[INFO] Automatic symlinking of build.rb to PATH is not supported on Windows." if OS.windows?
  source=EXECUTION_DIR.join $PROGRAM_NAME
  bin_dir=Pathname.new(ENV["HOME"]).join("bin")
  dest=bin_dir.join(cmd)
  bin_dir.mkdir unless bin_dir.exist?
  puts "[INFO] Symlinking #{source} to #{dest}"
	FileUtils.symlink(source, dest)
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

def pack_all(skip_compile=false)
  verify_executables
  init_directories()

  if skip_compile
    puts "[INFO] Skipping compilation due to configuration"
  end
    
  should_compile = update_gffs()
  if should_compile && !skip_compile
    puts "[INFO] No change in nss sources detected. Skipping compilation."
  end

  compile_nss(MODULE_FILE) unless skip_compile
  update_cache(GFF_CACHE_DIR, TMP_CACHE_DIR)
  pack_module(MODULE_FILE)

  elapsed_time = Time.now - START_TIME
  puts "[INFO] Done.\nTotal time: #{elapsed_time} seconds."
end

def clean()
  FileUtils.rm_r Dir.glob(to_forward_slash(CACHE_DIR.join("*")))
end

# Verify the target YAML file. Throws an error when YAML parsing fails.
# Defaults to check all project yml files if no target specified.
def verify_yaml(target=SRC_DIR.join("**").join("*.yml"))
  puts "[INFO] Verifying yaml"
  ymls=FileList[to_forward_slash target]
  if OS.windows?
    puts "[INFO] This may take a while due to the lack of multithreading support on windows in the Parallel gem..." unless ymls.size < 10
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
when "init"
  init_nwnproject
when "install"
  install_devbase 
when "install-as"
  install_devbase ARGV.shift 
when "extract"
  extract_all
when "pack-only"
  pack_all(true)
when "pack"
  pack_all
when "clean"
  clean
when "compile"
  ARGV.any? ? compile_nss(MODULE_FILE, ARGV) : compile_nss(MODULE_FILE)
when "resman"
  create_resman_symlinks
when "verify"
  target = ARGV.shift || to_forward_slash(SRC_DIR.join("**", "*.yml"))
  verify_yaml(target)
end
