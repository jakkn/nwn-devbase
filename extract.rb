TMP_GFFS = FileList["tmp/*"]
GFFS     = FileList["src/**/*.*"].exclude(/n[cs]s$|\.yml$/)

directory "tmp"
directory "src"

rule '.yml' => ->(f){ source_for_yml(f) } do |t|
  system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}"
  # FileUtils.rm "#{t.source}"
end

def source_for_yml(yml_file)
  GFFS.detect{|f| f == yml_file.sub(/\.yml$/, '')}
end


task :mod2gff => ["tmp", MODULE] do
  Dir.chdir("tmp") do
    system "nwn-erf", "-x", "-f", "../"+MODULE[0]
	end
end

desc 'Move to src'
task :move_sources => ["src", "extract"] do
  TMP_GFFS.each do |file|
    ext = File.extname(file).delete('.')
    srcdir = 'src/'+ext
    FileUtils.mkdir_p(srcdir)
    FileUtils.mv Dir.glob('tmp/*.'+ext), srcdir
  end
end

multitask :gff2yml => [:move_sources ,GFFS.inject(GFFS.class.new) {|res, fn| res << fn + '.yml' }]
