require 'rubygems'
require 'bundler/setup'

require 'systemu'
require 'nwn/all'
require 'fileutils'


MODULE    = FileList["module/*.mod"]
GFF       = FileList["tmp/*"]
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
    GFF.each do |file|
      ext = File.extname(file).delete('.')
      srcdir = 'src/'+ext
      FileUtils.mkdir_p(srcdir)
      FileUtils.mv Dir.glob('tmp/*.'+ext), srcdir
    end
  end

  desc 'Gff to Yaml'
  task :yml do
    def allGffToYml(dir)
      Dir.chdir(dir) do
        files = Rake::FileList['*']
        pr = puts files
      end
    end
    Dir.foreach('src') do |dir|
      next if dir == '.' or dir == '..' or dir == 'nss' or dir == 'ncs'
      allGffToYml('src/'+dir)
    end
  end
    # Dir.glob('tmp/*') { |filename|
    #   p File.extname(filename)
    # }

  desc 'Pack module'
  task :pack do
  end
end