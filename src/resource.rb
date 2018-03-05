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
  def self.load(type, name)
    raise("Invalid type #{type} for image.") if subtype(type) != :image
    raise("Empty name. Write a guard instead.") if name.empty?
    @cache[[type, name]] ||= Cairo::ImageSurface.from_png(find(type, name))
  end
  def self.find(type, name)
    res = find_low(type, name)
    until res
      msg = "Resource \"#{name}\" not found. What do you want to do?"
      ask = Gtk::MessageDialog.new(message: msg, buttons_type: :none)
      ask.add_button("Exit Application", 1)
      ask.add_button("Retry", 2)
      
      answer = ask.run
      ask.destroy
      case answer
      when 1
        exit(1)
      when 2
        res = find_low(type, name)
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
    rtp = $project.rtp
    dirs = rtp.empty? ? [$project.dir] : [$project.dir, rtp]
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
