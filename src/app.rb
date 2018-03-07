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
require 'os'
require 'launchy'
require_relative 'project.rb'
require_relative 'map_edit.rb'
require_relative 'tileset_view.rb'
require_relative 'mapinfo_bind.rb'
require_relative 'database.rb'
require_relative 'rtp.rb'
require_relative 'new_project.rb'

class ApplicationWindow < Gtk::ApplicationWindow
  def initialize(app, builder)
    super(app)
    self.title = "RPGXP"
    self.add(builder.get_object("widget"))
    @paned = builder.get_object("left-paned")
    connect_store
    restore
    self.show_all
  end
  def restore
    path = File.expand_path(GLib.application_name, GLib.user_cache_dir)
    file = GLib::KeyFile.new
    file.load_from_file(File.expand_path("state.ini", path))
    
    width = file.get_integer("WindowState", "Width")
    height = file.get_integer("WindowState", "Height")
    maximize = file.get_boolean("WindowState", "Maximized")
    paned_position = file.get_integer("WindowState", "PanedPosition")
  rescue
    width = 900
    height = 550
    maximize = false
    paned_position = 300
  ensure
    self.resize(width, height)
    self.maximize if maximize
    @paned.position = paned_position
  end
  def connect_store
    self.signal_connect("size-allocate") do
      @width, @height = self.size
    end
    self.signal_connect("window-state-event") do |w, event|
      state = event.new_window_state
      @maximized = (state == :maximized)
    end
    self.signal_connect("destroy") do
      file = GLib::KeyFile.new
      file.set_integer("WindowState", "Width", @width)
      file.set_integer("WindowState", "Height", @height)
      file.set_boolean("WindowState", "Maximized", @maximized)
      # querying while destroying is not safe, but I can't find paned's signal
      file.set_integer("WindowState", "PanedPosition", @paned.position)
      path = File.expand_path(GLib.application_name, GLib.user_cache_dir)
      begin
        FileUtils.mkdir_p(path)
        IO.write(File.expand_path("state.ini", path), file.to_data)
      rescue Errno::EACCES
      end
    end
  end
end

class MainApplication < Gtk::Application
  def initialize
    super("com.github." + $PROJECT_NAME, :flags_none)
    self.signal_connect("startup") { on_startup }
    self.signal_connect("activate") { on_activate }
  end
  def on_startup
    @builder = ExtraBuilder.new("main")
    self.set_menubar(@builder.get_object("menubar"))
    
    add_simple_actions("open", "save", "close", "run", "quit", "undo",
                       "redo", "copy", "cut", "paste", "delete", "scripts",
                       "database", "rtp")
    add_radio_action("layerview", "all")
    add_radio_action("layeredit", "layer1")
    add_check_action("dim")
  end
  def on_activate
    @window = ApplicationWindow.new(self, @builder)
  end
  def on_new
    NewProjectDialog.call(@window)
  end
  def on_rtp
    return unless has_project?
    change_rtp_directory(@window)
  end
  def on_database
    return unless has_project?
    database = DatabaseDialog.new(@window)
    database.run
    database.destroy
  end
  def on_close
    close_project if has_project?
  end
  def close_project
    return unless has_project?
    @mapedit.destroy
    @palette.destroy
    @builder.get_object("mapinfo-store").clear
    # destroy viewports, keep scrolled windows
    @builder.get_object("scrolled-map").child.destroy
    @builder.get_object("scrolled-palette").child.destroy
    $project = nil
  end
  def load_project(dir)
    close_project if has_project?
    $project = Project.new(dir)
    MapInfosBind.new(@builder.get_object("mapinfo-tv"),
                     @builder.get_object("mapinfo-store"))
    @mapedit = MapEdit.new(@builder.get_object("scrolled-map"))
    @palette = Palette.new(@builder.get_object("scrolled-palette"))
    edit_map($project.system.edit_map_id)

    @window.show_all
  end
  def has_project?
    $project != nil
  end
  def edit_map(map_id)
    $project.system.edit_map_id = map_id
    @map = $project.maps[map_id]
    @mapedit.map_id = map_id
    @palette.tileset = $project.tilesets[@map.tileset_id]
  end
  def on_open
    dialog = Gtk::FileChooserDialog.new(title: "Open Project", parent: @window)
    dialog.action = :select_folder
    dialog.add_button(Gtk::Stock::CANCEL, :cancel)
    open = dialog.add_button(Gtk::Stock::OPEN, :ok)
    open.style_context.add_class("suggested-action")
    if dialog.run == :ok
      load_project(dialog.filename)
    end
    dialog.destroy
  end
  def on_quit
    $app.quit
  end
  def on_scripts
    return unless has_project?
    if OS.linux? || OS.freebsd?
      system("xdg-open", $project.scripts_dir)
    else
      Launchy.open($project.scripts_dir)
    end
  end
  def on_run
    return unless has_project?
    save_project

    bin = "#{$project.dir}/mkxp_linux"
    Open3.popen3(bin, "debug") do |stdin, stdout, stderr, thread|
      thread.join
      
      lines = stderr.read.lines
      index = lines.find_index { |line| /Exception/.match?(line) }
      if index
        error = lines[index+1]
        file, line = error["Section".length..-1].split(":")
        file = file.to_i
        line = line.to_i
        puts $project.scripts[file][1]
      end
    end
  end
  def save_project
    $project.save if has_project?
  end
  def on_save
    save_project
  end
  def on_delete
    if @mapedit.has_focus?
      @mapedit.delete_on_cursor
    end
  end
  def on_layerview(value)
    case value
    when "below"
      @mapedit.draw_all = false
    when "all"
      @mapedit.draw_all = true
    end
    @mapedit.queue_draw
  end
  def on_layeredit(value)
    case value
    when "layer1"
      @mapedit.tile_mode(0)
    when "layer2"
      @mapedit.tile_mode(1)
    when "layer3"
      @mapedit.tile_mode(2)
    when "events"
      @mapedit.event_mode
    end
  end
  def on_dim(value)
    @mapedit.dim = value
  end
  def has_map?
    @map != nil
  end
  def add_radio_action(name, default)
    variant = GLib::Variant.new(default)
    action = Gio::SimpleAction.new(name, GLib::VariantType::STRING, variant)
    action.signal_connect("activate") do |widget, value|
      action.change_state(GLib::Variant.new(value))
      public_send("on_#{name}", value)
    end
    self.add_action(action)
  end
  def add_check_action(name, default = false)
    action = Gio::SimpleAction.new(name, nil, GLib::Variant.new(default))
    action.signal_connect("activate") do |widget, _ignore_me|
      value = !widget.state
      action.set_state(GLib::Variant.new(value))
      public_send("on_#{name}", value)
    end
    self.add_action(action)
  end
  def add_simple_actions(*names)
    names.each do |name|
      action = Gio::SimpleAction.new(name)
      action.signal_connect("activate") { |w, v| public_send("on_#{name}") }
      self.add_action(action)
    end
  end
end

