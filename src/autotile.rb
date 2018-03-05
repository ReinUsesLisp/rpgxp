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
def autotile_id(tile)
  tile / AS - 1
end

def autotile?(tile)
  tile != 0 && tile < FT
end

class AutotileCoords
  attr_reader :top_left_x, :top_left_y, :top_right_x, :top_right_y,
              :bot_left_x, :bot_left_y, :bot_right_x, :bot_right_y
  def initialize(*args)
    mapped = args.map { |n| (n*TS) / 2 }
    @top_left_x, @top_left_y, @top_right_x, @top_right_y,
    @bot_left_x, @bot_left_y, @bot_right_x, @bot_right_y = mapped
  end
end

class AutotileDeps
  def initialize(args)
    @data = args.map do |sym|
      case sym
      when :t; :on
      when :f; :off
      when :s, :ignore
      end
    end
  end
  def test(data)
    for i in 0...8
      value = data[i]
      case @data[i]
      when :on
        return false if !value
      when :off
        return false if value
      end
    end
    return true
  end
  def self.index(data)
    AUTOTILE_DEPENDENCIES.find_index { |dep| dep.test(data) }
  end
end

AUTOTILE_COORDINATES = [AutotileCoords.new(2, 4, 3, 4, 2, 5, 3, 5),
	                AutotileCoords.new(4, 0, 3, 4, 2, 5, 3, 5),
	                AutotileCoords.new(2, 4, 5, 0, 2, 5, 3, 5),
	                AutotileCoords.new(4, 0, 5, 0, 2, 5, 3, 5),
	                AutotileCoords.new(2, 4, 3, 4, 2, 5, 5, 1),
	                AutotileCoords.new(4, 0, 3, 4, 2, 5, 5, 1),
	                AutotileCoords.new(2, 4, 5, 0, 2, 5, 5, 1),
	                AutotileCoords.new(4, 0, 5, 0, 2, 5, 5, 1),
	                AutotileCoords.new(2, 4, 3, 4, 4, 1, 3, 5),
	                AutotileCoords.new(4, 0, 3, 4, 4, 1, 3, 5),
	                AutotileCoords.new(2, 4, 5, 0, 4, 1, 3, 5),
	                AutotileCoords.new(4, 0, 5, 0, 4, 1, 3, 5),
	                AutotileCoords.new(2, 4, 3, 4, 4, 1, 5, 1),
	                AutotileCoords.new(4, 0, 3, 4, 4, 1, 5, 1),
	                AutotileCoords.new(2, 4, 5, 0, 4, 1, 5, 1),
	                AutotileCoords.new(4, 0, 5, 0, 4, 1, 5, 1),
	                AutotileCoords.new(0, 4, 1, 4, 0, 5, 1, 5),
	                AutotileCoords.new(0, 4, 5, 0, 0, 5, 1, 5),
	                AutotileCoords.new(0, 4, 1, 4, 0, 5, 5, 1),
	                AutotileCoords.new(0, 4, 5, 0, 0, 5, 5, 1),
	                AutotileCoords.new(2, 2, 3, 2, 2, 3, 3, 3),
	                AutotileCoords.new(2, 2, 3, 2, 2, 3, 5, 1),
	                AutotileCoords.new(2, 2, 3, 2, 4, 1, 3, 3),
	                AutotileCoords.new(2, 2, 3, 2, 4, 1, 5, 1),
	                AutotileCoords.new(4, 4, 5, 4, 4, 5, 5, 5),
	                AutotileCoords.new(4, 4, 5, 4, 4, 1, 5, 5),
	                AutotileCoords.new(4, 0, 5, 4, 4, 5, 5, 5),
	                AutotileCoords.new(4, 0, 5, 4, 4, 1, 5, 5),
	                AutotileCoords.new(2, 6, 3, 6, 2, 7, 3, 7),
	                AutotileCoords.new(4, 0, 3, 6, 2, 7, 3, 7),
	                AutotileCoords.new(2, 6, 5, 0, 2, 7, 3, 7),
	                AutotileCoords.new(4, 0, 5, 0, 2, 7, 3, 7),
	                AutotileCoords.new(0, 4, 5, 4, 0, 5, 5, 5),
	                AutotileCoords.new(2, 2, 3, 2, 2, 7, 3, 7),
	                AutotileCoords.new(0, 2, 1, 2, 0, 3, 1, 3),
	                AutotileCoords.new(0, 2, 1, 2, 0, 3, 5, 1),
	                AutotileCoords.new(4, 2, 5, 2, 4, 3, 5, 3),
	                AutotileCoords.new(4, 2, 5, 2, 4, 1, 5, 3),
	                AutotileCoords.new(4, 6, 5, 6, 4, 7, 5, 7),
	                AutotileCoords.new(4, 0, 5, 6, 4, 7, 5, 7),
	                AutotileCoords.new(0, 6, 1, 6, 0, 7, 1, 7),
	                AutotileCoords.new(0, 6, 5, 0, 0, 7, 1, 7),
	                AutotileCoords.new(0, 2, 5, 2, 0, 3, 5, 3),
	                AutotileCoords.new(0, 2, 1, 2, 0, 7, 1, 7),
	                AutotileCoords.new(0, 6, 5, 6, 0, 7, 5, 7),
	                AutotileCoords.new(4, 2, 5, 2, 4, 7, 5, 7),
	                AutotileCoords.new(0, 2, 5, 2, 0, 7, 5, 7),
	                AutotileCoords.new(0, 0, 1, 0, 0, 1, 1, 1)]

AUTOTILE_DEPENDENCIES = [AutotileDeps.new(%i(t t t t t t t t)),
                         AutotileDeps.new(%i(f t t t t t t t)),
                         AutotileDeps.new(%i(t t f t t t t t)),
                         AutotileDeps.new(%i(f t f t t t t t)),
                         AutotileDeps.new(%i(t t t t t t t f)),
                         AutotileDeps.new(%i(f t t t t t t f)),
                         AutotileDeps.new(%i(t t f t t t t f)),
                         AutotileDeps.new(%i(f t f t t t t f)),
                         AutotileDeps.new(%i(t t t t t f t t)),
                         AutotileDeps.new(%i(f t t t t f t t)),
                         AutotileDeps.new(%i(t t f t t f t t)),
                         AutotileDeps.new(%i(f t f t t f t t)),
                         AutotileDeps.new(%i(t t t t t f t f)),
                         AutotileDeps.new(%i(f t t t t f t f)),
                         AutotileDeps.new(%i(t t f t t f t f)),
                         AutotileDeps.new(%i(f t f t t f t f)),
                         AutotileDeps.new(%i(s t t f t s t t)),
                         AutotileDeps.new(%i(s t f f t s t t)),
                         AutotileDeps.new(%i(s t t f t s t f)),
                         AutotileDeps.new(%i(s t f f t s t f)),
                         AutotileDeps.new(%i(s f s t t t t t)),
                         AutotileDeps.new(%i(s f s t t t t f)),
                         AutotileDeps.new(%i(s f s t t f t t)),
                         AutotileDeps.new(%i(s f s t t f t f)),
                         AutotileDeps.new(%i(t t s t f t t s)),
                         AutotileDeps.new(%i(t t s t f f t s)),
                         AutotileDeps.new(%i(f t s t f t t s)),
                         AutotileDeps.new(%i(f t s t f f t s)),
                         AutotileDeps.new(%i(t t t t t s f s)),
                         AutotileDeps.new(%i(f t t t t s f s)),
                         AutotileDeps.new(%i(t t f t t s f s)),
                         AutotileDeps.new(%i(f t f t t s f s)),
                         AutotileDeps.new(%i(s t s f f s t s)),
                         AutotileDeps.new(%i(s f s t t s f s)),
                         AutotileDeps.new(%i(s f s f t s t t)),
                         AutotileDeps.new(%i(s f s f t s t f)),
                         AutotileDeps.new(%i(s f s t f t t s)),
                         AutotileDeps.new(%i(s f s t f f t s)),
                         AutotileDeps.new(%i(t t s t f s f s)),
                         AutotileDeps.new(%i(f t s t f s f s)),
                         AutotileDeps.new(%i(s t t f t s f s)),
                         AutotileDeps.new(%i(s t f f t s f s)),
                         AutotileDeps.new(%i(s f s f f s t s)),
                         AutotileDeps.new(%i(s f s f t s f s)),
                         AutotileDeps.new(%i(s t s f f s f s)),
                         AutotileDeps.new(%i(s f s t f s f s)),
                         AutotileDeps.new(%i(s f s f f s f s)),
                         AutotileDeps.new(%i(s s s s s s s s))]
