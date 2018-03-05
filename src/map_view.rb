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
require 'gtk3'
require_relative 'resource.rb'
require_relative 'autotile.rb'
require_relative 'convert.rb'
require_relative 'widgets.rb'

class MapView < Gtk::DrawingArea
  attr_accessor :draw_all, :dim, :active_layer, :draw_lines
  def initialize(viewport)
    super()
    self.signal_connect("draw") do |widget, cr|
      on_draw(cr) if @map_id
      cr.destroy
    end
    viewport.add(self)
  end
  def map_id=(map_id)
    @map_id = map_id
    @map = $project.maps[map_id] || raise("Invalid map #{map_id}")
    @draw_all = true
    @dim = false
    @active_layer = 0
    @highlight_events = false
    self.width_request = @map.width * TS
    self.height_request = @map.height * TS
    self.queue_draw
  end
  def on_draw(cr)
    cr.set_source_rgb(0.5, 0.5, 0.5)
    cr.paint
    cr.rectangle(0.0, 0.0, width.to_f, height.to_f)
    cr.clip
    cr.set_source_rgb(1.0, 1.0, 1.0)
    cr.paint
    raw_x1, raw_y1, raw_x2, raw_y2 = cr.clip_extents.map { |n| n.to_i }
    x1 = raw_x1 / TS
    y1 = raw_y1 / TS
    x2 = [@map.width, (raw_x2 / TS) + 1].min
    y2 = [@map.height, (raw_y2 / TS) + 1].min
    3.times do |layer|
      if draw_all || layer <= active_layer
        if dim && (layer > active_layer || layer+1 == active_layer)
          cr.push_group
        end
        draw_layer(cr, layer, x1, y1, x2, y2)
        if dim
          if layer+1 == active_layer
            cr.set_source_rgba(0.0, 0.0, 0.0, 0.5)
            cr.paint
            cr.pop_group_to_source
            cr.paint
          elsif layer > active_layer
            cr.pop_group_to_source
            cr.paint(0.3)
          end
        end
      end
    end
    cr.set_antialias(Cairo::ANTIALIAS_NONE)
    if draw_lines
      cr.line_width = 2
      cr.set_source_rgba(0.0, 0.0, 0.0, 0.3)
      for x in x1...x2
        cr.move_to(x*TS, y1*TS)
        cr.line_to(x*TS, y2*TS)
      end
      for y in y1...y2
        cr.move_to(x1*TS, y*TS)
        cr.line_to(x2*TS, y*TS)
      end
      cr.stroke
    end
    
    # draw events
    unless highlight_events
      cr.push_group
    end
    cr.line_width = 1
    for id, event in @map.events
      if event.x < x1 || event.x > x2 || event.y < y1 || event.y > y2
        next
      end
      draw_event(cr, event)
    end
    # draw starting tile
    system = $project.system
    if system.start_map_id == @map_id
      with_event_square(cr, system.start_x*TS, system.start_y*TS) do
        cr.set_source_rgb(1.0, 1.0, 1.0)
        cr.font_size = TS * (2.0 / 3.0)
        cr.move_to((system.start_x + 0.27) * TS,
                   (system.start_y + 0.75) * TS)
        cr.show_text("S")
      end
    end
    unless highlight_events
      cr.pop_group_to_source
      cr.paint(0.4)
    end
  end
  def draw_event(cr, event)
    # always render the first page
    page = event.pages[0]
    dest_x = event.x*TS
    dest_y = event.y*TS
    with_event_square(cr, dest_x, dest_y) do
      unless page.graphic.character_name.empty?
        surface = Resource.load(:character, page.graphic.character_name)
        width, height = surface.width.to_i, surface.height.to_i
        src_x = page.graphic.pattern * width / 4
        src_y = direction_to_offset(page.graphic.direction) * height / 4
        cr.set_source(surface, dest_x - src_x, dest_y - src_y)
        cr.rectangle(dest_x+5, dest_y+5, TS-10, TS-10)
        cr.fill
      end
    end
  end
  def with_event_square(cr, dest_x, dest_y)
    # mac has a weird none-antialias, tested to work on high sierra
    square_offset_x = OS.mac? ? 4 : 5

    cr.set_source_rgba(1.0, 1.0, 1.0, 0.25)
    cr.rectangle(dest_x+square_offset_x, dest_y+5, TS-9, TS-9)
    cr.fill

    yield
    
    cr.set_source_rgb(1.0, 1.0, 1.0)
    cr.rectangle(dest_x+square_offset_x, dest_y+5, TS-9, TS-9)
    cr.stroke
  end
  def draw_layer(cr, layer, x1, y1, x2, y2)
    cr.set_source(Resource.load(:tileset, tileset.tileset_name), 0.0, 0.0)
    pattern = cr.source
    for y in y1...y2
      for x in x1...x2
        tile = @map.data[x, y, layer]
        if tile >= FT
          tile -= FT
          blit_normal_tile(cr, pattern, x, y, tile % TW, tile / TW)
        end
      end
    end
    8.times do |i|
      autotile = tileset.autotile_names[i]
      if autotile.nil? || autotile.empty?
        next
      end
      cr.set_source(Resource.load(:autotile, autotile), 0.0, 0.0)
      pattern = cr.source
      for y in y1...y2
        for x in x1...x2
          tile = @map.data[x, y, layer]
          if tile != 0 && tile < FT && i == tile / AS - 1
            blit_autotile(cr, pattern, x, y, AUTOTILE_COORDINATES[tile % AS])
          end
        end
      end
    end
  end
  def blit_normal_tile(cr, pattern, dest_x, dest_y, src_x, src_y)
    blit(cr, pattern, dest_x*TS, dest_y*TS, src_x*TS, src_y*TS, TS, TS)
  end
  def blit_autotile(cr, pattern, x, y, coords)
    c = coords
    fill_1_4(cr, pattern, x, y, 0, 0, c.top_left_x, c.top_left_y)
    fill_1_4(cr, pattern, x, y, TS/2, 0, c.top_right_x, c.top_right_y)
    fill_1_4(cr, pattern, x, y, 0, TS/2, c.bot_left_x, c.bot_left_y)
    fill_1_4(cr, pattern, x, y, TS/2, TS/2, c.bot_right_x, c.bot_right_y)
  end
  def fill_1_4(cr, pattern, x, y, offset_x, offset_y, src_x, src_y)
    blit(cr, pattern, x*TS + offset_x, y*TS + offset_y,
         src_x, src_y, TS/2, TS/2)
  end
  def blit(cr, pattern, dest_x, dest_y, src_x, src_y, width, height)
    matrix = Cairo::Matrix.new(1.0, 0.0, 0.0, 1.0, src_x-dest_x, src_y-dest_y)
    pattern.matrix = matrix
    cr.rectangle(dest_x, dest_y, width, height)
    cr.fill
  end
  def tileset
    id = @map.tileset_id
    $project.tilesets[id]
  end
  def width
    @map.width * TS
  end
  def height
    @map.height * TS
  end
end
