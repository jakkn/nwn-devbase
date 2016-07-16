require 'rubygems'
require 'bundler/setup'

require 'systemu'
require 'nwn/all'
require 'fileutils'

MODULE    = FileList["module/*.mod"]

namespace :extract do
  require_relative "./extract.rb"

  desc 'Extract module'
  task :module => :mod2gff

  desc 'Convert gff to yml'
  task :yml => :gff2yml
end


namespace :pack do
  require_relative "./pack.rb"

  desc 'Convert yml to gff'
  task :gff => :yml2gff

  desc 'Pack module'
  task :module => :gff2mod do
  end
end

namespace :clean do
  desc 'Clean tmp folder'
  task :tmp do
    FileUtils.rm_r Dir.glob('tmp/*')
  end
end