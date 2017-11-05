require "./themes"

module Noir::Themes
  THEMES = {} of String => Theme.class

  def self.register(name : String, theme) : Nil
    THEMES[name] = theme
  end

  def self.find(name : String, scope = ".highlight") : Theme?
    THEMES[name]?.try &.new(scope: scope)
  end
end
