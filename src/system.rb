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

class RPG::System
  def variable_name(id)
    get_name(id, @variables[id])
  end
  def switch_name(id)
    get_name(id, @switches[id])
  end
  private
  def get_name(id, name)
    name.empty? ? sprintf("%04d", id) : sprintf("%04d: %s", id, name)
  end
end
