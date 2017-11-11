require "../lexer"

class Noir::Lexers::JavaScript < Noir::Lexer
  tag "javascript"
  aliases %w(js)
  filenames %w(*.js)
  mimetypes %w(
    application/javascript application/x-javascript
    text/javascript text/x-javascript
  )

  state :multiline_comment do
    rule %r([*]/), Comment::Multiline, :pop!
    rule %r([^*/]+), Comment::Multiline
    rule %r([*/]), Comment::Multiline
  end

  state :comments_and_whitespace do
    rule /\s+/, Text
    rule /<!--/, Comment
    rule %r(//.*?$)m, Comment::Single
    rule %r(/[*]), Comment::Multiline, :multiline_comment
  end

  state :expr_start do
    mixin :comments_and_whitespace

    rule %r(/) do |m|
      m.token Str::Regex
      m.goto :regex
    end

    rule /[{]/ do |m|
      m.token Punctuation
      m.goto :object
    end

    rule //, Text, :pop!
  end

  state :regex do
    rule %r(/) do |m|
      m.token Str::Regex
      m.goto :regex_end
    end

    rule %r([^/]\n), Error, :pop!

    rule /\n/, Error, :pop!
    rule /\[\^/, Str::Escape, :regex_group
    rule /\[/, Str::Escape, :regex_group
    rule /\\./, Str::Escape
    rule %r{[(][?][:=<!]}, Str::Escape
    rule /[{][\d,]+[}]/, Str::Escape
    rule /[()?]/, Str::Escape
    rule /./, Str::Regex
  end

  state :regex_end do
    rule /[gim]+/, Str::Regex, :pop!
    rule //, &.pop!
  end

  state :regex_group do
    # specially highlight / in a group to indicate that it doesn't
    # close the regex
    rule /\//, Str::Escape

    rule %r([^/]\n) do |m|
      m.token Error
      m.pop! 2
    end

    rule /\]/, Str::Escape, :pop!
    rule /\\./, Str::Escape
    rule /./, Str::Regex
  end

  state :bad_regex do
    rule /[^\n]+/, Error, :pop!
  end

  KEYWORDS = Set.new %w(
    for in of while do break return continue switch case default
    if else throw try catch finally new delete typeof instanceof
    void this yield import export from as async super this
  )

  DECLARATIONS = Set.new %w(
    var let const with function class
    extends constructor get set
  )

  RESERVED = Set.new %w(
    abstract boolean byte char debugger double enum
    final float goto implements int interface
    long native package private protected public short static
    synchronized throws transient volatile
    eval arguments await
  )

  CONSTANTS = Set.new %w(true false null NaN Infinity undefined)

  BUILTINS = Set.new %w(
    Array Boolean Date Error Function Math netscape
    Number Object Packages RegExp String sun decodeURI
    decodeURIComponent encodeURI encodeURIComponent
    Error eval isFinite isNaN parseFloat parseInt
    document window navigator self global
    Promise Set Map WeakSet WeakMap Symbol Proxy Reflect
    Int8Array Uint8Array Uint8ClampedArray
    Int16Array Uint16Array Uint16ClampedArray
    Int32Array Uint32Array Uint32ClampedArray
    Float32Array Float64Array DataView ArrayBuffer
  )

  ID_REGEX = /[a-z_$][a-z0-9_$]*/i

  state :root do
    rule /\A\s*#!.*?\n/m, Comment::Preproc, :statement
    rule %r((?<=\n)(?=\s|/|<!--)), Text, :expr_start
    mixin :comments_and_whitespace
    rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | ===
    | !== )x,
      Operator, :expr_start
    rule %r([-<>+*%&|\^/!=]=?), Operator, :expr_start
    rule /[(\[,]/, Punctuation, :expr_start
    rule(/;/, Punctuation, :statement)
    rule /[)\].]/, Punctuation

    rule /`/ do |m|
      m.token Str::Double
      m.push :template_string
    end

    rule /[?]/ do |m|
      m.token Punctuation
      m.push :ternary
      m.push :expr_start
    end

    rule /(\@)(\w+)?/ do |m|
      m.groups Punctuation, Name::Decorator
      m.push :expr_start
    end

    rule /[{}]/, Punctuation, :statement

    rule ID_REGEX do |m|
      if KEYWORDS.includes? m[0]
        m.token Keyword
        m.push :expr_start
      elsif DECLARATIONS.includes? m[0]
        m.token Keyword::Declaration
        m.push :expr_start
      elsif RESERVED.includes? m[0]
        m.token Keyword::Reserved
      elsif CONSTANTS.includes? m[0]
        m.token Keyword::Constant
      elsif BUILTINS.includes? m[0]
        m.token Name::Builtin
      else
        m.token Name::Other
      end
    end

    rule /[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/, Num::Float
    rule /0x[0-9a-fA-F]+/i, Num::Hex
    rule /0o[0-7][0-7_]*/i, Num::Oct
    rule /0b[01][01_]*/i, Num::Bin
    rule /[0-9]+/, Num::Integer

    rule /"/, Str::Double, :dq
    rule /'/, Str::Single, :sq
    rule /:/, Punctuation
  end

  state :dq do
    rule /[^\\"]+/, Str::Double
    rule /\\"/, Str::Escape
    rule /"/, Str::Double, :pop!
  end

  state :sq do
    rule /[^\\']+/, Str::Single
    rule /\\'/, Str::Escape
    rule /'/, Str::Single, :pop!
  end

  # braced parts that aren't object literals
  state :statement do
    rule /case\b/ do |m|
      m.token Keyword
      m.goto :expr_start
    end

    rule /(#{ID_REGEX})(\s*)(:)/ do |m|
      m.groups Name::Label, Text, Punctuation
    end

    rule /[{}]/, Punctuation

    mixin :expr_start
  end

  # object literals
  state :object do
    mixin :comments_and_whitespace

    rule /[{]/ do |m|
      m.token Punctuation
      m.push
    end

    rule /[}]/ do |m|
      m.token Punctuation
      m.goto :statement
    end

    rule /(#{ID_REGEX})(\s*)(:)/ do |m|
      m.groups Name::Attribute, Text, Punctuation
      m.push :expr_start
    end

    rule /:/, Punctuation
    mixin :root
  end

  # ternary expressions, where <id>: is not a label!
  state :ternary do
    rule /:/ do |m|
      m.token Punctuation
      m.goto :expr_start
    end

    mixin :root
  end

  # template strings
  state :template_string do
    rule /\${/, Str::Interpol, :template_string_expr
    rule /`/, Str::Double, :pop!
    rule /(\\\\|\\[\$`]|[^\$`]|\$(?!{))*/, Str::Double
  end

  state :template_string_expr do
    rule /}/, Str::Interpol, :pop!
    mixin :root
  end
end
