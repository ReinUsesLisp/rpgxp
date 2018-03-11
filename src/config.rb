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
require_relative 'widgets.rb'

class Configuration
  def initialize
    path = File.expand_path(GLib.application_name, GLib.user_config_dir)
    filepath = File.expand_path("config", path)
    file = ExtraKeyFile.new(filepath)
    @background_color = file.get_integer_list("UI", "BackgroundColor", [255, 255, 255])
    @none_color = file.get_integer_list("UI", "NoneColor", [127, 127, 127])
    @rtps = {}
    if file.has_group?("RTPs")
      for key in file.get_keys("RTPs")
        @rtps[key] = file.get_string("RTPs", key)
      end
    end
    # if there is no config file, then it's the first time opening rpgxp
    unless File.exists?(filepath)
      welcome_message
    end
  end
  def save
    dir = File.expand_path(GLib.application_name, GLib.user_config_dir)
    file = ExtraKeyFile.new
    file.set_integer_list("UI", "BackgroundColor", @background_color)
    file.set_integer_list("UI", "NoneColor", @none_color)
    for key, path in @rtps
      file.set_string("RTPs", key, path)
    end
    FileUtils.mkdir_p(dir)
    IO.write(File.expand_path("config", dir), file.to_data)
  end
  def background_color
    map_color(@background_color)
  end
  def none_color
    map_color(@none_color)
  end
  def rtp_path(rtp)
    if @rtps.key?(rtp)
      @rtps[rtp]
    else
      # TODO gui ask to add it
      raise "RTP of name #{rtp} was not found."
    end
  end
  def welcome_message
    msg = "Welcome to RPG XP!\nDo you want to import a standard RTP?"
    ask = Gtk::MessageDialog.new(message: msg, buttons_type: :none)
    ask.add_button("No", :cancel)
    ok = ask.add_button("Import RTP", :ok)
    ok.style_context.add_class("suggested-action")
    confirmed = (ask.run == :ok)
    ask.destroy
    if confirmed
      dialog = Gtk::FileChooserDialog.new(title: "Import RTP (directory)")
      dialog.action = :select_folder
      dialog.add_button("Cancel", :cancel)
      ok = dialog.add_button("Import", :ok)
      ok.style_context.add_class("suggested-action")
      if dialog.run == :ok
        @rtps["Standard"] = dialog.filename
      end
      dialog.destroy
    end
  end
  protected
  def map_color(color)
    color.map { |n| n.to_f / 255.0 }
  end
end

