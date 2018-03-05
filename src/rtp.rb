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
def change_rtp(rtp_dir)
  $project.rtp = rtp_dir
  dir = $project.dir
  $app.save_project
  $app.load_project(dir)
end

def rtp_choose_dialog(parent, title)
  dialog = Gtk::FileChooserDialog.new(title: title, parent: parent)
  dialog.action = :select_folder
  dialog.current_folder = "#{$project.rtp}/.." if $project
  dialog.add_button(Gtk::Stock::CANCEL, :cancel)
  ok = dialog.add_button(Gtk::Stock::OPEN, :ok)
  ok.style_context.add_class("suggested-action")
  dialog
end

def change_rtp_directory(parent, confirm = true)
  dialog = rtp_choose_dialog(parent, "Change RTP Directory")
  if dialog.run == :ok
    if confirm
      msg = ["Changing RTP directory requires to save and reload the project.",
             "Do you want to proceed?"].join("\n")
      ask = Gtk::MessageDialog.new(message: msg, parent: dialog,
                                   buttons_type: :none)
      ask.add_button("Cancel", :cancel)
      ok = ask.add_button("Save Project and Reload", :ok)
      ok.style_context.add_class("suggested-action")
      confirmed = (ask.run == :ok)
      ask.destroy
    end
    if !confirm || confirmed
      change_rtp(dialog.filename)
    end
  end
  dialog.destroy
end

