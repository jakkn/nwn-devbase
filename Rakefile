require 'rubygems'
require 'bundler/setup'

require 'systemu'
require 'nwn/all'
require 'fileutils'

namespace :main do
  desc 'Clean tmp folder'
  task :clean do
    FileUtils.rm_r Dir.glob('tmp/*')
  end
  desc 'Extract module'
  task :extract do
    Dir.chdir("tmp") do
      mod = Rake::FileList["../module/*.mod"]
      system "nwn-erf", "-x", "-f", mod[0]
    end
  end
  desc 'Move to src'
  task :move_sources do
    Dir.foreach('tmp') do |file|
      next if file == '.' or file == '..'
      ext = File.extname(file).delete('.')
      srcdir = 'src/'+ext
      FileUtils.mkdir_p(srcdir)
      FileUtils.mv Dir.glob('tmp/*.'+ext), srcdir
    end
  end
    # Dir.glob('tmp/*') { |filename|
    #   p File.extname(filename)
    # }
  desc 'Pack module'
  task :pack do
  end
end