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
require_relative 'map_properties_edit.rb'

class MapInfosBind
  def initialize(tv, store)
    @tv = tv
    @store = store
    
    infos = $project.mapinfos.sort_by { |id, info| info.order }
    iters = {}

    # FIXME evil data may hang
    until iters.all? && iters.count >= infos.count
      for id, info in infos
        parent_id = info.parent_id
        parent = parent_id == 0 ? nil : iters[parent_id]
        if parent || parent_id == 0
          iters[id] = iter = store.append(parent)
          iter.set_value(0, info.name)
          iter.set_value(1, id)
        end
      end
    end
    
    refresh_expanded

    store.signal_connect("row-changed") { |model, path, iter| on_row_changed(path) }
    store.signal_connect_after("row-deleted") { on_row_deleted }
    tv.signal_connect("row-expanded") { |iter, tv, path| on_expand_changed(path, true) }
    tv.signal_connect("row-collapsed") { |iter, tv, path| on_expand_changed(path, false) }
    tv.signal_connect("row-activated") { |tv, path| on_activated(path) }
    tv.signal_connect("button-press-event") { |tv, event| on_button_press(event) }
  end
  def on_button_press(ev)
    if Gdk::EventType::BUTTON_PRESS == ev.type and 3 == ev.button
      path, column = @tv.get_path_at_pos(ev.x, ev.y)
      id = find_id_with_path(path)
      info = find_info_with_path(path)
      if info
        $app.edit_map(id)
        @tv.set_cursor(path, nil, false)
      end

      menu = Gtk::Menu.new
      props = Gtk::MenuItem.new(label: "Properties")
      new = Gtk::MenuItem.new(label: "New")
      copy = Gtk::MenuItem.new(label: "Copy")
      paste = Gtk::MenuItem.new(label: "Paste")
      delete = Gtk::MenuItem.new(label: "Delete")

      props.signal_connect("activate") do
        dialog = MapPropertiesEditor.new(parent, "Map Properties", id)
        dialog.edit
        if dialog.accepted?
          @store.get_iter(path).set_value(0, info.name)
          # force map bind (it redraws too)
          $app.edit_map(id)
        end
      end

      new.signal_connect("activate") do
        parent_info = info
        parent_id = id || 0
        new_id = RPG::Map.new_id
        new_name = sprintf("MAP%03d", new_id)

        $project.mapinfos[new_id] = RPG::MapInfo.new(new_name, parent_id)
        $project.maps[new_id] = RPG::Map.new
          
        dialog = MapPropertiesEditor.new(parent, "New Map", new_id)
        dialog.edit
        if dialog.accepted?
          iter = @store.append(@store.get_iter(path))
          iter.set_value(0, $project.mapinfos[new_id].name)
          iter.set_value(1, new_id)
          parent_info.expanded = true if parent_info
          refresh_orders
          refresh_expanded
        else
          $project.mapinfos.delete[new_id]
          $project.maps.delete[new_id]
        end
        $app.edit_map(new_id)
      end

      delete.signal_connect("activate") do
        $project.mapinfos.delete(id)
        loop do
          any = false
          for id, info in $project.mapinfos
            if info.parent_id != 0 && !$project.mapinfos.key?(info.parent_id)
              $project.mapinfos.delete(id)
              any = true
            end
          end
          break unless any
        end
        @store.remove(@store.get_iter(path))
        refresh_orders
      end

      if info
        menu.append(props)
        # TODO separator here
      else
        copy.sensitive = false
        delete.sensitive = false
      end

      [new, copy, paste, delete].each { |item| menu.append(item) }
      menu.show_all
      menu.popup_at_pointer(nil)
    end
  end
  def refresh_orders(order = 1, path = Gtk::TreePath.new("0"))
    loop do
      info = find_info_with_path(path)
      break unless info

      info.order = order
      order += 1

      child = Gtk::TreePath.new(path.to_s)
      child.down!
      order = refresh_orders(order, child)

      path.next!
    end
    order
  end
  def refresh_expanded
    @store.each do |model, path, iter|
      info = find_info_with_path(path)
      if !info || (info && info.expanded)
        @tv.expand_row(path, false)
      end
    end
  end
  def on_activated(path)
    id = find_id_with_path(path)
    $app.edit_map(id) if id
  end
  def on_row_deleted
    refresh_orders
  end
  def on_row_changed(path)
    info = find_info_with_path(path)
    if info
      if path.depth > 1
        path.up!
        info.parent_id = find_id_with_path(path)
      else
        info.parent_id = 0
      end
    end
  end
  def on_expand_changed(path, state)
    info = find_info_with_path(path)
    info.expanded = state if info
  end
  def find_id_with_path(path)
    if path
      iter = @store.get_iter(path)
      @store.get_value(iter, 1) if iter
    end
  end
  def find_info_with_path(path)
    if path
      id = find_id_with_path(path)
      $project.mapinfos[id] if id
    end
  end
  def parent
    @tv.toplevel
  end
end
