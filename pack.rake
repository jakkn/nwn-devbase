require 'nwn/all'
require 'fileutils'
require 'pathname'


def to_forward_slash(path=Pathname.getwd)
  return path.to_s.gsub(File::ALT_SEPARATOR || File::SEPARATOR, File::SEPARATOR)
end

task :default => :gff

SRC_DIR = Pathname.new ENV['SRC_DIR']
GFF_CACHE_DIR = Pathname.new ENV['GFF_CACHE_DIR']
ENCODING = ENV['ENCODING']

YML_SOURCES = FileList[to_forward_slash SRC_DIR.join("**/*.yml")].exclude(/n[cs]s$/)
GFF_TARGETS = YML_SOURCES.pathmap("#{GFF_CACHE_DIR}/%n")

directory GFF_CACHE_DIR.to_s

desc 'Convert yml to gff'
task :gff => [GFF_CACHE_DIR.to_s, :yml2gff]

multitask :yml2gff => GFF_TARGETS

rule( /\.(?!yml)[\w]+$/ => ->(f){ 
		source_for_gff(f)
	}) do |t|
	puts "[INFO] packing changed file: %s" % File.basename(t.name)
	# -i IN                       Input file [default: -]
	# -o OUT                      Output file [default: -]
	# -k OUTFORMAT                Output format [default: autodetect]
	system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}", "-kg", "--encoding", "#{ENCODING}"
	FileUtils.touch "#{t.name}", :mtime => File.mtime("#{t.source}")
end

def source_for_gff(gff)
	type = File.extname(gff).delete('.')
	SRC_DIR.join(type, "#{File.basename(gff)}.yml")
end
