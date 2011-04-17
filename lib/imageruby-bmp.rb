=begin

This file is part of the imageruby-bmp project, http://github.com/tario/imageruby-bmp

Copyright (c) 2010 Roberto Dario Seminara <robertodarioseminara@gmail.com>

imageruby-bmp is free software: you can redistribute it and/or modify
it under the terms of the gnu general public license as published by
the free software foundation, either version 3 of the license, or
(at your option) any later version.

imageruby-bmp is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.  see the
gnu general public license for more details.

you should have received a copy of the gnu general public license
along with imageruby-bmp.  if not, see <http://www.gnu.org/licenses/>.

=end
require "imageruby/decoder"

module ImageRuby
  class BmpDecoder < ImageRuby::Decoder
    def decode(data, image_class)

      # read bmp header
      header = data[0..13]
      dib_header = data[14..54]

      magic = header[0..1]

      # check magic
      unless magic == "BM"
        raise UnableToDecodeException
      end

      pixeldata_offset = header[10..13].unpack("L").first

      width = dib_header[4..7].unpack("L").first
      height = dib_header[8..11].unpack("L").first

      # create image object

      image = image_class.new(width,height)

      padding_size = ( 4 - (width * 3 % 4) ) % 4
      width_array_len = width*3 + padding_size

      # read pixel data
      height.times do |y|
        offset = pixeldata_offset+(height-y-1)*width_array_len
        index = (y*width)*3
        image.pixel_data[index..index+width*3] = data[offset..offset+width*3]
      end

      image

    end
  end

  class BmpEncoder < ImageRuby::Encoder

    def encode(image, format, output)
      unless format == :bmp
        raise UnableToEncodeException
      end

      width = image.width
      height = image.height

      totalsize = 56 + width * height * 3

      output << build_bmp_header(totalsize)
      output << build_bmp_dib_header(image)

      output << "\000\000" # for allignment

      padding_size = ( 4 - (width * 3 % 4) ) % 4
      padding =  "\000" * padding_size

      # write pixel data
      height.times do |y|
        index = ((height-y-1)*width)*3
        output << image.pixel_data[index..index+width*3-1]
        output << padding
      end
    end

  private
    def build_bmp_dib_header(image)
      data = String.new

      data << [40].pack("L") #size of header
      data << [image.width].pack("L")
      data << [image.height].pack("L")
      data << [1].pack("S") # nplanes
      data << [0x18].pack("L")  # depth
      data << [0].pack("S") # compress type
      data << [image.width*image.height*3].pack("S") # raw bitmap data size

      data << [0].pack("L") # hres
      data << [0].pack("L") # vres
      data << [0].pack("L") # ncolors
      data << [0].pack("L") # nimpcolors

      data
    end
    def build_bmp_header(totalsize)

      data = String.new

      data << "BM" # magic
      data << [totalsize].pack("L") # totalsize
      data << [0].pack("S") # creator1
      data << [0].pack("S") # creator2
      data << [54].pack("L") # offset

      data

    end
  end

end