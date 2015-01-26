#! /usr/bin/env ruby
raise 'Please run from base lilKanren dir' unless Dir.exists? 'crumpled-paper'

require 'pathname'

def makeindex(path, file, level = 0)
  puts path
  address = "http://nbviewer.ipython.org/github/lilinjn/lilKanren/blob/master/"
  path.children.collect do |child|
    if child.file? and child.extname == ".ipynb"
      file.write((' ' * level) + '* [' + child.basename('.*').to_s + "]\n")
      file.write('[' + child.basename('.*').to_s + "]: #{address}#{child.to_s}" + "\n")

    elsif child.directory? and !child.basename.to_s.start_with?('.')
      file.write((' ' * level) + '* ' + child.basename.to_s + "\n")
      makeindex(child, file, level+1)
    end
  end
end


File.open('crumpled-paper/Index.MD', 'w') do |file|
  header = <<HEADER
Crumpled Paper
===============
HEADER
  file.write(header)
  makeindex(Pathname.new('crumpled-paper'), file, 0)
end