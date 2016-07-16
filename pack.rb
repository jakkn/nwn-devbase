YMLS = FileList["src/**/*.yml"].exclude(/n[cs]s$/)

rule( /\.(?!yml)[\w]+$/ => [
  proc {|task_name| task_name.sub(/$/, '.yml') }
]) do |t|
  system "nwn-gff", "-i", "#{t.source}", "-o", "#{t.name}"
  # FileUtils.rm "#{t.source}"
end

multitask :yml2gff => YMLS.sub(/\.yml$/, '')
