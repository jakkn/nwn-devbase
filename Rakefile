require 'rubygems'
require 'bundler/setup'

require 'systemu'
require 'nwn/all'
require 'fileutils'


MODULE    = FileList["module/*.mod"]
TMP_GFFS  = FileList["tmp/*"]
GFFS      = FileList["src/**/*.*"].exclude(/n[cs]s$/)
GFF2YML   = GFFS.ext('.yml')

rule '.yml' => ->(f){ FileList[f.ext(".*")].first } do |t|
  system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}"
  FileUtils.rm "#{t.source}"
end

directory "tmp"
directory "src"

namespace :main do
  desc 'Clean tmp folder'
  task :clean do
    FileUtils.rm_r Dir.glob('tmp/*')
  end

  desc 'Extract module'
  task :extract => ["tmp", MODULE] do
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

  desc 'Gff to Yaml'
  multitask :yml => GFF2YML
    # GFF.each do |gff|
    #   puts gff
    # end
    # def allGffToYml(dir)
    #   Dir.chdir(dir) do
    #     files = Rake::FileList['*']
    #     pr = puts files
    #   end
    # end
    # Dir.foreach('src') do |dir|
    #   next if dir == '.' or dir == '..' or dir == 'nss' or dir == 'ncs'
    #   allGffToYml('src/'+dir)
    # end
  # end
    # Dir.glob('tmp/*') { |filename|
    #   p File.extname(filename)
    # }

  desc 'Pack module'
  task :pack do
  end
end