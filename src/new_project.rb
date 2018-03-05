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
require 'fileutils'

# FIXME import Data/ from RTP?
# TODO disable create button when no RTP is set
# TODO check directory name's sanity
class NewProjectDialog < Gtk::Dialog
  def initialize(parent)
    super(title: "New Project", parent: parent, modal: :modal)
    self.add_button("Cancel", :cancel)
    self.add_button("Create", :ok)

    @grid = Gtk::Grid.new

    @name = Gtk::Entry.new
    @directory = Gtk::Entry.new

    @base = Gtk::FileChooserButton.new("Base Directory", :select_folder)
    @base.current_folder = GLib::get_user_special_dir(:documents)

    @rtp = Gtk::FileChooserButton.new("Base Directory", :select_folder)
    # FIXME remove
    # TODO read from .config
    @rtp.current_folder = "/opt/rtp"

    @import = Gtk::CheckButton.new("Import RTP")

    add_widget("Project Name:", @name)
    add_widget("Directory Name:", @directory)
    add_widget("Base Directory:", @base)
    add_widget("RTP Directory:", @rtp)

    @grid.attach(@import, 0, @index, 2, 1)

    self.child.add(@grid)
    self.show_all
  end
  def create
    dir = "#{@base.filename}/#{@directory.text}"
    FileUtils.cp_r($DATA_DIR + "/system", dir)
    FileUtils.chmod(0755, "#{dir}/mkxp_linux")
    FileUtils.cp_r("#{@rtp.filename}/Data", dir+'/')
    if @import.active?
      FileUtils.cp_r("#{@rtp.filename}/Audio", dir+'/')
      FileUtils.cp_r("#{@rtp.filename}/Graphics", dir+'/')
    end

    $app.load_project(dir)
    $project.rtp = @import.active? ? "" : @rtp.filename
    $project.title = @name.text
    $app.save_project
  end
  def add_widget(label, widget)
    @index ||= 0
    @grid.attach(Gtk::Label.new(label), 0, @index, 1, 1)
    @grid.attach(widget, 1, @index, 1, 1)
    @index += 1
  end
  def self.call(parent)
    dialog = new(parent)
    dialog.create if dialog.run == :ok
    dialog.destroy
  end
end


