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
require_relative 'system.rb'

def define_filler(name, getter = nil)
  getter = name unless getter
  define_method "fill_with_#{name}" do |list|
    objects = $project.public_send(getter)
    for i in 1...objects.length
      obj = objects[i]
      list.append.set_value(0, yield(i, obj))
    end
  end
end

define_filler :classes do |index, cclass|
  cclass.name
end

define_filler :weapons do |index, weapon|
  sprintf("%03d: %s", index, weapon.name)
end

define_filler :armors do |index, armor|
  sprintf("%03d: %s", index, armor.name)
end

def fill_with_tilesets(list)
  tilesets = $project.tilesets
  for i in 1...tilesets.length
    tileset = tilesets[i]
    list.append.set_value(0, sprintf("%03d: %s", i, tileset.name))
  end
end

def fill_with_switches(list)
  switches = $project.system.switches
  for i in 1...switches.length
    switch = switches[i]
    list.append.set_value(0, $project.system.switch_name(i))
  end
end

def fill_with_variables(list)
  variables = $project.system.variables
  for i in 1...variables.length
    variable = variables[i]
    list.append.set_value(0, $project.system.variable_name(i))
  end
end
