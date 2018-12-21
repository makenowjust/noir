require "../lexer"
class Noir::Lexers::JSON < Noir::Lexer
  tag "json"
  filenames %w(*.json)
  mimetypes %w(application/json application/vnd.api+json application/hal+json)

  state :root do
    rule /\s+/, Text::Whitespace
    rule /"/, Str::Double, :string
    rule /\b(true|false|null)\b/, Keyword::Constant
    rule /[{},:\[\]]/, Punctuation
    rule /-?(0|[1-9]\d*)(\.\d+)?(e[+-]?\d+)?/i, Num
  end

  state :string do
    rule /[^\\"]+/, Str::Double
    rule /\\u[0-9a-fA-F]{4}|\\[\"\\\/bfnrt]/, Str::Escape
    rule /"/, Str::Double, :pop!
  end
end
