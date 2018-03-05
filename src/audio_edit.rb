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
require_relative 'widgets.rb'
require_relative 'resource.rb'

class AudioEdit < DialogEditorTemplate
  def initialize(parent, type, audio)
    title = type.to_s.upcase
    @audio = audio
    super(@audio, "audio", title, parent)
    @tv = @builder.get_object("tv")
    @audios = @builder.get_object("audios")
    @resources = Resource.list(type)

    @audios.append.set_value(0, "(None)")
    for audio in @resources
      @audios.append.set_value(0, audio)
    end

    found = @resources.find_index(@audio.name)
    index = found ? found+1 : 0
    @tv.set_cursor(Gtk::TreePath.new(index.to_s), nil, false)
  end
  def extract
    audio = super
    audio.name = ""
    path = @tv.cursor[0]
    if path
      index = path.indices[0]
      if index > 0
        audio.name = @resources[index-1]
      end
    end
    audio
  end
end
