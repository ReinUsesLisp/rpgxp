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
require_relative 'resource.rb'

# TODO move somewhere else
# https://stackoverflow.com/questions/8206523/how-to-create-a-deep-copy-of-an-object-in-ruby
class Object
  def deep_clone
    # efficient, yay!
    Marshal.load(Marshal.dump(self))
  end
end

class DialogEditorTemplate < Gtk::Dialog
  def initialize(object, builder, title, parent, klass = nil)
    super(:title => title, :parent => parent, :flags => :modal)
    self.add_button(Gtk::Stock::CANCEL, :cancel)
    ok = self.add_button(Gtk::Stock::OK, :ok)
    #ok.style_context.add_class("suggested-action")

    @builder = ExtraBuilder.new(builder)
    add_builder
    @builder.connect_signals { |handler| method("on_#{handler}") }

    @original = object.deep_clone
    @klass = klass || object.class

    if !object.is_a?(Array) || (object.is_a?(Array) && !object.empty?)
      bind(object)
    end
  end
  def edit
    self.show_all
    if -5 == self.run
      object = extract
      @canceled = false
    else
      object = @original
      @canceled = true
    end
    self.destroy
    object
  end
  def accepted?
    !canceled?
  end
  def canceled?
    @canceled
  end
  protected
  def extract
    @klass.extract_from(@builder)
  end
  def bind(object)
    @klass.bind_to(@builder, object)
  end
  def add_builder
    self.child.add(@builder.get_object("widget"))
  end
end

def big_widget(widget, screen, width = nil, height = nil)
  if screen.height < 800
    scrolled = Gtk::ScrolledWindow.new
    scrolled.add_with_viewport(widget)
    scrolled.vscrollbar_policy = :automatic
    scrolled.hscrollbar_policy = :automatic
    scrolled.width_request = width if width
    scrolled.height_request = height if height
    scrolled
  else
    widget
  end
end

class DialogImageChooser < DialogEditorTemplate
  def initialize(type, *args)
    @resources = Resource.list(type)
    super(*args)
  end
  def add_builder
    @list = @builder.get_object("resources")
    for resource in @resources
      @list.append.set_value(0, resource)
    end
    super
  end
end

class Cairo::Context
  def draw_selection_square(x, y, width, height)
    self.set_source_rgb(0.0, 0.0, 0.0)
    self.line_width = 4
    self.rectangle(x+2, y+2, width-4, height-4)
    self.stroke
    self.set_source_rgb(1.0, 1.0, 1.0)
    self.line_width = 2
    self.rectangle(x+2, y+2, width-4, height-4)
    self.stroke
  end
  def draw_selection(size_x, size_y, x, y, width = 1, height = 1)
    draw_selection_square(x*size_x, y*size_y, width*size_x, height*size_y)
  end
end

class ExtraKeyFile < GLib::KeyFile
  def initialize(file = nil)
    super()
    if file && File.exists?(file)
      data = IO.read(file)
      data.gsub!("\r\n", "\n")
      self.load_from_data(data)
    end
  end
  def self.define_getter(function)
    define_method(function) do |section, key, default = nil|
      if self.has_group?(section) && self.has_key?(section, key)
        super(section, key)
      else
        default
      end
    end
  end
  define_getter :get_value
  define_getter :get_string
  define_getter :get_integer
  define_getter :get_integer_list
end

