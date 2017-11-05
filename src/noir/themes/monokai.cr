require "../theme"

class Noir::Themes::Monokai < Noir::Theme
  name "monokai"

  palette :black, "#000000"
  palette :bright_green, "#a6e22e"
  palette :bright_pink, "#f92672"
  palette :carmine, "#960050"
  palette :dark, "#49483e"
  palette :dark_grey, "#888888"
  palette :dark_red, "#aa0000"
  palette :dimgrey, "#75715e"
  palette :dimgreen, "#324932"
  palette :dimred, "#493131"
  palette :emperor, "#555555"
  palette :grey, "#999999"
  palette :light_grey, "#aaaaaa"
  palette :light_violet, "#ae81ff"
  palette :soft_cyan, "#66d9ef"
  palette :soft_yellow, "#e6db74"
  palette :very_dark, "#1e0010"
  palette :whitish, "#f8f8f2"
  palette :orange, "#f6aa11"
  palette :white, "#ffffff"

  style Comment,
    Comment::Multiline,
    Comment::Single, fore: :dimgrey, italic: true
  style Comment::Preproc, fore: :dimgrey, bold: true
  style Comment::Special, fore: :dimgrey, italic: true, bold: true
  style Error, fore: :carmine, back: :very_dark
  style Generic::Inserted, fore: :white, back: :dimgreen
  style Generic::Deleted, fore: :white, back: :dimred
  style Generic::Emph, fore: :black, italic: true
  style Generic::Error,
    Generic::Traceback, fore: :dark_red
  style Generic::Heading, fore: :grey
  style Generic::Output, fore: :dark_grey
  style Generic::Prompt, fore: :emperor
  style Generic::Strong, bold: true
  style Generic::Subheading, fore: :light_grey
  style Keyword,
    Keyword::Constant,
    Keyword::Declaration,
    Keyword::Pseudo,
    Keyword::Reserved,
    Keyword::Type, fore: :soft_cyan, bold: true
  style Keyword::Namespace,
    Operator::Word,
    Operator, fore: :bright_pink, bold: true
  style Literal::Number::Float,
    Literal::Number::Hex,
    Literal::Number::Integer::Long,
    Literal::Number::Integer,
    Literal::Number::Oct,
    Literal::Number,
    Literal::String::Escape, fore: :light_violet
  style Literal::String::Backtick,
    Literal::String::Char,
    Literal::String::Doc,
    Literal::String::Double,
    Literal::String::Heredoc,
    Literal::String::Interpol,
    Literal::String::Other,
    Literal::String::Regex,
    Literal::String::Single,
    Literal::String::Symbol,
    Literal::String, fore: :soft_yellow
  style Name::Attribute, fore: :bright_green
  style Name::Class,
    Name::Decorator,
    Name::Exception,
    Name::Function, fore: :bright_green, bold: true
  style Name::Constant, fore: :soft_cyan
  style Name::Builtin::Pseudo,
    Name::Builtin,
    Name::Entity,
    Name::Namespace,
    Name::Variable::Class,
    Name::Variable::Global,
    Name::Variable::Instance,
    Name::Variable,
    Text::Whitespace, fore: :whitish
  style Name::Label, fore: :whitish, bold: true
  style Name::Tag, fore: :bright_pink
  style Text, fore: :whitish, back: :dark
end
