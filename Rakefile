require 'rubygems'
require 'bundler/setup'

require 'fileutils'

namespace :clean do
  desc 'Clean tmp folder'
  task :tmp do
    FileUtils.rm_r Dir.glob('tmp/*')
  end
end