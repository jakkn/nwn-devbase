require 'rubygems'
require 'bundler/setup'

require 'nwn/all'
require 'fileutils'

MODULE    = FileList["module/*.mod"]
YMLS = FileList["src/**/*.yml"].exclude(/n[cs]s$/)


desc 'Convert yml to gff'
task :gff => :yml2gff
desc 'Pack module'
task :module => :gff2mod do
end


rule( /\.(?!yml)[\w]+$/ => [
  proc {|task_name| task_name.sub(/$/, '.yml') }
]) do |t|
  system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}"
  # FileUtils.rm "#{t.source}"
end

multitask :yml2gff => YMLS.sub(/\.yml$/, '')
