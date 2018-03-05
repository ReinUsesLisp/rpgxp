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
require_relative 'project.rb'
require_relative 'command.rb'
require_relative 'widgets.rb'
require_relative 'fill.rb'
require_relative 'move_route_edit.rb'
require_relative 'resource.rb'
require_relative 'convert.rb'
require_relative 'map.rb'

class EventEditor < DialogEditorTemplate
  def initialize(parent, title, map, event)
    @map = map
    @event = event
    super(@event, "event", title, parent)

    notebook = Gtk::Notebook.new
    @builder.get_object("page-container").add(notebook)

    @pages = []
    for page in @event.pages
      builder = PageEditor.new(self, page)
      notebook.append_page(big_widget(builder.widget, self.screen, 720, 400))
      @pages.push(builder)
    end
  end
  def extract
    object = super
    object.pages = @pages.map { |page| page.extract }
    object.x = @original.x
    object.y = @original.y
    object
  end
end

class GraphicEditor < DialogImageChooser
  def initialize(parent, graphic)
    super(:character, graphic, "graphic", "Graphic", parent)
    @list.prepend.set_value(0, "(Tileset)")
    @list.prepend.set_value(0, "(None)")
  end
  def on_cursor_move
    # cursor_index includes none and tileset items (2)
    if cursor_path && cursor_index >= 2
      @resource = @resources[cursor_index - 2]
    else
      @resource = nil
    end
    @builder.get_object("area").queue_draw
  end
  def on_area_click(area, event)
    surface = Resource.load(:character, @resource)
    x, y = event.x.to_i, event.y.to_i
    if x < surface.width && y < surface.height
      @pattern = x / (surface.width / 4)
      @direction = offset_to_direction(y / (surface.height / 4))
      @builder.get_object("area").queue_draw
    end
  end
  def on_draw(area, cr)
    if @resource
      surface = Resource.load(:character, @resource)
      area.width_request = surface.width
      area.height_request = surface.height
      chara_x = surface.width / 4
      chara_y = surface.height / 4

      cr.set_source_rgb(1.0, 1.0, 1.0)
      cr.rectangle(0, 0, surface.width, surface.height)
      cr.fill
      cr.set_source(surface)
      cr.paint
      cr.draw_selection(chara_x, chara_y,
                        @pattern, direction_to_offset(@direction))
    end
    cr.destroy
  end
  def bind(graphic)
    super
    unless graphic.character_name.empty?
      index = @resources.find_index(graphic.character_name) || \
              raise("Invalid graphic #{graphic.character_name}")
      treeview.set_cursor(Gtk::TreePath.new((index + 2).to_s), nil, false)
    end
    @pattern = graphic.pattern
    @direction = graphic.direction
  end
  def extract
    graphic = super
    graphic.character_name = @resource || @original.character_name
    graphic.pattern = @pattern
    graphic.direction = @direction
    # FIXME get from input
    graphic.tile_id = 0
    graphic
  end
  def treeview
    @builder.get_object("resource")
  end
  def cursor_path
    treeview.cursor[0]
  end
  def cursor_index
    cursor_path.indices[0] if cursor_path
  end
end

class PageEditor < ExtraBuilder
  def initialize(parent, page)
    super("event_page")
    self.connect_signals { |handler| method("on_#{handler}") }
    @parent = parent

    fill_with_switches(self.get_object("switches"))
    fill_with_variables(self.get_object("variables"))

    @page = page.clone
    @page.class.bind_to(self, page)
    @page.condition.class.bind_to(self, page.condition)
    @graphic = @page.graphic
    @move_route = @page.move_route
    @commands = @page.list

    @list = self.get_object("commands")
    for command in @commands
      command.set_iter(@list.append)
    end
  end
  def on_graphic_click(area, event)
    if event.event_type == Gdk::EventType::BUTTON2_PRESS
      @graphic = GraphicEditor.new(@parent, @graphic).edit
      @parent.queue_draw
    end
  end
  def on_change_move_route
    editor = MoveRouteEditor.new(@parent, @move_route)
    @move_route = editor.edit
  end
  def on_move_type_change
    self.get_object("move_route_button").sensitive = RPG::Event::Page::Custom == self.get_object("move_type").active
  end
  def extract
    page = @page.class.extract_from(self)
    page.condition = @page.condition.class.extract_from(self)
    page.move_route = @move_route
    page.graphic = @graphic
    page.list = @commands
    page
  end
  def widget
    self.get_object("widget")
  end
  def on_graphic_draw(area, cr)
    unless @graphic.character_name.empty?
      surface = Resource.load(:character, @graphic.character_name)
      chara_x = surface.width / 4
      chara_y = surface.height / 4

      offset_x = chara_x * @graphic.pattern
      offset_y = chara_y * direction_to_offset(@graphic.direction)

      draw_x = (area.allocation.width - chara_x) / 2
      draw_y = (area.allocation.height - chara_y) / 2

      cr.push_group
      cr.set_source(surface, draw_x-offset_x, draw_y-offset_y)
      cr.rectangle(draw_x, draw_y, chara_x, chara_y)
      cr.fill
      cr.pop_group_to_source
      cr.paint(@graphic.opacity / 255.0)
    end
    cr.destroy
  end
  def self.define_toggle(name, check, widgets)
    define_method name do
      active = get_object(check).active?
      for widget in widgets
        self.get_object(widget).sensitive = active
      end
    end
  end
  define_toggle :on_toggle_switch1, "switch1_valid", ["switch1_id"]
  define_toggle :on_toggle_switch2, "switch2_valid", ["switch2_id"]
  define_toggle :on_toggle_variable, "variable_valid", ["variable_id", "variable_value_widget"]
  define_toggle :on_toggle_self_switch, "self_switch_valid", ["self_switch_ch"]
end
