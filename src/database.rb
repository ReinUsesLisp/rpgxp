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

class DatabaseWindow < Gtk::Window
  def initialize
    super()
    self.title = "Database"
    
    buttons = Gtk::ButtonBox.new(:horizontal)
    buttons.layout = :end
    buttons.spacing = 4
    cancel = Gtk::Button.new(stock_id: Gtk::Stock::CANCEL)
    apply = Gtk::Button.new(stock_id: Gtk::Stock::APPLY)
    ok = Gtk::Button.new(stock_id: Gtk::Stock::OK)
    ok.style_context.add_class("suggested-action")
    buttons.add(cancel)
    buttons.add(apply)
    buttons.add(ok)

    notebook = Gtk::Notebook.new
    notebook.tab_pos = :left
    notebook.vexpand = true
    notebook.scrollable = true

    widget = ActorEditor.new
    notebook.append_page(widget, Gtk::Label.new("Actors"))
    
    not_implemented(notebook, "Classes")
    not_implemented(notebook, "Skills")
    not_implemented(notebook, "Items")
    not_implemented(notebook, "Weapons")
    not_implemented(notebook, "Armors")
    not_implemented(notebook, "Enemies")
    not_implemented(notebook, "Troops")
    not_implemented(notebook, "States")
    not_implemented(notebook, "Animations")
    not_implemented(notebook, "Tilesets")
    not_implemented(notebook, "Common\nEvents")
    not_implemented(notebook, "System")

    vbox = Gtk::Box.new(:vertical)
    vbox.add(notebook)
    vbox.add(buttons)
    self.add(vbox)
    self.show_all
  end
  def not_implemented(notebook, name)
    label = Gtk::Label.new("This has not been implemented yet")
    notebook.append_page(label, Gtk::Label.new(name))
  end
end

class GenericDatabaseEditor < Gtk::Box
  def initialize(ui, array, name_getter = :name)
    super(:horizontal)
    @builder = ExtraBuilder.new(ui)
    @array = array
    @name_getter = name_getter
    @store = Gtk::ListStore.new(String)
    refresh_store

    @tv = Gtk::TreeView.new(@store)
    @tv.headers_visible = false
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Name", renderer, { :text => 0, })
    @tv.append_column(column)
    @tv.signal_connect("cursor-changed") do
      path = @tv.cursor[0]
      if path
        index = path.indices[0]
        @object = @array[index+1].deep_clone
        @object.class.bind_to(@builder, @object)
        on_object_change
      end
    end

    scroll = Gtk::ScrolledWindow.new(nil, nil)
    scroll.add(@tv)
    scroll.width_request = 150

    self.add(scroll)
    self.add(big_widget(self["widget"], self.screen, 620, 400))
    self.show_all
  end
  def refresh_store
    for object in @array[1..-1]
      item = @store.append
      item.set_value(0, object.public_send(@name_getter))
    end
  end
  def on_object_change
    # Ignore
  end
  def [](widget_name)
    @builder.get_object(widget_name)
  end
end

class DrawableCurve < Gtk::DrawingArea
  def initialize(max)
    super()
    @max = max.to_f
    @color = [0.0, 0.0, 0.0]
    
    self.signal_connect("draw") do |w, cr|
      on_draw(cr)
      cr.destroy
    end
  end
  def on_draw(cr)
    cr.set_source_rgb(*@color)
    height = self.allocated_height
    dx = self.allocated_width / length.to_f

    for index in 0...length
      y = (self[index] * height) / @max
      x = dx * index
      cr.rectangle(x, height-y, dx, y)
    end
    cr.fill
  end
  def max=(max)
    @max = max
    self.queue_draw
  end
  def color=(color)
    @color = color
    self.queue_draw
  end
end

class ListCurve < DrawableCurve
  def initialize(max)
    super
    @list = []
  end
  def on_draw(cr)
    super unless @list.empty?
  end
  def list=(list)
    @list = list
    self.queue_draw
  end
  def length
    @list.length
  end
  def [](index)
    @list[index]
  end
end

class ParameterCurve < DrawableCurve
  def initialize(max, index, r, g, b)
    super(max)
    @index = index
    @parameters = nil
    self.color = [r, g, b]
  end
  def on_draw(cr)
    super if @parameters
  end
  def parameters=(parameters)
    @parameters = parameters
    self.queue_draw
  end
  def length
    99
  end
  def [](level)
    @parameters[@index, level+1]
  end
end

class ActorEditor < GenericDatabaseEditor
  def initialize
    super("actor", $project.actors)
    fill_with_classes(self["class_id_list"])

    # Magic number calculated using 50 base 50 inflation values    
    @exp_graph = ListCurve.new(322987)
    @exp_graph.color = [0.05, 0.57, 0.05] 
    self["exp_graph_container"].add(@exp_graph)
    
    @maxhp_graph = ParameterCurve.new(9999, 0, 0.75, 0.25, 0.50)
    @maxsp_graph = ParameterCurve.new(9999, 1, 0.25, 0.50, 0.75)
    @str_graph = ParameterCurve.new(999, 2, 0.75, 0.50, 0.25)
    @dex_graph = ParameterCurve.new(999, 3, 0.50, 0.75, 0.25)
    @agi_graph = ParameterCurve.new(999, 4, 0.25, 0.75, 0.50)
    @int_graph = ParameterCurve.new(999, 5, 0.50, 0.25, 0.75)
    
    self["maxhp_container"].add(@maxhp_graph)
    self["maxsp_container"].add(@maxsp_graph)
    self["str_container"].add(@str_graph)
    self["dex_container"].add(@dex_graph)
    self["agi_container"].add(@agi_graph)
    self["int_container"].add(@int_graph)
    
    link_refresh("initial_level", "final_level", "exp_basis", "exp_inflation")
  end
  def on_object_change
    refresh
  end
  def refresh
    refresh_parameters
    refresh_exp_graph
  end
  def refresh_parameters
    for graph in [@maxhp_graph, @maxsp_graph,
                  @str_graph, @dex_graph, @agi_graph, @int_graph]
      graph.parameters = @object.parameters
    end
  end
  def refresh_exp_graph
    @exp_list ||= Array.new(100)
    @exp_list[0] = 0
    pow_i = 2.4 + exp_inflation / 100.0
    for i in 1...100
      j = i+1
      if i > final_level || j < initial_level
        @exp_list[i] = 0
      else
        @exp_list[i] = exp_basis * ((j+3) ** pow_i) / (5 ** pow_i)
      end
    end
    @exp_graph.list = @exp_list
  end
  def self.widget_reader(name)
    var = "@#{name}#{rand(1000)}".to_sym
    define_method name do
      value = self.instance_variable_get(var)
      unless value
        value = self[name]
        self.instance_variable_set(var, value)
      end
      value.abstract_value
    end
  end
  widget_reader "initial_level"
  widget_reader "final_level"
  widget_reader "exp_basis"
  widget_reader "exp_inflation"
  def link_refresh(*widgets)
    for widget in widgets
      self[widget].signal_connect("value-changed") do
        refresh
      end
    end
  end
end

