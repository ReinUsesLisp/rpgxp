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
require_relative 'map.rb'
require_relative 'fill.rb'
require_relative 'audio_edit.rb'

class MapPropertiesEditor < DialogEditorTemplate
  def initialize(parent, title, map_id)
    @map_id = map_id
    @properties = MapProperties.new(map_id)
    super(@properties, "map_properties", title, parent)

    @tv = @builder.get_object("encounters-tv")
    @encounters = @builder.get_object("encounters")
    
    @properties.encounter_list.each do |troop_id|
      troop = $project.troops[troop_id]
      @encounters.append.set_value(0, troop.name)
    end
    @encounters.append.set_value(0, "")
  end
  def add_builder
    super
    fill_with_tilesets(@builder.get_object("tileset_names"))
  end
  def bind(properties)
    super
    rename(@builder.get_object("bgm"), @properties.bgm.name)
    rename(@builder.get_object("bgs"), @properties.bgs.name)
  end
  def extract
    properties = super
    properties.encounter_list = @properties.encounter_list
    properties.bgm = @properties.bgm
    properties.bgs = @properties.bgs
    properties.set_to_map(@map_id)
    properties
  end
  def on_add_encounter
    id = TroopChooser.new(self).call
    if id
      troop = $project.troops[id]
      last = @properties.encounter_list.length
      @properties.encounter_list.push(id)
      @encounters.insert(last).set_value(0, troop.name)
    end
  end
  def on_remove_encounter
    if cursor_path
      index = cursor_index
      if index < @properties.encounter_list.length
        @properties.encounter_list.delete_at(index)
        @encounters.remove(@encounters.get_iter(cursor_path))
      end
    end
  end
  def rename(widget, name)
    widget.label = name.empty? ? "(None)" : name
  end
  def on_bgm_edit
    @properties.bgm = AudioEdit.new(self, :bgm, @properties.bgm).edit
    rename(@builder.get_object("bgm"), @properties.bgm.name)
  end
  def on_bgs_edit
    @properties.bgs = AudioEdit.new(self, :bgs, @properties.bgs).edit
    rename(@builder.get_object("bgs"), @properties.bgs.name)
  end
  def on_bgm_toggle(check)
    @builder.get_object("bgm").sensitive = check.active?
  end
  def on_bgs_toggle(check)
    @builder.get_object("bgs").sensitive = check.active?
  end
  def cursor_path
    @tv.cursor[0]
  end
  def cursor_index
    cursor_path.indices[0] if cursor_path
  end
end

class TroopChooser < Gtk::Dialog
  def initialize(parent)
    super(title: "Choose Troop", parent: parent, flags: :modal)
    self.add_button(Gtk::Stock::CANCEL, :cancel)
    self.add_button(Gtk::Stock::OK, :ok)

    @combo = Gtk::ComboBoxText.new
    for id in 1...$project.troops.length
      troop = $project.troops[id]
      @combo.append_text(sprintf("%03d: %s", id, troop.name))
    end
    self.child.add(@combo)
    self.show_all
  end
  def call
    id = nil
    if -5 == self.run && @combo.active >= 0
      id = @combo.active + 1
    end
    self.destroy
    id
  end
end
