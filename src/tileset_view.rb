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
require_relative 'selection.rb'
require_relative 'tileset.rb'

class TilesetView < Gtk::DrawingArea
  def initialize(viewport)
    super()
    viewport.add(self)
    self.signal_connect("draw") do |widget, cr|
      on_draw(cr) if @tileset
      cr.destroy
    end
  end
  def on_draw(cr)
    cr.set_source(@tileset.surface, 0, TS)
    cr.paint
    for x in 1..8
      autotile = @tileset.autotile_names[x-1]
      if autotile && !autotile.empty?
        cr.set_source(Resource.load(:autotile, autotile), x*TS, 0)
        cr.rectangle(x*TS, 0, TS, TS)
        cr.fill
      end
    end
  end
  def tileset=(tileset)
    @tileset = tileset
    self.height_request = tileset.raw_height + TS
    self.queue_draw
  end
end

class Palette < TilesetView
  def initialize(*args)
    super
    self.add_events([:button_press_mask, :button_release_mask, :pointer_motion_mask])
    self.signal_connect("button-press-event") { |w, event| on_button_press(event) }
    self.signal_connect("button-release-event") { |w, event| on_button_release(event) }
    self.signal_connect("motion-notify-event") { |w, event| on_motion(event) }
    @selection_x = @selection_y = 0
  end
  def on_draw(cr)
    super
    if @selecting
      r = rectangle
      cr.draw_selection(TS, TS, r.min_x, r.min_y, r.width, r.height)
    elsif $selection && $selection.source?(@tileset)
      $selection.draw(cr, @selection_x, @selection_y)
    end
  end
  def on_button_press(ev)
    if 1 == ev.button
      @x1 = @x2 = ev.x
      @y1 = @y2 = ev.y
      @selecting = true
      self.queue_draw
    end
  end
  def on_button_release(ev)
    if 1 == ev.button
      r = rectangle
      @selecting = false
      @selection_x = r.min_x
      @selection_y = r.min_y
      $selection = Selection.tileset(@tileset, r)
      self.queue_draw
    end
  end
  def on_motion(ev)
    if @selecting
      if @x2.to_i / TS != ev.x.to_i / TS || @y2.to_i / TS != ev.y.to_i / TS
        @x2 = ev.x
        @y2 = ev.y
        self.queue_draw
      end
    end
  end
  def rectangle
    Rectangle.new(@x1, @y1, @x2, @y2, TW-1, @tileset.height)
  end
end
