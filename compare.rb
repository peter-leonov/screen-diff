#!/usr/bin/env ruby

# raise 'three args needed: a b diff' unless ARGV.length == 3

system('convert a.png -compress none a.pgm')
system('convert b.png -compress none b.pgm')
system('diff -U10000 a.pgm b.pgm > diff.pgm')

diff = File.readlines('diff.pgm')
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

spacer = '255 ' * width

a = []
b = []

colors = diff.shift

loop do
  c = diff.shift or break
  if c[0] == ' '
    a << c[1..-1]
    b << c[1..-1]
  end
end

da = File.open('da.pgm','w')
# db = File.open('db.pgm','w')
da.puts 'P2'
da.puts "#{width} #{a.size}"
da.print colors
a.each { |line| da.print line }
da.close

system('convert da.pgm da.png')

# compare a.png b.png png:- | montage -geometry +4+0 a.png - b.png diff.png