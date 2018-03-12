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
require 'zlib'
require 'scanf'
require_relative 'widget_link.rb'
require_relative 'convert.rb'
require_relative 'xproj.rb'

# FIXME move somewhere else
TILE_SIZE = 32
FIRST_TILE = 384
AUTOTILE_STRIDE = 48
TILESET_WIDTH = 8
TS, FT, AS, TW = TILE_SIZE, FIRST_TILE, AUTOTILE_STRIDE, TILESET_WIDTH

class Project
  attr_accessor :actors, :animations, :armors, :classes, :common_events,
                :enemies, :items, :mapinfos, :scripts, :skills, :states,
                :system, :tilesets, :troops, :weapons, :maps
  attr_reader :dir, :config
  def initialize(file)
    @dir = File.dirname(file)
    case File.extname(file)
    when ".xproj"
      @config = read_marshal(file)
    when ".rxproj"
      @config = XProj.new
      name = File.basename(file, ".rxproj")
      @config.load_ini(File.expand_path("#{name}.ini", dir))
    else
      raise("Invalid Project extension")
    end
    data = "#{dir}/Data"
    @actors = read_marshal("#{data}/Actors.rxdata")
    @animations = read_marshal("#{data}/Animations.rxdata")
    @armors = read_marshal("#{data}/Armors.rxdata")
    @classes = read_marshal("#{data}/Classes.rxdata")
    @common_events = read_marshal("#{data}/CommonEvents.rxdata")
    @enemies = read_marshal("#{data}/Enemies.rxdata")
    @items = read_marshal("#{data}/Items.rxdata")
    @mapinfos = read_marshal("#{data}/MapInfos.rxdata")
    @scripts = read_marshal("#{data}/Scripts.rxdata")
    @skills = read_marshal("#{data}/Skills.rxdata")
    @states = read_marshal("#{data}/States.rxdata")
    @system = read_marshal("#{data}/System.rxdata")
    @tilesets = read_marshal("#{data}/Tilesets.rxdata")
    @troops = read_marshal("#{data}/Troops.rxdata")
    @weapons = read_marshal("#{data}/Weapons.rxdata")
    @maps = {}
    @mapinfos.each do |map_id, info|
      @maps[map_id] = read_marshal(sprintf("#{data}/Map%03d.rxdata", map_id))
    end
    try_export_scripts
  end
  def save
    # load script files into memory, then save it as .rxdata
    import_scripts
    data = "#{dir}/Data"
    write_marshal(@actors, "#{data}/Actors.rxdata")
    write_marshal(@animations, "#{data}/Animations.rxdata")
    write_marshal(@armors, "#{data}/Armors.rxdata")
    write_marshal(@classes, "#{data}/Classes.rxdata")
    write_marshal(@common_events, "#{data}/CommonEvents.rxdata")
    write_marshal(@enemies, "#{data}/Enemies.rxdata")
    write_marshal(@items, "#{data}/Items.rxdata")
    write_marshal(@mapinfos, "#{data}/MapInfos.rxdata")
    write_marshal(@scripts, "#{data}/Scripts.rxdata")
    write_marshal(@skills, "#{data}/Skills.rxdata")
    write_marshal(@states, "#{data}/States.rxdata")
    write_marshal(@system, "#{data}/System.rxdata")
    write_marshal(@tilesets, "#{data}/Tilesets.rxdata")
    write_marshal(@troops, "#{data}/Troops.rxdata")
    write_marshal(@weapons, "#{data}/Weapons.rxdata")
    # save those in mapinfos
    @mapinfos.each do |map_id, info|
      write_marshal(@maps[map_id], sprintf("#{data}/Map%03d.rxdata", map_id))
    end
    # save metadata
    @config.save(dir)
    @config.export_ini(dir)
    @config.export_conf(dir)
  end
  def try_export_scripts
    export_scripts unless has_scripts?
  end
  def export_scripts
    if has_scripts?
      # clear directory before writing fresh files
      # this is a forced export
      for script in ruby_scripts
        File.delete(script)
      end
    else
      Dir.mkdir(scripts_dir)
    end
    for i in 0...@scripts.length
      script = @scripts[i]
      # checker seems not to be a checksum nor a timestamp,
      # ignoring it may be safe
      checker, name, zlib = script
      code = Zlib::Inflate.inflate(zlib)
      file = File.open(sprintf("%s/%03d-%s.rb", scripts_dir, i+1, name), "wb")
      file.write(code)
      file.close
    end
  end
  def import_scripts
    checker = 0
    empty_zlib = Zlib::Deflate.deflate("")
    
    files = ruby_scripts
    max_id, name = extract_script_path(files.sort.last)
    scripts = Array.new(max_id, [checker, "", empty_zlib])

    for path in files
      id, name = extract_script_path(path)
      code = IO.read(path)
      scripts[id-1] = [checker, name, Zlib::Deflate.deflate(code)]
    end

    @scripts = scripts
  end
  def has_scripts?
    File.exists?(scripts_dir)
  end
  def ruby_scripts
    Dir["#{scripts_dir}/*.rb"]
  end
  def extract_script_path(path)
    filename = File.basename(path.split("/").last, ".rb")
    id = filename.to_i
    id_len = [3, id.to_s.length].max
    name = filename[id_len+1..-1]
    [id, name]
  end
  def scripts_dir
    "#{dir}/Scripts"
  end
end

module RPG
  class Actor
    attr_accessor :name
  end
  class Animation
    class Frame
    end
    class Timing
    end
  end
  class Armor
    attr_accessor :name
  end
  class AudioFile
    attr_accessor :name
    extend WidgetLinkObject
    alink "volume", :to_float, :to_integer
    alink "pitch", :to_float, :to_integer
  end
  class Class
    class Learning
    end
  end
  class CommonEvent
    attr_accessor :name, :list, :parameters, :indent, :code
  end
  class Enemy
    class Action
    end
  end
  class Event
    attr_accessor :pages, :x, :y
    extend WidgetLinkObject
    alink "name"
    class Page
      attr_accessor :condition, :move_route, :graphic, :list
      extend WidgetLinkObject
      alink "move_type"
      alink "move_speed", :minus_one, :plus_one
      alink "move_frequency", :minus_one, :plus_one
      alink "walk_anime"
      alink "step_anime"
      alink "direction_fix"
      alink "through"
      alink "always_on_top"
      alink ["action_button", "player_touch", "event_touch", "autorun", "parallel_process"], :trigger
      Fixed = 0
      Random = 1
      Approach = 2
      Custom = 3
      class Condition
        extend WidgetLinkObject
        alink "switch1_valid"
        alink "switch1_id", :minus_one, :plus_one
        alink "switch2_valid"
        alink "switch2_id", :minus_one, :plus_one
        alink "variable_valid"
        alink "variable_id", :minus_one, :plus_one
        alink "variable_value", :to_float, :to_integer
        alink "self_switch_valid"
        alink "self_switch_ch", :self_switch_to_character, :character_to_self_switch
      end
      class Graphic
        extend WidgetLinkObject
        alink "hue", :character_hue, :to_float, :to_integer
        alink "opacity", :to_float, :to_integer
        alink "blending", :blend_type
        attr_accessor :character_name, :pattern, :tile_id, :direction
      end
    end
  end
  class EventCommand
    attr_accessor :name, :parameters
  end
  class Item
    attr_accessor :name
  end
  class Map
    attr_accessor :width, :height, :events, :tileset_id, :data, :bgm, :bgs,
                  :autoplay_bgm, :autoplay_bgs, :encounter_step, :encounter_list
  end
  class MapInfo
    attr_accessor :scroll_x, :name, :expanded, :order, :scroll_y, :parent_id
  end
  class MoveCommand
    attr_accessor :code, :parameters
    NoOp = 0
    MoveDown = 1
    MoveLeft = 2
    MoveRight = 3
    MoveUp = 4
    MoveLowerLeft = 5
    MoveLowerRight = 6
    MoveUpperLeft = 7
    MoveUpperRight = 8
    MoveRandom = 9
    MoveTowardPlayer = 10
    MoveAwayFromPlayer = 11
    StepForward = 12
    StepBackward = 13
    Jump = 14
    Wait = 15
    TurnDown = 16
    TurnLeft = 17
    TurnRight = 18
    TurnUp = 19
    Turn90Right = 20
    Turn90Left = 21
    Turn180 = 22
    Turn90RightOrLeft = 23
    TurnRandom = 24
    TurnTowardPlayer = 25
    TurnAwayFromPlayer = 26
    SwitchON = 27
    SwitchOFF = 28
    ChangeSpeed = 29
    ChangeFrequency = 30
    MoveAnimationON = 31
    MoveAnimationOFF = 32
    StopAnimationON = 33
    StopAnimationOFF = 34
    DirectionFixON = 35
    DirectionFixOFF = 36
    ThroughON = 37
    ThroughOFF = 38
    AlwaysOnTopON = 39
    AlwaysOnTopOFF = 40
    ChangeGraphic = 41
    ChangeOpacity = 42
    ChangeBlending = 43
    PlaySE = 44
    Script = 45
    Names = ["", "Move Down", "Move Left", "Move Right", "Move Up",
             "Move Lower Left", "Move Lower Right", "Move Upper Left",
             "Move Upper Right", "Move Random", "Move toward Player",
             "Move away from Player", "Step Forward", "Step Backward",
             "Jump", "Wait", "Turn Down", "Turn Left", "Turn Right", "Turn Up",
             "Turn 90° Right", "Turn 90° Left", "Turn 180°",
             "Turn 90° Right or Left", "Turn Random", "Turn toward Player",
             "Turn away from Player", "Switch ON", "Switch OFF", "Change Speed",
             "Change Frequency", "Move Animation ON", "Move Animation OFF",
             "Stop Animation ON", "Stop Animation OFF", "Direction Fix ON",
             "Direction Fix OFF", "Through ON", "Through OFF",
             "Always on Top ON", "Always on Top OFF", "Change Graphic",
             "Change Opacity", "Change Blending", "Play SE", "Script"]
    def initialize(code = NoOp, parameters = [])
      @code = code
      @parameters = parameters
    end
    def to_s
      if @parameters.empty?
        "$>#{name}"
      else
        str = "$>#{name}: "
        for i in 0...@parameters.length-1
          str += "#{@parameters[i]}, "
        end
        str += @parameters.last.to_s
        str
      end
    end
    def name
      Names[@code]
    end
    def no_op?
      NoOp == @code
    end
  end
  class MoveRoute
    attr_accessor :list
    extend WidgetLinkObject
    alink "repeat"
    alink "skippable"
  end
  class Skill
    attr_accessor :name
  end
  class State
    attr_accessor :name
  end
  class System
    attr_accessor :variables, :switches, :edit_map_id,
                  :start_map_id, :start_x, :start_y
    class TestBattler
    end
    class Words
    end
  end
  class Tileset
    attr_accessor :tileset_name, :autotile_names, :name
  end
  class Troop
    attr_accessor :name
    class Member
    end
    class Page
      class Condition
      end
    end
  end
  class Weapon
    attr_accessor :name
  end
end

class Color
  attr_accessor :r, :g, :b, :a
  def _dump(level)
    [@r, @g, @b, @a].pack('EEEE')
  end
  def self._load(args)
    color = new
    color.r, color.g, color.b, color.a = args.unpack('EEEE')
    color
  end
end

class Tone
  attr_accessor :red, :green, :blue, :gray
  def _dump(level)
    [@red, @green, @blue, @gray].pack('EEEE')
  end
  def self._load(args)
    tone = new
    tone.red, tone.green, tone.blue, tone.gray = args.unpack('EEEE')
    tone
  end
end

class Table
  attr_accessor :dims, :width, :height, :depth, :size, :data
  def initialize(width, height = 1, depth = 1, dims = nil)
    @dims = if dims; dims
            elsif depth > 1; 3
            elsif height > 1; 2
            else; 1
            end
    @width = width
    @height = height
    @depth = depth
    @size = @width * @height * @depth
    @data = (0...@size).map { 0 }
  end
  def resize(width, height = nil, depth = nil)
    height = @height unless height
    depth = @depth unless depth
    size = width * height * depth
    data = (0...size).map { 0 }
    for z in 0...[depth, @depth].min
      for y in 0...[height, @height].min
        for x in 0...[width, @width].min
          index = z*width*height + y*width + x
          data[index] = self[x,y,z]
        end
      end
    end
    @width = width
    @height = height
    @depth = depth
    @size = size
    @data = data
  end
  def [](x, y = 0, z = 0)
    x = x % width
    y = y % height
    z = z % depth
    @data[index(x,y,z)]
  end
  def []=(x, y, z, value)
    @data[index(x,y,z)] = value
  end
  def set_tile(dest_x, dest_y, layer, new_tile)
    self[dest_x, dest_y, layer] = new_tile
    surroundings(dest_x, dest_y, true, false) do |x, y|
      tile = self[x, y, layer]
      id = autotile_id(tile)
      if autotile?(tile)
        state = []
        surroundings(x, y, false, true) do |near_x, near_y|
          state.push(!in?(near_x, near_y) ||
                     id == autotile_id(self[near_x, near_y, layer]))
        end
        self[x, y, layer] = AS*(id+1) + AutotileDeps.index(state)
      end
    end
  end
  def surroundings(x, y, center, include_all)
    for ox, oy in [[-1, -1], [0, -1], [1, -1],
                   [-1,  0],          [1,  0],
                   [-1,  1], [0,  1], [1,  1]]
      ix = x+ox
      iy = y+oy
      yield(ix, iy) if include_all || in?(ix, iy)
    end
    yield(x, y) if center
  end
  def index(x, y = 0, z = 0)
    z*@width*@height + y*@width + x
  end
  def in?(x, y = 0, z = 0)
    x >= 0 && x < @width &&
      y >= 0 && y < @height &&
      z >= 0 && z < @depth
  end
  def _dump(level)
    header = [@dims, @width, @height, @depth, @size].pack('L<5')
    data = @data.pack('S<*')
    header + data
  end
  def self._load(args)
    table = allocate
    table.dims, table.width, table.height, table.depth, table.size = args.unpack('L<5')
    table.data = args.unpack('@20S<*')
    table
  end
end

def read_marshal(path)
  Marshal.load(IO.read(path))
end

def write_marshal(object, path)
  file = File.open(path, "wb")
  file.write(Marshal.dump(object))
  file.close
end
