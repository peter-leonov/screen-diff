#!/usr/bin/env ruby

def main file_a, file_b, file_diff
  system(*%W{./rgb.rb dump #{file_a} tmp/a.rgb})
  system(*%W{./rgb.rb dump #{file_b} tmp/b.rgb})

  diff = `diff -U10000 --minimal tmp/a.rgb tmp/b.rgb`.lines
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

  write 'tmp/da.rgb', width, colors, a
  write 'tmp/db.rgb', width, colors, b
  system('./rgb.rb load tmp/da.rgb tmp/da.png')
  system('./rgb.rb load tmp/db.rgb tmp/db.png')

  system('compare tmp/da.png tmp/db.png tmp/diff.png')
  system(*%W{montage -geometry +4+0 tmp/da.png tmp/diff.png tmp/db.png #{file_diff}})
end


def parse width, diff
  spacer = ([65535] * (width * 3)).join(' ') + "\n"
  a = []
  b = []
  minus = 0
  plus = 0
  add = proc do
    if minus < plus
      # puts "#{minus} < #{plus}"
      (plus - minus).times { a << spacer }
    elsif minus > plus
      # puts "#{minus} > #{plus}"
      (minus - plus).times { b << spacer }
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
      a << line[1..-1]
      b << line[1..-1]
    elsif line[0] == '-'
      # puts '-'
      a << line[1..-1]
      minus += 1
    elsif line[0] == '+'
      # puts '+'
      b << line[1..-1]
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
