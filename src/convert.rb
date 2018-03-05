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
def minus_one(n)
  n-1
end

def plus_one(n)
  n+1
end

def self_switch_to_character(a)
  {"A" => 0, "B" => 1, "C" => 2, "D" => 3}[a] || -1
end

def character_to_self_switch(a)
  ["A", "B", "C", "D"][a]
end

def to_float(n)
  n.to_f
end

def to_integer(n)
  n.to_i
end

def direction_to_offset(direction)
  case direction
  when 2; 0
  when 4; 1
  when 6; 2
  when 8; 3
  else; raise("Not a direction (#{direction})")
  end
end

def offset_to_direction(offset)
  case offset
  when 0; 2
  when 1; 4
  when 2; 6
  when 3; 8
  else; raise("Not an offset (#{offset})")
  end
end
