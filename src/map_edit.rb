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
require 'open3'
require_relative 'event.rb'
require_relative 'map_view.rb'
require_relative 'event_edit.rb'

class MapEdit < MapView
  def initialize(*args)
    super
    self.can_focus = true
    self.focus_on_click = true
    self.add_events([:button_press_mask, :button_release_mask,
                     :pointer_motion_mask, :key_press_mask])
    self.signal_connect("button-press-event") { |w, event| on_button_press(event) }
    self.signal_connect("button-release-event") { |w, event| on_button_release(event) }
    self.signal_connect("motion-notify-event") { |w, event| on_motion(event) }
    self.signal_connect("key-press-event") { |w, event| on_key_press(event) }
    tile_mode(0)

    @selecting = false
    @sel_start_x = @sel_start_y = 0
    @start_x = @start_y = 0
    @pointer_x = @pointer_y = 0
    @cursor_x = @cursor_y = 0
  end
  def delete_all_on_cursor
    events_on_cursor.each { |id, event| delete_event(id) }
  end
  def delete_on_cursor
    events = events_on_cursor
    if events.length > 1
      menu = Gtk::Menu.new
      add_delete_events_to_menu(menu, events)
      menu.show_all
      menu.popup_at_pointer(nil)
    else
      delete_event(events.first[0])
    end
  end
  def write_selection(x, y, raw = false)
    if $selection
      $selection.paste_to_map(@map, x, y, @start_x, @start_y, active_layer, raw)
      # include surroundings
      $selection.queue_draw(self, x-1, y-1, 2, 2)
    end
  end
  def move_cursor(x, y)
    # redraw previous position
    self.queue_draw_area(@cursor_x*TS, @cursor_y*TS, TS, TS)
    self.queue_draw_area(x*TS, y*TS, TS, TS)
    @cursor_x = x
    @cursor_y = y
  end
  def edit_events_on_cursor
    events = events_on_cursor
    # unique skips menu query
    if events.length == 1
      id = events.first[0]
      edit_event(id)
    elsif events.length > 1
      menu = Gtk::Menu.new
      add_edit_events_to_menu(menu, events)
      menu.show_all
      menu.popup_at_pointer(nil)
    end
  end
  def delete_event(id)
    event = @map.events[id]
    self.queue_draw_area(event.x*TS, event.y*TS, TS, TS)
    @map.events.delete(id)
  end
  def add_edit_events_to_menu(menu, events, extra = "")
    add_events_to_menu(menu, events, extra) { |id| edit_event(id) }
  end
  def add_delete_events_to_menu(menu, events)
    add_events_to_menu(menu, events, "") { |id| delete_event(id) }
  end
  def add_events_to_menu(menu, events, extra)
    events.each do |id, event|
      item = Gtk::MenuItem.new(label: extra + event.name)
      item.signal_connect("activate") { yield(id) }
      menu.append(item)
    end
  end
  def events_on_position(x, y)
    events = @map.events.clone
    events.delete_if do |id, event|
      !(event.x == x && event.y == y)
    end
    events
  end
  def events_on_cursor
    events_on_position(@cursor_x, @cursor_y)
  end
  def new_event(x, y)
    id = @map.new_event_id
    template = RPG::Event.new(id, x, y)
    @map.events[id] = template
    dialog = EventEditor.new(self.toplevel, "New Event", @map, template)
    event = dialog.edit
    if dialog.canceled?
      @map.events.delete(id)
    else
      @map.events[id] = event
    end
    self.queue_draw_area(x*TS, y*TS, TS, TS)
  end
  def edit_event(id)
    event = @map.events[id]
    title = sprintf("Edit Event - ID:%03d", id)
    dialog = EventEditor.new(self.toplevel, title, @map, @map.events[id])
    @map.events[id] = dialog.edit
    self.queue_draw_area(event.x*TS, event.y*TS, TS, TS)
  end
  def selection_rectangle
    Rectangle.new(@sel_start_x, @sel_start_y, @pointer_x, @pointer_y,
                  @map.width, @map.height, false)
  end
  def on_draw(cr)
    super
    case @mode
    when :tile
      if @selecting
        r = selection_rectangle
        cr.draw_selection(TS, TS, r.min_x, r.min_y, r.width, r.height)
      else
        $selection.draw(cr, @pointer_x, @pointer_y) if $selection
      end
    when :event
      cr.draw_selection(TS, TS, @cursor_x, @cursor_y)
    end
  end
  def on_button_press(ev)
    return unless @map

    x, y = @scroll.hadjustment.value, @scroll.vadjustment.value
    self.grab_focus
    @scroll.hadjustment.value, @scroll.vadjustment.value = x, y

    x = ev.x.to_i / TS
    y = ev.y.to_i / TS
    case @mode
    when :tile
      if 1 == ev.button && $selection
        @start_x = x
        @start_y = y
        write_selection(x, y, ev.state.shift_mask?)
      end
      if 3 == ev.button
        $selection.queue_draw(self, @pointer_x, @pointer_y) if $selection
        self.queue_draw_area(x*TS, y*TS, TS, TS)
        @selecting = true
        @sel_start_x = @pointer_x = x
        @sel_start_y = @pointer_y = y
      end
    when :event
      if x < 0 || x >= @map.width || y < 0 || y >= @map.height
        return
      end
      if 1 == ev.button
        case ev.event_type
        when Gdk::EventType::BUTTON_PRESS
          move_cursor(x, y)
        when Gdk::EventType::BUTTON2_PRESS
          if events_on_cursor.empty?
            new_event(x, y)
          else
            edit_events_on_cursor
          end
        end
      end
    end
  end
  def on_button_release(ev)
    return unless @map
    pointer_x = ev.x.to_i / TS
    pointer_y = ev.y.to_i / TS
    case @mode
    when :tile
      if 3 == ev.button
        @pointer_x = pointer_x
        @pointer_y = pointer_y
        @selecting = false
        $selection = Selection.map(@map, selection_rectangle, active_layer)
        $selection.queue_draw(self, @pointer_x, @pointer_y)
      end
    when :event
      if 3 == ev.button
        if pointer_x < 0 || pointer_x >= @map.width ||
           pointer_y < 0 || pointer_y >= @map.height
          return
        end
        
        self.queue_draw_area(@cursor_x*TS, @cursor_y*TS, TS, TS)
        self.queue_draw_area(pointer_x*TS, pointer_y*TS, TS, TS)
        @cursor_x = pointer_x
        @cursor_y = pointer_y
        
        menu = Gtk::Menu.new
        
        item = Gtk::MenuItem.new(label: "New Event")
        item.signal_connect("activate") do
          new_event(pointer_x, pointer_y)
        end
        menu.append(item)

        add_edit_events_to_menu(menu, events_on_cursor, "Edit ")
        
        menu.append(Gtk::SeparatorMenuItem.new)

        item = Gtk::MenuItem.new(label: "Player's Starting Position")
        system = $project.system
        item.signal_connect("activate") do
          if @map_id == system.start_map_id
            self.queue_draw_area(system.start_x*TS, system.start_y*TS, TS, TS)
          end
          self.queue_draw_area(pointer_x*TS, pointer_y*TS, TS, TS)
          
          system.start_x = pointer_x
          system.start_y = pointer_y
          system.start_map_id = @map_id
        end
        if @map_id == system.start_map_id &&
           system.start_x == pointer_x && system.start_y == pointer_y
          item.sensitive = false
        end
        menu.append(item)

        menu.show_all
        menu.popup_at_pointer
      end
    end
  end
  def on_key_press(ev)
    case @mode
    when :event
      x, y = @cursor_x, @cursor_y
      case ev.keyval
      when Gdk::Keyval::KEY_Left
        move_cursor((x-1) % @map.width, y)
      when Gdk::Keyval::KEY_Right
        move_cursor((x+1) % @map.width, y)
      when Gdk::Keyval::KEY_Up
        move_cursor(x, (y-1) % @map.height)
      when Gdk::Keyval::KEY_Down
        move_cursor(x, (y+1) % @map.height)
      when Gdk::Keyval::KEY_space
        edit_events_on_cursor
      else
        return false
      end
      return true
    end
    return false
  end
  def on_motion(ev)
    case @mode
    when :tile
      x = ev.x.to_i / TS
      y = ev.y.to_i / TS
      if @pointer_x != x || @pointer_y != y
        old_x = @pointer_x
        old_y = @pointer_y
        @pointer_x = x
        @pointer_y = y
        if ev.state.button1_mask?
          write_selection(x, y, ev.state.shift_mask?)
        end
        if ev.state.button3_mask?
          if @selecting
            # FIXME
            Rectangle.new(@sel_start_x, @sel_start_y, old_x, old_y, nil, nil, false).queue_draw(self)
            Rectangle.new(@sel_start_x, @sel_start_y, @pointer_x, @pointer_y, nil, nil, false).queue_draw(self)
          end
        end
        if $selection
          $selection.queue_draw(self, old_x, old_y)
          $selection.queue_draw(self, @pointer_x, @pointer_y)
        end
      end
    end
  end
  def tile_mode(layer)
    self.active_layer = layer
    @mode = :tile
    self.queue_draw
  end
  def event_mode
    @mode = :event
    self.queue_draw
  end
  def draw_lines
    @mode == :event
  end
  def highlight_events
    @mode == :event
  end
  def dim
    super && @mode != :event
  end
  def dim=(dim)
    super
    self.queue_draw
  end
end
