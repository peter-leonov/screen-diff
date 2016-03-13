#!/usr/bin/env ruby
require 'tmpdir'
require 'fileutils'

def main file_a, file_b, file_diff
  tmp = Dir.mktmpdir("compare-rb")

  system(*%W{./rgb.rb img-to-rgb #{file_a} #{tmp}/a.rgb})
  system(*%W{./rgb.rb img-to-rgb #{file_b} #{tmp}/b.rgb})

  diff = `diff -U10000 --minimal #{tmp}/a.rgb #{tmp}/b.rgb`.lines
  raise 'empty diff' if diff.empty?

  head = diff.shift(3)
  raise 'wrong diff header' unless head[0]['---'] && head[1]['+++'] && head[2]['@@']
  raise 'wrong format' unless diff.shift['RGB']

  size_a = diff.shift
  raise 'TODO: do nothing for same size images' if size_a[0] == ' '
  size_b = diff.shift
  raise 'wrong sizes diff' unless size_a[0] == '-' && size_b[0] == '+'
  size_rex = /.(\d+) (\d+)/
  width_a = size_rex.match(size_a)[1].to_i
  width_b = size_rex.match(size_b)[1].to_i
  raise "different widths: #{width_a} and #{width_b}" if width_a != width_b
  width = width_a

  colors = diff.shift[1..-1]

  a, b = parse(width, diff)

  write "#{tmp}/da.rgb", width, colors, a
  write "#{tmp}/db.rgb", width, colors, b
  system(*%W{./rgb.rb rgb-to-img #{tmp}/da.rgb #{tmp}/da.png})
  system(*%W{./rgb.rb rgb-to-img #{tmp}/db.rgb #{tmp}/db.png})

  system(*%W{compare #{tmp}/da.png #{tmp}/db.png #{tmp}/diff.png})
  system(*%W{montage -geometry +4+0 #{tmp}/da.png #{tmp}/diff.png #{tmp}/db.png #{file_diff}})
ensure
  FileUtils.remove_entry tmp
end


def parse width, diff
  spacer = ([65535] * (width * 3)).join(' ') + "\n"
  last_line_a = spacer
  last_line_b = spacer
  a = []
  b = []
  minus = 0
  plus = 0
  add = proc do
    if minus < plus
      # puts "#{minus} < #{plus}"
      (plus - minus).times { a << last_line_a }
    elsif minus > plus
      # puts "#{minus} > #{plus}"
      (minus - plus).times { b << last_line_b }
    else
      # puts "#{minus} = #{plus}"
    end
    minus = 0
    plus = 0
  end

  loop do
    if diff.empty?
      add.call()
      break
    end
    line = diff.shift
    if line[0] == ' '
      # puts ' '
      add.call()
      a << last_line_a = line[1..-1]
      b << last_line_b = line[1..-1]
    elsif line[0] == '-'
      # puts '-'
      a << last_line_a = line[1..-1]
      minus += 1
    elsif line[0] == '+'
      # puts '+'
      b << last_line_b = line[1..-1]
      plus += 1
    end
  end
  
  return a, b
end

def write name, width, colors, lines
  File.open(name, 'w') do |f|
    f.puts 'RGB'
    f.puts "#{width} #{lines.size}"
    f.print colors
    lines.each { |line| f.print line }
  end
end

raise 'three args needed: a b diff' unless ARGV.length == 3
main *ARGV
