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
class XProj
  attr_reader :id, :version
  attr_accessor :title, :rtps, :debug_mode, :print_fps, :window_resizable,
                :fixed_aspect_ratio, :smooth_scaling, :vsync, :screen_width,
                :screen_height, :fixed_framerate, :frame_skip,
                :sync_to_refresh_rate, :solid_fonts, :subimage_fix,
                :enable_blitting, :max_texture_size, :game_folder,
                :toggle_fullscreen, :enable_reset, :allow_symlinks, :org_name,
                :app_name, :icon_path, :preload_scripts, :path_cache,
                :font_subs, :midi_font, :midi_chorus, :midi_reverb, :se_count,
                :exec_name, :title_language
  def initialize
    @id = "RPGXP"
    @version = 1
    # ini and mkxp
    @title = "Untitled"
    @scripts = "Data\\Scripts.rxdata"
    @rtps = ["Standard"]
    # ini only
    @library = "RGSS102E.dll"
    # mkxp.conf only
    @debug_mode = false
    @print_fps = false
    @window_resizable = false
    @fixed_aspect_ratio = true
    @smooth_scaling = true
    @vsync = false
    @screen_width = 640
    @screen_height = 480
    @fixed_framerate = 0
    @frame_skip = true
    @sync_to_refresh_rate = false
    @solid_fonts = false
    @subimage_fix = false
    @enable_blitting = true
    @max_texture_size = 0
    @game_folder = "."
    @toggle_fullscreen = false
    @enable_reset = true
    @allow_symlinks = false
    @org_name = nil
    @app_name = nil
    @icon_path = nil
    @preload_scripts = []
    @path_cache = true
    @font_subs = []
    @midi_font = "GMGSx.sf2"
    @midi_chorus = false
    @midi_reverb = false
    @se_count = 6
    @exec_name = "Game"
    @title_language = nil
  end
  def load_ini(filepath)
    file = ExtraKeyFile.new(filepath)
    name = File.basename(filepath, ".ini")
    keys = file.get_keys("Game")
    rtps = keys.delete_if { |key| !key.match?(/RTP/) }.sort

    @scripts = file.get_value("Game", "Scripts", @scripts)
    @library = file.get_string("Game", "Library", @library)
    @title = file.get_string("Game", "Title", @title)
    @exec_name = name

    @rtps = []
    for rtp in rtps
      rtp_name = file.get_string("Game", rtp)
      @rtps.push(rtp_name) unless rtp_name.empty?
    end
  end
  def rtps
    @rtps.map { |rtp| $config.rtp_path(rtp) }
  end
  def save(dir)
    IO.write(File.expand_path("#{@exec_name}.xproj", dir), Marshal.dump(self))
  end
  def export_ini(dir)
    file = ExtraKeyFile.new
    file.set_string("Game", "Library", @library)
    file.set_string("Game", "Scripts", @scripts)
    file.set_string("Game", "Title", @title)
    @rtps.each_index do |index|
      file.set_string("Game", sprintf("RTP%d", index+1), @rtps[index])
    end
    # convert to DOS style
    data = file.to_data
    data.gsub!("\n", "\r\n")
    IO.write(File.expand_path("#{@exec_name}.ini", dir), data)
  end
  def export_conf(dir)
    file = File.open(File.expand_path("mkxp.conf", dir), "w")
    set_item(file, "rgssVersion", 1)
    set_item(file, "debugMode", @debug_mode)
    set_item(file, "printFPS", @print_fps)
    set_item(file, "winResizable", @window_resizable)
    set_item(file, "fixedAspectRatio", @fixed_aspect_ratio)
    set_item(file, "smoothScaling", @smooth_scaling)
    set_item(file, "vsync", @vsync)
    set_item(file, "defScreenW", @screen_width)
    set_item(file, "defScreenH", @screen_height)
    set_item(file, "windowTitle", @title)
    set_item(file, "fixedFramerate", @fixed_framerate)
    set_item(file, "frameSkip", @frame_skip)
    set_item(file, "syncToRefreshrate", @sync_to_refresh_rate)
    set_item(file, "solidFonts", @solid_fonts)
    set_item(file, "subImageFix", @subimage_fix)
    set_item(file, "enableBlitting", @enable_blitting)
    set_item(file, "maxTextureSize", @max_texture_size)
    set_item(file, "gameFolder", @game_folder)
    set_item(file, "anyAltToggleFS", @toggle_fullscreen)
    set_item(file, "enableReset", @enable_reset)
    set_item(file, "allowSymlinks", @allow_symlinks)
    set_item(file, "dataPathOrg", @org_name) if @org_name
    set_item(file, "dataPathApp", @app_name) if @app_name
    set_item(file, "iconPath", @icon_path) if @icon_path
    for script in @preload_scripts
      set_item(file, "preloadScript", script)
    end
    set_item(file, "pathCache", @path_cache)
    for rtp in @rtps
      set_item(file, "RTP", $config.rtp_path(rtp))
    end
    set_item(file, "useScriptNames", true)
    for sub in @font_subs
      original, replacement = sub
      set_item(file, "fontSub", "#{original}>#{replacement}")
    end
    set_item(file, "midi.soundFont", @midi_font) if @midi_font
    set_item(file, "midi.chorus", @midi_chorus)
    set_item(file, "midi.reverb", @midi_reverb)
    set_item(file, "SE.sourceCount", @se_count)
    set_item(file, "execName", @exec_name)
    set_item(file, "titleLanguage", @title_language) if @title_language
    file.close
  end
  protected
  def set_item(file, key, value)
    file.puts("#{key}=#{value}\n")
  end
end

