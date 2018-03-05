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
require_relative 'project.rb'

module Jump
  extend WidgetLinkArray
  link "x", 0, :to_float, :to_integer
  link "y", 1, :to_float, :to_integer
end

module Wait
  extend WidgetLinkArray
  link "frames", 0, :to_float, :to_integer
end

module Switch
  extend WidgetLinkArray
  link "switch", 0, :minus_one, :plus_one
end

module ChangeSpeed
  extend WidgetLinkArray
  link "speed", 0, :minus_one, :plus_one
end

module ChangeFrequency
  extend WidgetLinkArray
  link "frequency", 0, :minus_one, :plus_one
end

class DialogSwitchChooser < DialogEditorTemplate
  def initialize(*args)
    super
    fill_with_switches(@builder.get_object("switches"))
    widget = @builder.get_object("switch")
  end
end

class MoveRouteEditor < DialogEditorTemplate
  def initialize(parent, route, targets = [])
    @route = route
    super(@route, "move_route", "title", parent)
    @tv = @builder.get_object("moves")
    @list = @builder.get_object("moves_list")
    for command in @route.list
      widget_insert_row(command)
    end
  end
  def extract
    route = super()
    route.list = @route.list
    route
  end
  def on_key_press(widget, event)
    case event.keyval
    when Gdk::Keyval::KEY_Delete
      delete_row(cursor_path) if cursor_path
    when Gdk::Keyval::KEY_space
      edit_row(cursor_path) if cursor_path
    end
  end
  def edit_row(path)
    index = path.indices[0]
    command = @route.list[index]
    editor, builder_file, title, linker = @@menus[command.code]
    if editor
      dialog = editor.new(command.parameters, builder_file, title, self, linker)
      command.parameters = dialog.edit
      @list.get_iter(path).set_value(0, command.to_s)
    end
  end
  def delete_row(path)
    index = path.indices[0]
    # no-ops can't be removed
    unless @route.list[index].no_op?
      @route.list.delete_at(path.indices[0])
      @list.remove(@list.get_iter(path))
      @tv.set_cursor(path, nil, false)
    end
  end
  def insert_row(command, index)
    @route.list.insert(index, command)
    widget_insert_row(command, index)
  end
  def widget_insert_row(command, index = nil)
    item = index ? @list.insert(index) : @list.append
    item.set_value(0, command.to_s)
  end
  def cursor_path
    @tv.cursor[0]
  end
  def cursor_index
    cursor_path.indices[0] if cursor_path
  end
  def self.define_menuless(name, code)
    define_method name do
      command = RPG::MoveCommand.new(code)
      insert_row(command, cursor_index) if cursor_path
    end
  end
  @@menus = {}
  def self.define_menu(name, code, linker, builder_file, title, editor = DialogEditorTemplate)
    @@menus[code] = [editor, builder_file, title, linker]
    define_method name do
      dialog = editor.new([], builder_file, title, self, linker)
      result = dialog.edit
      # empty means that "original" was returned (it was canceled)
      unless result.empty?
        command = RPG::MoveCommand.new(code, result)
        insert_row(command, cursor_index)
      end
    end
  end
  define_menuless :on_move_down, RPG::MoveCommand::MoveDown
  define_menuless :on_move_left, RPG::MoveCommand::MoveLeft
  define_menuless :on_move_right, RPG::MoveCommand::MoveRight
  define_menuless :on_move_up, RPG::MoveCommand::MoveUp
  define_menuless :on_move_lower_right, RPG::MoveCommand::MoveLowerRight
  define_menuless :on_move_lower_left, RPG::MoveCommand::MoveLowerLeft
  define_menuless :on_move_upper_right, RPG::MoveCommand::MoveUpperRight
  define_menuless :on_move_upper_left, RPG::MoveCommand::MoveUpperLeft
  define_menuless :on_move_random, RPG::MoveCommand::MoveRandom
  define_menuless :on_move_toward_player, RPG::MoveCommand::MoveTowardPlayer
  define_menuless :on_move_away_from_player, RPG::MoveCommand::MoveAwayFromPlayer
  define_menuless :on_step_forward, RPG::MoveCommand::StepForward
  define_menuless :on_step_backward, RPG::MoveCommand::StepBackward
  define_menuless :on_turn_down, RPG::MoveCommand::TurnDown
  define_menuless :on_turn_left, RPG::MoveCommand::TurnLeft
  define_menuless :on_turn_right, RPG::MoveCommand::TurnRight
  define_menuless :on_turn_up, RPG::MoveCommand::TurnUp
  define_menuless :on_turn_90_right, RPG::MoveCommand::Turn90Right
  define_menuless :on_turn_90_left, RPG::MoveCommand::Turn90Left
  define_menuless :on_turn_180, RPG::MoveCommand::Turn180
  define_menuless :on_turn_90_right_or_left, RPG::MoveCommand::Turn90RightOrLeft
  define_menuless :on_turn_random, RPG::MoveCommand::TurnRandom
  define_menuless :on_turn_toward_player, RPG::MoveCommand::TurnTowardPlayer
  define_menuless :on_turn_away_from_player, RPG::MoveCommand::TurnAwayFromPlayer
  define_menuless :on_move_animation_on, RPG::MoveCommand::MoveAnimationON
  define_menuless :on_move_animation_off, RPG::MoveCommand::MoveAnimationOFF
  define_menuless :on_stop_animation_on, RPG::MoveCommand::StopAnimationON
  define_menuless :on_stop_animation_off, RPG::MoveCommand::StopAnimationOFF
  define_menuless :on_direction_fix_on, RPG::MoveCommand::DirectionFixON
  define_menuless :on_direction_fix_off, RPG::MoveCommand::DirectionFixOFF
  define_menuless :on_through_on, RPG::MoveCommand::ThroughON
  define_menuless :on_through_off, RPG::MoveCommand::ThroughOFF
  define_menuless :on_always_on_top_on, RPG::MoveCommand::AlwaysOnTopON
  define_menuless :on_always_on_top_off, RPG::MoveCommand::AlwaysOnTopOFF
  define_menu :on_jump, RPG::MoveCommand::Jump, Jump, "jump", "Jump"
  define_menu :on_wait, RPG::MoveCommand::Wait, Wait, "wait", "Wait"
  define_menu :on_switch_on, RPG::MoveCommand::SwitchON, Switch, "switch", "Switch ON", DialogSwitchChooser
  define_menu :on_switch_off, RPG::MoveCommand::SwitchOFF, Switch, "switch", "Switch OFF", DialogSwitchChooser
  define_menu :on_change_speed, RPG::MoveCommand::ChangeSpeed, ChangeSpeed, "change_speed", "Change Speed"
  define_menu :on_change_frequency, RPG::MoveCommand::ChangeFrequency, ChangeFrequency, "change_frequency", "Change Frequency"
  #define_menu :on_change_graphic, RPG::MoveCommand::ChangeGraphic, ChangeGraphic, "graphic", "Change Graphic"

  def self.define_empty(name)
    define_method name do
    end
  end
  def self.define_empties(*names)
    for name in names
      self.define_empty name
    end
  end
  define_empties :on_change_graphic, :on_change_opacity, :on_change_blending,
                 :on_play_se, :on_script
end
