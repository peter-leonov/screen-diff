#!/usr/bin/env ruby
require 'rmagick'

def dump file_src, io_dst
  img = Magick::Image.read(file_src).first
  w = img.columns
  h = img.rows
  io_dst.puts "RGB #{w} #{h}"
  h.times do |y|
    # x, y, columns, rows -> array
    io_dst.puts img.export_pixels(0, y, w, 1, 'RGB').join(' ')
  end
end

def load io_src, file_dst
  header = io_src.gets
  _, format, w, h = /^(RGB) (\d+) (\d+)/.match(header).to_a
  raise 'wrong format' unless format == 'RGB'
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


# CLI

case ARGV.shift
when 'dump'
  raise 'rgb dump: one arg needed: source.img' unless ARGV.length == 1
  dump ARGV.first, STDOUT
when 'load'
  raise 'rgb load: one arg needed: dst' unless ARGV.length == 1
  load STDIN, ARGV.first
else
  raise 'usage: rgb dump source.img | process | rgb load dest.img'
end
