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
require 'gettext' # used to manually translate Gtk::Builder

class WidgetLink
  attr_reader :widget, :id
  def initialize(widget, id, getter, setter)
    id = widget unless id
    @widget, @id, @getter, @setter = widget, id, getter, setter
  end
  def object_get(object)
    get_value(object.instance_variable_get("@#{@id}"))
  end
  def object_set(object, value)
    object.instance_variable_set("@#{@id}", set_value(value))
  end
  def array_get(array)
    get_value(array[@id])
  end
  def array_set(array, value)
    array[@id] = set_value(value)
  end
  private
  def get_value(value)
    @getter ? method(@getter).call(value) : value
  end
  def set_value(value)
    @setter ? method(@setter).call(value) : value
  end
end

module WidgetLinkTemplate
  @@links = {}
  def link(widget, *args)
    @@links[self] ||= []
    variable, getter, setter = []
    case args.length
    when 1
      variable = args.first
    when 2
      getter, setter = args
    when 3
      variable, getter, setter = args
    end
    link = WidgetLink.new(widget, variable, getter, setter)
    @@links[self].push(link)
    link
  end
  def alink(*args)
    link = link(*args)
    attr_accessor(link.id)
  end
end

module WidgetLinkArray
  include WidgetLinkTemplate
  def bind_to(builder, array)
    for link in @@links[self]
      if link.widget.is_a?(Array)
        index = link.array_get(array)
        widget_id = link.widget[index]
        builder.get_object(widget_id).abstract_value = true
      else
        builder.get_object(link.widget).abstract_value = link.array_get(array)
      end
    end
  end
  def extract_from(builder)
    array = Array.new(@@links[self].map { |link| link.id }.max)
    for link in @@links[self]
      if link.widget.is_a?(Array)
        value = link.widget.index do |widget|
          builder.get_object(widget).abstract_value
        end
        raise unless value
      else
        value = builder.get_object(link.widget).abstract_value
      end
      link.array_set(array, value)
    end
    array.delete(nil) # remove extras
    array
  end
end

module WidgetLinkObject
  include WidgetLinkTemplate
  def bind_to(builder, object)
    for link in @@links[self]
      if link.widget.is_a?(Array)
        index = link.object_get(object)
        widget_id = link.widget[index]
        builder.get_object(widget_id).abstract_value = true
      else
        builder.get_object(link.widget).abstract_value = link.object_get(object)
      end
    end
  end
  def extract_from(builder)
    object = self.allocate
    for link in @@links[self]
      if link.widget.is_a?(Array)
        value = link.widget.index do |widget|
          builder.get_object(widget).abstract_value
        end
        raise unless value
      else
        value = builder.get_object(link.widget).abstract_value
      end
      link.object_set(object, value)
    end
    object
  end
end

class ExtraBuilder < Gtk::Builder
  TRANSLATABLE = 'translatable="yes"'
  def initialize(path)
    super()
    data = IO.read("#{$DATA_DIR}/ui/#{path}.glade")

    while (floor = data.index(TRANSLATABLE))
      data[floor...floor+TRANSLATABLE.length] = ""

      section = data[floor..-1]
      start = floor + section.index(">") + 1
      finish = floor + section.index("<")
      data[start...finish] = GetText._(data[start...finish])
    end
    
    self.add_from_string(data)
  end
  def get_object(name)
    object = super(name)
    if object
      object
    else
      raise("Object \"#{name}\" not found in builder")
    end
  end
end

class Gtk::Entry
  def abstract_value=(value)
    self.text = value
  end
  def abstract_value
    self.text
  end
end

class Gtk::CheckButton
  def abstract_value=(value)
    self.active = value
  end
  def abstract_value
    self.active?
  end
end

class Gtk::ComboBox
  def abstract_value=(value)
    self.active = value
  end
  def abstract_value
    self.active
  end
end

class Gtk::Adjustment
  def abstract_value=(value)
    self.value = value
  end
  def abstract_value
    self.value
  end
end
