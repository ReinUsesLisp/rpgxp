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
require 'filemagic'

module Resource
  AudioMime = ["audio/midi", "audio/ogg", "audio/mp3", "audio/wav", "audio/wma"]
  ImageMime = ["image/png", "image/jpeg"]
  @cache = {}
  @ignores = []
  @always_ignore = false
  def self.load(*key)
    type, name = key
    raise("Invalid type #{type} for image.") if subtype(type) != :image
    raise("Empty name. Write a guard instead.") if name.empty?
    @cache[key] ||= load_resource(find(*key))
  end
  def self.load_resource(resource)
    if resource
      Cairo::ImageSurface.from_png(resource)
    else
      # Return empty surface when resource is nil
      Cairo::ImageSurface.new(1, 1)
    end
  end
  def self.find(type, name)
    res = find_low(type, name)
    key = [type, name]
    if res.nil? && @always_ignore == false && @ignores.member?(key) == false
      msg = "#{type.capitalize} \"#{name}\" not found."
      ask = Gtk::MessageDialog.new(buttons_type: :none, type: :error,
                                   message: msg)
      ask.secondary_text = "What do you want to do?"
      ask.add_button("Exit Application", 1)
      ask.add_button("Retry", 2)
      ask.add_button("Ignore All", 3)
      ignore = ask.add_button("Ignore", 4)
      ignore.style_context.add_class("suggested-action")

      answer = ask.run
      ask.destroy
      case answer
      when 1
	      $app.quit
      when 2
        res = find(type, name)
      when 3
        @always_ignore = true
      when 4
        @ignores.push(key)
      end
    end
    res
  end
  def self.find_low(type, name)
    path_list(type).find do |path|
      name == File.basename(path, ".*")
    end
  end
  def self.list(type)
    path_list(type).map { |path| File.basename(path, ".*") }.uniq.sort
  end
  def self.path_list(type)
    magic = FileMagic.new(FileMagic::MAGIC_MIME)
    dirs = [$project.dir] + $project.config.rtps
    resources = []
    for dir in dirs
      for file in Dir["#{dir}/#{dir(type)}/*"]
        mime = magic.file(file).split(";")[0]
        case subtype(type)
        when :audio
          resources.push(file) if AudioMime.member?(mime)
        when :image
          resources.push(file) if ImageMime.member?(mime)
        end
      end
    end
    resources.uniq
  end
  private
  def self.subtype(type)
    if [:bgm, :bgs, :me, :se].member?(type)
      :audio
    elsif [:animation, :autotile, :battleback, :battler, :character, :fog,
           :icon, :panorama, :tileset, :title, :transition,
           :windowskin].member?(type)
      :image
    else
      nil
    end
  end
  def self.dir(type)
    case type
    when :animation; "Graphics/Animations"
    when :autotile; "Graphics/Autotiles"
    when :battleback; "Graphics/Battlebacks"
    when :battler; "Graphics/Battlers"
    when :character; "Graphics/Characters"
    when :fog; "Graphics/Fogs"
    when :icon; "Graphics/Icons"
    when :panorama; "Graphics/Panoramas"
    when :tileset; "Graphics/Tilesets"
    when :title; "Graphics/Titles"
    when :transition; "Graphics/Transitions"
    when :windowskin; "Graphics/Windowskins"
    when :bgm; "Audio/BGM"
    when :bgs; "Audio/BGS"
    when :me; "Audio/ME"
    when :se; "Audio/SE"
    else; raise
    end
  end
end
