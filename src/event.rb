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
require_relative 'project.rb'

class RPG::Event
  def initialize(id, x, y)
    @name = sprintf("EV%03d", id)
    @x = x
    @y = y
    @pages = [RPG::Event::Page.new]
  end
end

class RPG::Event::Page
  def initialize
    @condition = RPG::Event::Page::Condition.new
    @move_route = RPG::MoveRoute.new
    @graphic = RPG::Event::Page::Graphic.new
    @list = [RPG::EventCommand.new]
    @move_type = 0
    @move_speed = 4
    @move_frequency = 3
    @walk_anime = true
    @step_anime = false
    @direction_fix = false
    @through = false
    @always_on_top = false
    @trigger = 0
  end
end

class RPG::Event::Page::Condition
  def initialize
    @switch1_valid = false
    @switch1_id = 1
    @switch2_valid = false
    @switch2_id = 1
    @variable_valid = false
    @variable_id = 1
    @variable_value = 0
    @self_switch_valid = false
    @self_switch_ch = "A"
  end
end

class RPG::Event::Page::Graphic
  def initialize
    @character_hue = 0
    @opacity = 255
    @blend_type = 0
    @character_name = ""
    @pattern = 0
    @tile_id = 0
    @direction = 2
  end
end

# FIXME: move somewhere else
class RPG::MoveRoute
  def initialize
    @list = [RPG::MoveCommand.new]
    @repeat = true
    @skippable = false
  end
end

