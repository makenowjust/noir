require "../theme"

module Noir::Themes
  module Solarized
    macro included
      palette :yellow, "#B58900"
      palette :orange, "#CB4B16"
      palette :red, "#DC322F"
      palette :magenta, "#D33682"
      palette :violet, "#6C71C4"
      palette :blue, "#268BD2"
      palette :cyan, "#2AA198"
      palette :green, "#859900"

      style Text, fore: :base1, back: :base03

      style Keyword, fore: :green
      style Keyword::Constant, fore: :orange
      style Keyword::Reserved, fore: :blue
      style Keyword::Type, fore: :red

      style Name::Attribute, fore: :base1
      style Name::Builtin, fore: :yellow
      style Name::Builtin::Pseudo,
        Name::Class,
        Name::Decorator,
        Name::Function,
        Name::Tag,
        Name::Variable, fore: :blue
      style Name::Constant,
        Name::Entity,
        Name::Exception, fore: :orange

      style Literal::String,
        Literal::String::Single,
        Literal::String::Double,
        Literal::String::Char, fore: :cyan
      style Literal::String::Interpol, fore: :blue
      style Literal::String::Backtick,
        Literal::String::Doc, fore: :base1
      style Literal::String::Escape, fore: :orange
      style Literal::String::Heredoc, fore: :base1
      style Literal::String::Regex, fore: :red
      style Literal::Number, fore: :cyan

      style Operator, fore: :green
      style Punctuation, fore: :orange
      style Comment, fore: :base01
      style Comment::Preproc, Comment::Special, fore: :green

      style Generic::Deleted, fore: :cyan
      style Generic::Emph, italic: true
      style Generic::Error, fore: :red
      style Generic::Heading, fore: :orange
      style Generic::Inserted, fore: :green
      style Generic::Strong, bold: true
      style Generic::Subheading, fore: :orange
    end
  end

  class SolarizedDark < Noir::Theme
    name "solarized-dark"

    palette :base03, "#002B36"
    palette :base02, "#073642"
    palette :base01, "#586E75"
    palette :base00, "#657B83"
    palette :base0, "#839496"
    palette :base1, "#93A1A1"
    palette :base2, "#EEE8D5"
    palette :base3, "#FDF6E3"

    include Solarized
  end

  class SolarizedLight < Noir::Theme
    name "solarized-light"

    palette :base3, "#002B36"
    palette :base2, "#073642"
    palette :base1, "#586E75"
    palette :base0, "#657B83"
    palette :base00, "#839496"
    palette :base01, "#93A1A1"
    palette :base02, "#EEE8D5"
    palette :base03, "#FDF6E3"

    include Solarized
  end
end
