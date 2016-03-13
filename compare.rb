#!/usr/bin/env ruby

def main file_a, file_b, file_diff
  system(*%W{convert #{file_a} -compress none tmp/a.pgm})
  system(*%W{convert #{file_b} -compress none tmp/b.pgm})

  diff = `diff -U10000 --minimal tmp/a.pgm tmp/b.pgm`.lines
  raise 'empty diff' if diff.empty?

  head = diff.shift(3)
  raise 'wrong diff header' unless head[0]['---'] && head[1]['+++'] && head[2]['@@']
  raise 'wrong format' unless diff.shift['P2']

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

  write 'tmp/da.pgm', width, colors, a
  write 'tmp/db.pgm', width, colors, b
  system('convert tmp/da.pgm tmp/da.png')
  system('convert tmp/db.pgm tmp/db.png')

  system('compare tmp/da.png tmp/db.png tmp/diff.png')
  system(*%W{montage -geometry +4+0 #{file_a} tmp/diff.png #{file_b} #{file_diff}})
end


def parse width, diff
  spacer = '255 ' * width + "\n"
  a = []
  b = []
  minus = 0
  plus = 0
  add = proc do
    if minus < plus
      (plus - minus).times { a << spacer }
    elsif minus > plus
      (minus - plus).times { b << spacer }
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
      add.call()
      a << line[1..-1]
      b << line[1..-1]
    elsif line[0] == '-'
      a << line[1..-1]
      minus += 1
    elsif line[0] == '+'
      b << line[1..-1]
      plus += 1
    end
  end
  
  return a, b
end

def write name, width, colors, lines
  File.open(name, 'w') do |f|
    f.puts 'P2'
    f.puts "#{width} #{lines.size}"
    f.print colors
    lines.each { |line| f.print line }
  end
end

raise 'three args needed: a b diff' unless ARGV.length == 3
main *ARGV
