require "../lexer"

class Noir::Lexers::YAML < Noir::Lexer
  tag "yaml"
  filenames %w(*.yaml *.yml)
  mimetypes %w(text/x-yaml)
  property block_scalar_indent : (Nil|Int32)

  @debug: Bool
  @indent_stack : Array(Int32)
  @next_indent : Int32

  def initialize
    @debug = true
    @indent_stack = [0]
    @next_indent = 0
    @block_scalar_indent = nil
    super
  end

  SPECIAL_VALUES = Regex.union(%w(true false null))

  # NB: Tabs are forbidden in YAML, which is why you see things
  # like /[ ]+/.

  # reset the indentation levels
  def reset_indent
    @indent_stack = [0]
    @next_indent = 0
    @block_scalar_indent = nil
  end

  def indent : Int32
    raise "empty indent stack!" if stack.empty?
    @indent_stack.last
  end

  def dedent?(level : Int32)
    level < self.indent
  end

  # Save a possible indentation level
  def save_indent(match : String)
    @next_indent = match.size
    puts "    yaml: indent: #{self.indent}/#@next_indent: #{@next_indent}" if @debug
    puts "    yaml: popping indent stack - before: #@indent_stack #{@indent_stack}" if @debug
    if dedent?(@next_indent)
      while dedent?(@next_indent)
        @indent_stack.pop
      end
      puts "    yaml: popping indent stack - after: #@indent_stack" if @debug
      puts "    yaml: indent: #{self.indent}/#@next_indent" if @debug

      # dedenting to a state not previously indented to is an error
      [match[0...self.indent], match[self.indent..-1]]
    else
      [match, ""]
    end
  end

  def continue_indent(match)
    puts "    yaml: continue_indent" if @debug
    @next_indent += match.size
  end

  def set_indent(match, opts={} of Int32 => Bool)
    if indent < @next_indent
      puts "    yaml: indenting #{indent}/#{@next_indent}" if @debug
      @indent_stack << @next_indent
    end

    @next_indent += match.size unless opts[:implicit]?
  end

  plain_scalar_start = /[^ \t\n\r\f\v?:,\[\]{}#&*!\|>'"%@`]/

  state :basic do
    # https://github.com/crystal-lang/crystal/issues/8062
    rule /#.*?$/m, Comment::Single
  end

  state :root do
    mixin :basic
    rule /\n+/, Text
    #
    # trailing or pre-comment whitespace
    rule /[ ]+(?=#|$)/m, Text

    rule /^%YAML\b/m do |m|
      m.token Name::Tag
      m.lexer.as(YAML).reset_indent
      m.push :yaml_directive
    end

    rule /^%TAG\b/m do |m|
      m.token Name::Tag
      m.lexer.as(YAML).reset_indent
      m.push :tag_directive
    end

    # doc-start and doc-end indicators
    rule /^(?:---|\.\.\.)(?= |$)/m do |m|
      m.token Name::Namespace
      m.lexer.as(YAML).reset_indent
      m.push :block_line
    end

    # indentation spaces
    rule /[ ]*(?!\s|\n|$)/m do |m|
      text, err = m.lexer.as(YAML).save_indent(m[0])
      #text, err = save_indent(m[0])
      m.token Text, text
      m.token Error, err
      m.push :block_line; m.push :indentation
    end

  end


  state :indentation do
    rule /\s*?\n/ do |m|
      m.token Text
      m.pop! 2
    end

    # whitespace preceding block collection indicators
    rule /[ ]+(?=[-:?](?:[ ]|$))/m do |m|
      m.token Text
      m.lexer.as(YAML).continue_indent(m[0])
    end

    # block collection indicators
    rule /[?:-](?=[ ]|$)/m do |m|
      m.lexer.as(YAML).set_indent(m[0])
      m.token Punctuation::Indicator
    end

    # the beginning of a block line
    rule /[ ]*/ do |m|
      m.token Text
      m.lexer.as(YAML).continue_indent(m[0])
      m.pop!
    end
  end


  # indented line in the block context
  state :block_line do
    # line end
    rule /[ ]*(?=#|$|\n)/m do |m|
        m.token Text
        m.pop!
    end
    rule /[ ]+/ do |m|
      m.token Text
    end

    # tags, anchors, and aliases
    mixin :descriptors
    # block collections and scalars
    mixin :block_nodes
    # flow collections and quoed scalars
    mixin :flow_nodes

    # a plain scalar
    rule /(?=#{plain_scalar_start}|[?:-][^ \t\n\r\f\v])/ do |m|
      m.token Name::Variable
      m.push :plain_scalar_in_block_context
    end
  end


  state :descriptors do
    # a full-form tag
    rule /!<[0-9A-Za-z;\/?:@&=+$,_.!~*'()\[\]%-]+>/, Keyword::Type

    # a tag in the form '!', '!suffix' or '!handle!suffix'
    rule %r(
      (?:![\w-]+)? # handle
      !(?:[\w;/?:@&=+$,.!~*\'()\[\]%-]*) # suffix
    )x, Keyword::Type

    # an anchor
    rule /&[\p{L}\p{Nl}\p{Nd}_-]+/, Name::Label

    # an alias
    rule /\*[\p{L}\p{Nl}\p{Nd}_-]+/, Name::Variable
  end

  state :block_nodes do
    # implicit key
    rule /([^#,:?\[\]{}"'\n]+)(:)(?=\s|$)/m do |m|
      m.groups Name::Attribute, Punctuation::Indicator
      m.lexer.as(YAML).set_indent m[0], { :implicit => true }
    end

    # literal and folded scalars
    rule /[\|>][+-]?/ do |m|
      m.token Punctuation::Indicator
      m.push :block_scalar_content
      m.push :block_scalar_header
    end
  end

  state :flow_nodes do
    rule /\[/, Punctuation::Indicator, :flow_sequence
    rule /\{/, Punctuation::Indicator, :flow_mapping
    rule /'/, Str::Single, :single_quoted_scalar
    rule /"/, Str::Double, :double_quoted_scalar
  end

  state :flow_collection do
    rule /\s+/, Text
    mixin :basic
    rule /[?:,]/, Punctuation::Indicator
    mixin :descriptors
    mixin :flow_nodes

    rule /(?=#{plain_scalar_start})/ do |m|
      m.push :plain_scalar_in_flow_context
    end
  end

  state :flow_sequence do
    rule /\]/, Punctuation::Indicator, :pop!
    mixin :flow_collection
  end

  state :flow_mapping do
    rule /\}/, Punctuation::Indicator, :pop!
    mixin :flow_collection
  end

  state :block_scalar_content do
    rule /\n+/, Text

    # empty lines never dedent, but they might be part of the scalar.
    rule /^[ ]+$/m do |m|
      text = m[0]
      indent_size = text.size

      indent_mark = m.lexer.as(YAML).block_scalar_indent || indent_size

      m.token Text, text[0...indent_mark]
      m.token Name::Constant, text[indent_mark..-1]
    end

    # TODO: ^ doesn't actually seem to affect the match at all.
    # Find a way to work around this limitation.
    rule /^[ ]*/m do |m|
      m.token Text

      indent_size = m[0].size

      dedent_level = m.lexer.as(YAML).block_scalar_indent || m.lexer.as(YAML).indent
      m.lexer.as(YAML).block_scalar_indent ||= indent_size

      if indent_size < dedent_level
        m.lexer.as(YAML).save_indent m[0]
        m.pop!
        m.push :indentation
      end
    end

    rule /[^\n\r\f\v]+/, Str
  end

  state :block_scalar_header do
    # optional indentation indicator and chomping flag, in either order
    rule %r(
      (
        ([1-9])[+-]? | [+-]?([1-9])?
      )(?=[ ]|$)
    )xm do |m|
      m.lexer.as(YAML).block_scalar_indent = nil
      m.goto :ignored_line
      next if m[0].empty?

      increment = m[1] || m[2]
      if increment
        m.lexer.as(YAML).block_scalar_indent = m.lexer.as(YAML).indent + increment.to_i
      end

      m.token Punctuation::Indicator
    end
  end

  state :ignored_line do
    mixin :basic
    rule /[ ]+/, Text
    rule /\n/, Text, :pop!
  end

  state :quoted_scalar_whitespaces do
    # leading and trailing whitespace is ignored
    rule /^[ ]+/m, Text
    rule /[ ]+$/m, Text

    rule /\n+/, Text

    rule /[ ]+/, Name::Variable
  end

  state :single_quoted_scalar do
    mixin :quoted_scalar_whitespaces
    rule /\\'/, Str::Escape
    rule /'/, Str, :pop!
    rule /[^\s']+/, Str
  end

  state :double_quoted_scalar do
    rule /"/, Str, :pop!
    mixin :quoted_scalar_whitespaces
    # escapes
    rule /\\[0abt\tn\nvfre "\\N_LP]/, Str::Escape
    rule /\\(?:x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,
      Str::Escape
    rule /[^ \t\n\r\f\v"\\]+/, Str
  end

  state :plain_scalar_in_block_context_new_line do
    # empty lines
    rule /^[ ]+\n/m, Text
    # line breaks
    rule /\n+/, Text
    # document start and document end indicators
    rule /^(?=---|\.\.\.)/m do |m|
      m.pop! 3
    end

    # indentation spaces (we may leave the block line state here)
    # dedent detection
    rule /^[ ]*/m do |m|
      m.token Text
      m.pop!

      indent_size = m[0].size

      # dedent = end of scalar
      if indent_size <= m.lexer.as(YAML).indent
        m.pop!
        m.lexer.as(YAML).save_indent(m[0])
        m.push :indentation
      end
    end
  end

  state :plain_scalar_in_block_context do
    # the : indicator ends a scalar
    rule /[ ]*(?=:[ \n]|:$)/m, Text, :pop!
    rule /[ ]*:\S+/, Str
    rule /[ ]+(?=#)/, Text, :pop!
    rule /[ ]+$/m, Text
    # check for new documents or dedents at the new line
    rule /\n+/ do |m|
      m.token Text
      m.push :plain_scalar_in_block_context_new_line
    end

    rule /[ ]+/, Str
    rule SPECIAL_VALUES, Name::Constant
    rule /\d+(?:\.\d+)?(?=(\r?\n)| +#)/, Literal::Number, :pop!

    # regular non-whitespace characters
    rule /[^\s:]+/, Str
  end

  state :plain_scalar_in_flow_context do
    rule /[ ]*(?=[,:?\[\]{}])/, Text, :pop!
    rule /[ ]+(?=#)/, Text, :pop!
    rule /^[ ]+/, Text
    rule /[ ]+$/m, Text
    rule /\n+/, Text
    rule /[ ]+/, Name::Variable
    rule /[^\s,:?\[\]{}]+/, Name::Variable
  end

  state :yaml_directive do
    rule /([ ]+)(\d+\.\d+)/ do |m|
      m.groups Text, Num
      m.goto :ignored_line
    end
  end


  state :tag_directive do
    rule %r(
      ([ ]+)(!|![\w-]*!) # prefix
      ([ ]+)(!|!?[\w;/?:@&=+$,.!~*'()\[\]%-]+) # tag handle
    )x do |m|
      m.groups Text, Keyword::Type, Text, Keyword::Type
      m.goto :ignored_line
    end
  end

end
