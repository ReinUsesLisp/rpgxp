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
require_relative 'drawable_curve.rb'

class DatabaseWindow < Gtk::Window
  def initialize
    super()
    self.title = "Database"
    
    buttons = Gtk::ButtonBox.new(:horizontal)
    buttons.layout = :end
    buttons.spacing = 4
    
    cancel = Gtk::Button.new(stock_id: Gtk::Stock::CANCEL)
    cancel.signal_connect("clicked") { on_cancel }
    
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
    notebook.signal_connect("switch-page") do |w, new_page|
      if @page
        @page.apply_object_changes
        if !(@page.data == @stored)
          msg = "Do you want to keep changes?"
          ask = Gtk::MessageDialog.new(message: msg, buttons_type: :none,
                                       parent: self, flags: :modal)
          ask.add_button("Discard Changes", :cancel)
          ok = ask.add_button("Keep Changes", :ok)
          ok.style_context.add_class("suggested-action")
          if ask.run == :ok
            @page.apply_changes
          else
            @page.reload_data
          end
          ask.destroy
        end
      end
      # Set new values
      @page = new_page
      @page.reload_object
      @stored = new_page.data.deep_clone
    end

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
    vbox.spacing = 4
    vbox.add(notebook)
    vbox.add(buttons)
    self.add(vbox)
    self.show_all
  end
  def not_implemented(notebook, name)
    label = Gtk::Label.new("This has not been implemented yet")
    class << label
      def data
        nil
      end
      def apply_object_changes; end
      def reload_data; end
      def reload_object; end
    end
    notebook.append_page(label, Gtk::Label.new(name))
  end
  def on_cancel
    self.destroy
  end
end

class GenericDatabaseEditor < Gtk::Box
  def initialize(ui, array, name_getter = :name)
    super(:horizontal)
    @builder = ExtraBuilder.new(ui)
    @array_src = array
    @name_getter = name_getter
    @store = Gtk::ListStore.new(String)
    reload_data
    refresh_store

    @tv = Gtk::TreeView.new(@store)
    @tv.headers_visible = false
    renderer = Gtk::CellRendererText.new
    column = Gtk::TreeViewColumn.new("Name", renderer, { :text => 0, })
    @tv.append_column(column)
    @tv.signal_connect("cursor-changed") do
      reload_object
    end

    scroll = Gtk::ScrolledWindow.new(nil, nil)
    scroll.add(@tv)
    scroll.width_request = 150

    self.add(scroll)
    self.add(big_widget(self["widget"], self.screen, 620, 400))
    self.show_all
  end
  def reload_data
    @array = @array_src.deep_clone
  end
  def reload_object
    path = @tv.cursor[0]
    if path
      apply_object_changes
      @index = path.indices[0] + 1
      @object = @array[@index].deep_clone
      @object.class.bind_to(@builder, @object)
      on_object_change
    end
  end
  def refresh_store
    @store.clear
    for object in @array[1..-1]
      item = @store.append
      item.set_value(0, object.public_send(@name_getter))
    end
  end
  def apply_object_changes
    if @object
      new = @object.class.extract_from(@builder)
      on_extract(new)
      @array[@index] = new
    end
  end
  def apply_changes
    raise "Apply changes not implemented"
  end
  def data
    @array
  end
  def on_object_change
  end
  def on_extract(new)
  end
  def [](widget_name)
    @builder.get_object(widget_name)
  end
end

class ActorEditor < GenericDatabaseEditor
  def apply_changes
    $project.actors = @array.deep_clone
  end
  def initialize
    super("actor", $project.actors)
    fill_with_classes(self["class_id_list"])
    fill_with_weapons(self["weapon_id_list"])
    fill_with_armors(self["armor_id_list"])
    
    # Magic number calculated using 50 base 50 inflation values
    max_exp = 322987
    @exp_graph = ListCurve.new(max_exp)
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
    super
    refresh
  end
  def on_extract(new)
    super
    new.character_name = @object.character_name
    new.parameters = @object.parameters
    new.battler_hue = @object.battler_hue
    new.character_hue = @object.character_hue
    new.id = @object.id
    new.battler_name = @object.battler_name
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
    var = "@__#{name}".to_sym
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
