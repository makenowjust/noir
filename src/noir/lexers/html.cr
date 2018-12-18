require "../lexer"
require "./javascript"
require "./css"

class Noir::Lexers::HTML < Noir::Lexer
  tag "html"
  filenames %w(*.html *.htm *.xhtml)
  mimetypes %w(text/html application/xhtml+xml)

  getter js_lexer : JavaScript
  getter css_lexer : CSS

  def initialize
    @js_lexer = JavaScript.new
    @css_lexer = CSS.new
    super
  end

  # :nodoc:
  def reset_js_lexer
    @js_lexer = JavaScript.new
  end

  # :nodoc:
  def reset_css_lexer
    @css_lexer = CSS.new
  end

  state :root do
    rule /[^<&]+/, Text
    rule /&\S*?;/, Name::Entity
    rule /<!DOCTYPE .*?>/im, Comment::Preproc
    rule /<!\[CDATA\[.*?\]\]>/m, Comment::Preproc
    rule /<!--/, Comment, :comment
    rule /<\?.*?\?>/m, Comment::Preproc

    rule /<\s*script\s*/ do |m|
      m.token Name::Tag
      m.lexer.as(HTML).reset_js_lexer
      m.push :script_content
      m.push :tag
    end

    rule /<\s*style\s*/ do |m|
      m.token Name::Tag
      m.lexer.as(HTML).reset_css_lexer
      m.push :style_content
      m.push :tag
    end

    rule /<\//, Name::Tag, :tag_end
    rule /</, Name::Tag, :tag_start

    rule %r(<\s*[a-zA-Z0-9:-]+), Name::Tag, :tag   # opening tags
    rule %r(<\s*/\s*[a-zA-Z0-9:-]+\s*>), Name::Tag # closing tags
  end

  state :tag_end do
    mixin :tag_end_end
    rule /[a-zA-Z0-9:-]+/ do |m|
      m.token Name::Tag
      m.goto :tag_end_end
    end
  end

  state :tag_end_end do
    rule /\s+/, Text
    rule />/, Name::Tag, :pop!
  end

  state :tag_start do
    rule /\s+/, Text

    rule /[a-zA-Z0-9:-]+/ do |m|
      m.token Name::Tag
      m.goto :tag
    end

    rule(//) { |m| m.goto :tag }
  end

  state :comment do
    rule /[^-]+/, Comment
    rule /-->/, Comment, :pop!
    rule /-/, Comment
  end

  state :tag do
    rule /\s+/, Text
    rule /[a-zA-Z0-9_:-]+\s*=\s*/, Name::Attribute, :attr
    rule /[a-zA-Z0-9_:-]+/, Name::Attribute
    rule %r(/?\s*>), Name::Tag, :pop!
  end

  state :attr do
    rule /"/ do |m|
      m.token Str
      m.goto :dq
    end

    rule /'/ do |m|
      m.token Str
      m.goto :sq
    end

    rule /[^\s>]+/, Str, :pop!
  end

  state :dq do
    rule /"/, Str, :pop!
    rule /[^"]+/, Str
  end

  state :sq do
    rule /'/, Str, :pop!
    rule /[^']+/, Str
  end

  state :script_content do
    rule %r([^<]+) do |m|
      m.delegate m.lexer.as(HTML).js_lexer
    end

    rule %r(<\s*/\s*script\s*>), Name::Tag, :pop!

    rule %r(<) do |m|
      m.delegate m.lexer.as(HTML).js_lexer
    end
  end

  state :style_content do
    rule /[^<]+/ do |m|
      m.delegate m.lexer.as(HTML).css_lexer
    end

    rule %r(<\s*/\s*style\s*>), Name::Tag, :pop!

    rule /</ do |m|
      m.delegate m.lexer.as(HTML).css_lexer
    end
  end
end
