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

class DatabaseDialog < Gtk::Dialog
  def initialize(parent)
    super(title: "Database", parent: parent, flags: :modal)
    self.add_button(Gtk::Stock::CANCEL, :cancel)
    ok = self.add_button(Gtk::Stock::OK, :ok)
    #ok.style_context.add_class("suggested-action")

    widget = GenericDatabaseEditor.new("actor", "Actors", $project.actors[1..-1])
    self.child.add(widget)
    self.show_all
  end
end

class GenericDatabaseEditor < Gtk::Box
  def initialize(ui, column, array, name_getter = :name)
    super(:horizontal)
    @builder = ExtraBuilder.new(ui)

    @store = Gtk::ListStore.new(String)
    for object in array
      item = @store.append
      item.set_value(0, object.public_send(name_getter))
    end

    @tv = Gtk::TreeView.new(@store)
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new(column, renderer, { :text => 0, })
    @tv.append_column(column)

    scroll = Gtk::ScrolledWindow.new(nil, nil)
    scroll.add(@tv)
    scroll.width_request = 150

    self.add(scroll)
    self.add(big_widget(self["widget"], self.screen, 620, 400))
    self.show_all
  end
  def [](widget_name)
    @builder.get_object(widget_name)
  end
end

