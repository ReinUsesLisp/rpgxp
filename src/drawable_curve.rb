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

class DrawableCurve < Gtk::DrawingArea
  def initialize(max)
    super()
    @max = max.to_f
    @color = [0.0, 0.0, 0.0]
    
    self.signal_connect("draw") do |w, cr|
      on_draw(cr)
      cr.destroy
    end
  end
  def on_draw(cr)
    cr.set_source_rgb(*@color)
    height = self.allocated_height
    dx = self.allocated_width / length.to_f

    for index in 0...length
      y = (self[index] * height) / @max
      x = dx * index
      cr.rectangle(x, height-y, dx, y)
    end
    cr.fill
  end
  def max=(max)
    @max = max
    self.queue_draw
  end
  def color=(color)
    @color = color
    self.queue_draw
  end
end

class ListCurve < DrawableCurve
  def initialize(max)
    super
    @list = []
  end
  def on_draw(cr)
    super unless @list.empty?
  end
  def list=(list)
    @list = list
    self.queue_draw
  end
  def length
    @list.length
  end
  def [](index)
    @list[index]
  end
end

class ParameterCurve < DrawableCurve
  def initialize(max, index, r, g, b)
    super(max)
    @index = index
    @parameters = nil
    self.color = [r, g, b]
  end
  def on_draw(cr)
    super if @parameters
  end
  def parameters=(parameters)
    @parameters = parameters
    self.queue_draw
  end
  def length
    99
  end
  def [](level)
    @parameters[@index, level+1]
  end
end
