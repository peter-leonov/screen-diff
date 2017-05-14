#!/usr/bin/env ruby
require 'tmpdir'
require 'fileutils'
require 'rmagick'

def main file_a, file_b, file_result
  tmp = Dir.mktmpdir("compare-rb")

  img_to_rgb(file_a, "#{tmp}/a.rgb")
  img_to_rgb(file_b, "#{tmp}/b.rgb")

  diff = `diff -U10000 --minimal #{tmp}/a.rgb #{tmp}/b.rgb`.lines
  if diff.empty?
    # just compare identical images as compare normally would
    final_cut(tmp, file_a, file_b, file_result)
    return
  end

  head = diff.shift(3)
  raise 'wrong diff header' unless head[0]['---'] && head[1]['+++'] && head[2]['@@']
  raise 'wrong format' unless diff.shift['RGB']

  size_a = diff.shift
  if size_a[0] == ' '
    # just compare same height images as compare normally would
    final_cut(tmp, file_a, file_b, file_result)
    return
  end
  size_b = diff.shift
  raise 'wrong sizes diff' unless size_a[0] == '-' && size_b[0] == '+'
  size_rex = /.(\d+) (\d+)/
  width_a = size_rex.match(size_a)[1].to_i
  width_b = size_rex.match(size_b)[1].to_i
  raise "different widths: #{width_a} and #{width_b}" if width_a != width_b
  width = width_a

  colors = diff.shift[1..-1]

  a, b = parse(width, diff)

  write_rgb "#{tmp}/da.rgb", width, colors, a
  write_rgb "#{tmp}/db.rgb", width, colors, b

  rgb_to_img("#{tmp}/da.rgb", "#{tmp}/da.png")
  rgb_to_img("#{tmp}/db.rgb", "#{tmp}/db.png")

  final_cut(tmp, "#{tmp}/da.png", "#{tmp}/db.png", file_result)
ensure
  FileUtils.remove_entry tmp
end

def final_cut tmp, file_a, file_b, file_result
  file_diff = "#{tmp}/diff.png"
  system(*%W{compare #{file_a} #{file_b} #{file_diff}})
  system(*%W{montage -geometry +4+0 #{file_a} #{file_diff} #{file_b} #{file_result}})
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
      add.()
      break
    end
    line = diff.shift
    if line[0] == ' '
      # puts ' '
      add.()
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

def write_rgb name, width, colors, lines
  File.open(name, 'w') do |f|
    f.puts 'RGB'
    f.puts "#{width} #{lines.size}"
    f.print colors
    lines.each { |line| f.print line }
  end
end

def img_to_rgb file_src, file_dst
  img = Magick::Image.read(file_src).first
  w = img.columns
  h = img.rows
  io_dst = File.open(file_dst, 'w')
  io_dst.puts "RGB"
  io_dst.puts "#{w} #{h}"
  h.times do |y|
    # x, y, columns, rows -> array
    io_dst.puts img.export_pixels(0, y, w, 1, 'RGB').join(' ')
  end
  io_dst.close
end

def rgb_to_img file_src, file_dst
  io_src = File.open(file_src, 'r')
  format = io_src.readline.chomp
  raise 'wrong format' unless format == 'RGB'
  _, w, h = /^(\d+) (\d+)/.match(io_src.readline).to_a
  raise 'wrong format' unless w && h
  w = w.to_i
  h = h.to_i

  img = Magick::Image.new(w, h)

  h.times do |y|
    pixels = io_src.readline.split(' ').map(&:to_i)
    # x, y, columns, rows, format, array
    img.import_pixels(0, y, w, 1, 'RGB', pixels)
  end

  img.write(file_dst)
end


raise 'three args needed: a b diff' unless ARGV.length == 3
main *ARGV
