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
require_relative 'widget_link.rb'
require_relative 'project.rb'

# FIXME move somewhere else
class RPG::AudioFile
  def initialize
    @name = ""
    @volume = 80
    @pitch = 100
  end
end

class RPG::MapInfo
  def initialize(name, parent_id)
    @name = name
    @parent_id = parent_id
    @expanded = true
    @order = 1.0 / 0.0 # infinity, to sort
    @scroll_x = 0
    @scroll_y = 0
  end
end

class RPG::Map
  def initialize
    @bgm = RPG::AudioFile.new
    @bgs = RPG::AudioFile.new
    @events = {}
    @tileset_id = 1
    @autoplay_bgs = false
    @autoplay_bgm = false
    @width = 20
    @height = 15
    @encounter_step = 30
    @encounter_list = []
    @name = "" # unused
    @data = Table.new(@width, @height, 3)
    for y in 0...@height
      for x in 0...@width
        @data[x,y,0] = FT
      end
    end
  end
  def self.new_id
    i = 1
    while $project.mapinfos.include?(i)
      i += 1
    end
    i
  end
  def new_event_id
    i = 1
    while @events.include?(i)
      i += 1
    end
    i
  end
end

class MapProperties
  extend WidgetLinkObject
  alink "name"
  alink "autoplay_bgm"
  alink "autoplay_bgs"
  alink "tileset_id", :minus_one, :plus_one
  alink "width"
  alink "height"
  alink "encounter_step", :to_float, :to_integer
  attr_accessor :bgm, :bgs, :encounter_list
  def initialize(map_id)
    map = $project.maps[map_id]
    info = $project.mapinfos[map_id]
    @name = info.name
    @bgm = map.bgm.deep_clone
    @tileset_id = map.tileset_id
    @bgs = map.bgs.deep_clone
    @autoplay_bgm = map.autoplay_bgm
    @autoplay_bgs = map.autoplay_bgs
    @height = map.height
    @encounter_step = map.encounter_step
    @width = map.width
    @encounter_list = map.encounter_list.clone
  end
  def set_to_map(map_id)
    map = $project.maps[map_id]
    info = $project.mapinfos[map_id]
    info.name = @name
    map.bgm = @bgm.deep_clone
    map.tileset_id = @tileset_id
    map.bgs = @bgs.deep_clone
    map.autoplay_bgm = @autoplay_bgm
    map.autoplay_bgs = @autoplay_bgs
    map.height = @height
    map.encounter_step = @encounter_step
    map.width = @width
    map.encounter_list = @encounter_list.clone
    map.data.resize(width, height)
  end
end
