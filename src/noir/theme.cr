require "./themes"
require "./token"

class Noir::Theme
  include Tokens

  class_getter! name : String

  def self.name(@@name)
    Themes.register name, self
  end

  record Color,
    red : UInt8,
    green : UInt8,
    blue : UInt8 do
    def self.parse(rgb)
      return unless rgb.starts_with? "#"
      r = rgb[1..2].to_u8? 16
      g = rgb[3..4].to_u8? 16
      b = rgb[5..6].to_u8? 16
      return unless r && g && b
      Color.new r, g, b
    end

    def to_s(io)
      io << sprintf("#%02x%02x%02x", red, green, blue)
    end
  end

  # :nodoc:
  record Style,
    fore : Color? = nil,
    back : Color? = nil,
    bold : Bool = false,
    italic : Bool = false,
    underline : Bool = false do
    def to_s(io) : Nil
      wrote = false

      if fore
        io << "color: #{fore};"
        wrote = true
      end

      if back
        io << " " if wrote
        io << "background-color: #{back};"
        wrote = true
      end

      if bold
        io << " " if wrote
        io << "font-weight: bold;"
        wrote = true
      end

      if italic
        io << " " if wrote
        io << "font-style: italic;"
        wrote = true
      end

      if underline
        io << " " if wrote
        io << "text-decoration: underline;"
      end
    end
  end

  @@palette = {} of Symbol => Color
  @@styles = {} of Token => Style

  def self.palette(color_name)
    @@palette.fetch(color_name) do
      if (klass = {{@type.superclass}}).responds_to?(:palette)
        klass.palette(color_name)
      else
        # TODO
        raise "error!"
      end
    end
  end

  def self.palette(color_name, color)
    color = Color.parse(color) || raise "error!"
    @@palette[color_name] = color
  end

  def self.style_for(token : Token)
    token.token_chain.each do |t|
      style = style?(t)
      return style if style
    end

    base_style
  end

  class_getter base_style : Style do
    style?(Tokens::Text) || raise("style for Text token must be defined")
  end

  # :nodoc:
  def self.style?(token)
    @@styles.fetch(token) do
      if (klass = {{@type.superclass}}).responds_to?(:style?)
        klass.style?(token)
      else
        nil
      end
    end
  end

  private def self.color(color : Symbol)
    palette(color)
  end

  private def self.color(color : String)
    Color.parse(color) || raise "error!"
  end

  private def self.color(color : Nil)
    nil
  end

  def self.style(*tokens, fore = nil, back = nil, bold = false, italic = false, underline = false)
    style = Style.new(color(fore), color(back), bold, italic, underline)
    tokens.each do |t|
      @@styles[t] = style
    end
  end

  def initialize(@scope = ".highlight")
  end

  def style_for(token)
    self.class.style_for token
  end

  def base_style
    self.class.base_style
  end

  private def style?(token)
    self.class.style? token
  end

  def to_s(io)
    Tokens.each_token do |t|
      if style = style?(t)
        css_selectors(t).join(", ", io) { |s| io << s }
        io << " { "
        style.to_s io
        io << " }"
        io.puts
      end
    end
  end

  private def css_selectors(token)
    sub_tokens = [] of String

    token.each_sub_token do |t|
      next if style?(t)
      sub_tokens.concat css_selectors(t)
    end

    [css_selector(token)].concat sub_tokens
  end

  private def css_selector(token)
    if token == Tokens::Text
      @scope
    else
      "#{@scope} .#{token.short_name}"
    end
  end
end
