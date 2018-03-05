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
require_relative 'system.rb'

class RPG::EventCommand
  # default initialize is a no-op
  def initialize(code = 0, parameters = [], indent = 0)
    @code = code
    @parameters = parameters
    @indent = indent
  end
  def set_iter(iter)
    text, color = values
    @indent.times { text = "\t#{text}" }
    iter.set_value(0, text)
    iter.set_value(1, color)
  end
  def values
    case @code
    when 0; ["@>", "black"]
    when 101; show_text
    when 102; show_choices
    when 103; input_number
    when 104; change_text_options
    when 105; button_input
    when 106; wait
    when 108; comment
    when 111; conditional_branch
    when 112; loop_
    when 113; break_loop
    when 115; exit_event_processing
    when 116; erase_event
    when 117; call_common_event
    when 118; label
    when 119; jump_label
    when 121; control_switches
    when 122; control_variables
    when 123; control_self_switch
    when 124; control_timer
    when 125; change_gold
    when 126; change_items
    #when 127; change_weapons
    when 402; when_
    when 403; when_cancel
    when 404; branch_end
    when 411; else_
    when 412; branch_end
    when 413; repeat_above
    else; ["#{@code.to_s}: #{@parameters}", "orange"]
    end
  end
  def show_text
    ["@>Text: #{a}", "black"]
  end
  def show_choices
    choices = a.join(", ")
    ["@>Show Choices: #{choices}", "black"]
  end
  def input_number
    digits = 1 == b ? "digit" : "digits"
    ["@>Input Number: #{variable(a)}, #{b} #{digits}", "black"]
  end
  def change_text_options
    position = ["Top", "Middle", "Bottom"][a]
    window = ["Show", "Hide"][b]
    ["@>Change Text Options: #{position}, #{window}", "black"]
  end
  def button_input
    ["@>Button Input Processing: #{variable(a)}", "black"]
  end
  def wait
    frames = 1 == a ? "frame" : "frames"
    ["@>Wait: #{a} #{frames}", "black"]
  end
  def comment
    ["@>Comment: #{a}", "green"]
  end
  def conditional_branch
    ["@>Conditional Branch: " +
     case a
     when 0 # switch
       status = ["ON", "OFF"][c]
       "Switch #{switch(b)} == #{status}"
     when 1 # variable
       comp = ["==", ">=", "<=", ">", "<", "!="][e]
       "Variable #{variable(b)} #{comp} " +
         if 0 == c # constant
           d.to_s
         else # variable
           "Variable #{variable(d)}"
         end
     when 2 # self switch
       status = ["ON", "OFF"][c]
       "Self Switch #{b} == #{status}"
     when 3 # timer
       comp = ["or more", "or less"][c]
       minutes = b / 60
       seconds = b % 60
       "Timer #{minutes} min #{seconds} sec #{comp}"
     when 4 # actor
       "#{actor(b)} " +
         case c
         when 0
           "is in the party"
         when 1
           "'s name is \"#{d}\""
         when 2
           "has #{skill(d)} learned"
         when 3
           "has #{weapon(d)} equipped"
         when 4
           "has #{armor(d)} equipped"
         when 5
           "is #{state(d)}"
         end
     when 5
       # TODO add support for reading monster's name from current troop
       "Enemy #{b+1} has " +
         if 0 == c
           "appeared"
         else
           "#{state(d)} inflicted"
         end
     when 6
       # TODO read event names from current map
       target = case b
                when -1; "Player"
                when 0; "This Event"
                else; sprintf("%03d", b)
                end
       direction = {2=>"Down", 4=>"Left", 6=>"Right", 8=>"Up"}[c]
       sprintf("%s is facing %s", target, direction)
     when 7
       comp = ["or more", "or less"][c]
       sprintf("Gold %d %s", b, comp)
     when 8
       sprintf("%s is in Inventory", item(b))
     when 9
       sprintf("%s is in Inventory", weapon(b))
     when 10
       sprintf("%s is in Inventory", armor(b))
     when 11
       button = {2=>"Down", 4=>"Left", 6=>"Right", 8=>"Up", 11=>"A", 12=>"B",
                 13=>"C", 14=>"X", 15=>"Y", 16=>"Z", 17=>"L", 18=>"R"}[b]
       sprintf("The %s button is being pressed", button)
     when 12
       sprintf("Script: %s", b)
     end,
     "blue"]
  end
  def loop_
    ["@>Loop", "blue"]
  end
  def break_loop
    ["@>Break Loop", "blue"]
  end
  def exit_event_processing
    ["@>Exit Event Processing", "blue"]
  end
  def erase_event
    ["@>Erase Event", "blue"]
  end
  def call_common_event
    event = $project.common_events[a].name
    ["@>Call Common Event: #{event}", "blue"]
  end
  def label
    ["@>Label: #{a}", "blue"]
  end
  def jump_label
    ["@>Jump to Label: #{a}", "blue"]
  end
  def control_switches
    name = "Control Switches"
    status = ["ON", "OFF"][last]
    color = "red"
    case length
    when 2 # single
      ["@>#{name}: #{switch(a)} = #{status}", color]
    when 3 # batch
      status = ["ON", "OFF"][c]
      [sprintf("@>#{name}: [%04d..%04d] = #{status}", a, b), color]
    end
  end
  def control_variables
    name = "Control Variables"
    batch = a == b ? switch(a) : sprintf("[%04d..%04d]", a, b)
    operation = ["=", "+=", "-=", "*=", "/=", "%="][c]
    color = "red"
    beg = "@>#{name}: #{batch} #{operation}"
    case d
    when 0 # constant
      ["#{beg} #{e}", color]
    when 1 # variable
      ["#{beg} Variable #{variable(e)}", color]
    when 2 # random
      ["#{beg} Random No. (#{e}...#{f})", color]
    when 3 # item
      ["#{beg} #{item(e)} in Inventory", color]
    when 4 # actor
      element = ["Level", "EXP", "HP", "SP", "MaxHP", "MaxSP", "STR", "DEX",
                 "AGI", "INT", "ATK", "PDEF", "MDEF", "EVA"][f]
      ["#{beg} #{actor(e)}'s #{element}", color]
    when 5 # enemy
      element = ["HP", "SP", "MaxHP", "MaxSP", "STR", "DEX", "AGI", "INT",
                 "ATK", "PDEF", "MDEF", "EVA"][f]
      # TODO add support for reading monster's name from current troop
      ["#{beg} [Enemy #{e+1}]'s #{element}", color]
    when 6 # character
      element = ["Map X", "Map Y", "Direction", "Screen X", "Screen Y",
                 "Terrain Tag"][f]
      # TODO read event names from current map
      name = case e
             when -1; "Player"
             when 0; "This Event"
             else; sprintf("Event %03d", e)
             end
      ["#{beg} #{name}'s #{element}", color]
    when 7 # other
      element = ["Map ID", "Party Members", "Gold", "Steps", "Play Time",
                 "Timer", "Save Count"][e]
      ["#{beg} #{element}", color]
    end
  end
  def control_self_switch
    status = ["ON", "OFF"][b]
    ["@>Control Self Switch: #{a} = #{status}", "red"]
  end
  def control_timer
    color = "red"
    case a
    when 0 # start
      minutes, seconds = b / 60, b % 60
      ["@>Control Timer: Startup (#{minutes} min., #{seconds} sec.)", color]
    when 1 # stop
      ["@>Control Timer: Stop", color]
    end
  end
  def change_gold
    operation = ["+", "-"][a]
    name = "Change Gold"
    color = "red"
    if 0 == b
      ["@>#{name}: #{operation} #{c}", color]
    else
      ["@>#{name}: #{operation} Variable #{variable(c)}", color]
    end
  end
  def change_items
    operation = ["+", "-"][b]
    name = "Change Items"
    color = "red"
    ["@>Change Items: #{item(a)} #{operation}" +
     if 0 == c # constant
       d.to_s
     else # variable
       "Variable #{variable(d)}"
     end, "red"]
  end
  def when_
    ["When [#{b}]", "black"]
  end
  def when_cancel
    ["When Cancel", "black"]
  end
  def branch_end
    ["Branch End", "black"]
  end
  def else_
    ["Else", "blue"]
  end
  def branch_end
    ["Branch End", "blue"]
  end
  def repeat_above
    ["Repeat Above", "blue"]
  end
  def variable(id)
    "[#{$project.system.variable_name(id)}]"
  end
  def switch(id)
    "[#{$project.system.switch_name(id)}]"
  end
  def actor(id)
    "[#{$project.actors[id].name}]"
  end
  def item(id)
    "[#{$project.items[id].name}]"
  end
  def skill(id)
    "[#{$project.skills[id].name}]"
  end
  def weapon(id)
    "[#{$project.weapons[id].name}]"
  end
  def armor(id)
    "[#{$project.armors[id].name}]"
  end
  def state(id)
    "[#{$project.states[id].name}]"
  end
  def length
    @parameters.length
  end
  def a
    @parameters[0]
  end
  def b
    @parameters[1]
  end
  def c
    @parameters[2]
  end
  def d
    @parameters[3]
  end
  def e
    @parameters[4]
  end
  def f
    @parameters[5]
  end
  def last
    @parameters.last
  end
end
