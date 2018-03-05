#
# This file is part of RPGXP.
#
# RPGXP is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published
# by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# RPGXP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with RPGXP.  If not, see <http://www.gnu.org/licenses/>.
#
def clamp(n, floor, roof)
  if floor && n <= floor
    floor
  elsif roof && n >= roof
    roof
  else
    n
  end
end

class Rectangle
  attr_reader :x1, :y1, :x2, :y2,
              :min_x, :min_y, :max_x, :max_y,
              :width, :height
  def initialize(x1, y1, x2, y2,
                 max_width = nil, max_height = nil, raw = true)
    @x1, @y1, @x2, @y2 = [x1, y1, x2, y2].map { |n| raw ? n.to_i / TS : n.to_i }
    @x1 = clamp(@x1, 0, max_width)
    @x2 = clamp(@x2, 0, max_width)
    @y1 = clamp(@y1, 0, max_height)
    @y2 = clamp(@y2, 0, max_height)
    @min_x = [@x1, @x2].min
    @min_y = [@y1, @y2].min
    @max_x = [@x1, @x2].max
    @max_y = [@y1, @y2].max
    @width = max_x - min_x + 1
    @height = max_y - min_y + 1
  end
  def queue_draw(widget)
    widget.queue_draw_area(@min_x*TS, @min_y*TS, @width*TS, @height*TS)
  end
end

class Selection
  attr_reader :data, :origin_x, :origin_y
  def initialize(data, start_x, start_y,
                 origin_x = 0, origin_y = 0, source = nil)
    @data = data
    @start_x = start_x
    @start_y = start_y
    @origin_x = origin_x
    @origin_y = origin_y
    @source = source
  end
  def paste_to_map(map, pos_x, pos_y, offset_x, offset_y, layer, raw = false)
    ox = pos_x - offset_x
    oy = pos_y - offset_y
    for y in 0...height
      iy = pos_y + y - @origin_y
      next if iy < 0 || iy >= map.height
      for x in 0...width
        ix = pos_x + x - @origin_x
        next if ix < 0 || ix >= map.width
        tile = @data[x+ox, y+oy, 0]
        if raw
          map.data[ix, iy, layer] = tile
        else
          map.data.set_tile(ix, iy, layer, tile)
        end
      end
    end
  end
  def self.empty
    table = Table.new(1, 1, 1, 2)
    table[0,0,0] = 0
    new(table, 0, 0)
  end
  def self.map(map, r, layer)
    table = Table.new(r.width, r.height, 1, 2)
    for y in 0...r.height
      for x in 0...r.width
        table[x, y, 0] = map.data[r.min_x + x, r.min_y + y, layer]
      end
    end
    origin_x = r.x2 - r.min_x
    origin_y = r.y2 - r.min_y
    new(table, r.min_x, r.min_y, origin_x, origin_y, map)
  end
  def self.tileset(tileset, r)
    table = Table.new(r.width, r.height, 1, 2)
    for y in 0...r.height
      for x in 0...r.width
        tile_x = r.min_x + x
        tile_y = r.min_y + y
        table[x, y, 0] = if 0 == tile_y
                           tile_x * AS
                         else
                           FT + tile_x + (tile_y - 1)*TW
                         end
      end
    end
    new(table, r.min_x, r.min_y, 0, 0, tileset)
  end
  def source?(source)
    @source == source
  end
  def width
    @data.width
  end
  def height
    @data.height
  end
  def draw(cr, x = 0, y = 0)
    cr.draw_selection(TS, TS, x - @origin_x, y - @origin_y, width, height)
  end
  def queue_draw(widget, x, y, extra_x = 0, extra_y = 0)
    widget.queue_draw_area((x-@origin_x) * TS, (y-@origin_y) * TS,
                           (width+extra_x) * TS, (height+extra_y) * TS)
  end
end
