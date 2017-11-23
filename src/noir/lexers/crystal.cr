require "../lexer"

class Noir::Lexers::Crystal < Noir::Lexer
  tag "crystal"
  aliases %w(cr)
  filenames %w(*.cr)
  mimetypes %w(text/x-crystal)

  KEYWORDS = Set.new %w(
    abstract as as? asm begin break case
    do else elsif end ensure extend for
    if in include instance_sizeof is_a?
    next nil? of out pointerof private protected require
    rescue responds_to? return select sizeof struct super
    then typeof undef union uninitialized unless until
    when while with yield
  )

  CONSTANTS = Set.new %w(
    true false nil self
  )

  # https://crystal-lang.org/api/0.23.1/toplevel.html
  BUILTINS = Set.new %w(
    abort at_exit caller delay exit fork future gets lazy loop
    p print printf puts raise rand read_line sleep spawn sprintf
    system
    debugger parallel pp
    assert
  )

  # https://crystal-lang.org/api/0.23.1/Object.html
  BUILTIN_MACROS = Set.new %w(
    record
    class_getter class_getter? class_getter!
    class_setter class_setter? class_setter?
    class_property class_property? class_property!
    def_clone def_equals def_hash def_equals_and_hash
    delegate forward_missing_to
    getter getter? getter!
    setter setter? setter!
    property property? property!
  )

  BUILTIN_CLASSES = Set.new %w(
    ArgumentError Array Atomic Bool Box Bytes Channnel Char Class
    Crystal Deque Dir Enum Enumerable Errno Exception Fiber File
    Float Float32 Float64 GC Hash Indexable IndexError Int Int8 Int16
    Int32 Int64 Int128 InvalidByteSequenceError IO Iterable Iterator
    KeyError Math Mutex NamedTuple Nil Number Object PartialComparable
    Pointer PrettyPrinter Proc Process Random Range Reference Reflect
    Regex SecureRandom Set Signal Slice StaticArray String Struct Symbol
    System Tuple TypeCastError UInt8 UInt16 UInt64 UInt128 Unicode Union
    Value WeakRef
  )

  BUILTIN_CONSTANTS = Set.new %w(
    ARGF ARGV PROGRAM_NAME STDIN STDOUT STDERR
  )

  ID_REGEX = /[a-z_]\w*[!?]?/

  state :root do
    rule /\n/, Text, :follow_literal
    rule /[ \r\t]+/m, Text
    rule /#.*?$/m, Comment::Single, :follow_literal

    # names and keywords
    rule /(module|lib)(\s+)([A-Z]\w*(?:::[A-Z]\w*)*)/, &.groups(Keyword, Text, Name::Namespace)
    rule /(def|fun|macro)(\s+)((?:[A-Z]\w*::)*)/ do |m|
      m.groups(Keyword, Text, Name::Namespace)
      m.push :def
    end
    rule /def(?=[*%&^`~+-\/\[<>=])/, Keyword, :def
    rule /(class|struct|union|type|alias|enum)(\s+)((?:[A-Z_]\w*::)*)([A-Z]\w*)/, &.groups(Keyword, Text, Name::Namespace, Name::Class)
    rule ID_REGEX do |m|
      id = m[0]
      if KEYWORDS.includes? id
        m.token Keyword
        case id
        when "end"
          # nothing
        when "do"
          m.push :begin_block_arg
        else
          m.push :follow_literal
        end
      elsif CONSTANTS.includes? id
        if id == "self"
          m.token Keyword::Pseudo
        else
          m.token Keyword::Constant
        end
      elsif BUILTINS.includes? id
        m.token Name::Builtin
        m.push :follow_literal
      elsif BUILTIN_MACROS.includes? id
        m.token Name::Builtin::Pseudo
        m.push :follow_literal
      else
        m.token Name::Variable
        m.push :follow_literal
      end
    end
    rule /@@[a-z]\w*/, Name::Variable::Class
    rule /@[a-z]\w*/, Name::Variable::Instance
    rule /\$[a-z]\w*/, Name::Variable::Global
    rule /\$(?:[?~]|[1-9]\??)/, Name::Variable::Global
    rule /[A-Z]\w*/ do |m|
      name = m[0]
      if name =~ /\A[A-Z_]+\z/
        if BUILTIN_CONSTANTS.includes? name
          m.token Name::Builtin
        else
          m.token Name::Constant
        end
      else
        if BUILTIN_CLASSES.includes? name
          m.token Name::Builtin
        else
          m.token Name::Class
        end
      end
    end

    # heredoc
    rule /(<<-)([']?)(\w*)(\2)(\s*?\n)/m do |m|
      m.token Operator, m[1]
      m.token Name::Constant, "#{m[2]}#{m[3]}#{m[4]}"
      m.token Str::Heredoc, m[5]

      heredoc_name = m[3]
      has_interpolation = m[2] != "\'"

      m.push do
        rule /^(\s*)(\w+)/m do |m|
          if m[2] == heredoc_name
            m.groups Str::Heredoc, Name::Constant
            m.pop!
          else
            m.token Str::Heredoc
          end
        end

        mixin :has_interpolation if has_interpolation

        rule /.*?(?:\n|$)/, Str::Heredoc
      end
    end

    rule /"/, Str::Double, :string
    rule /'(?:\\U\{[0-9a-fA-F]+\}|\\u[0-9a-fA-F]+|\\.|.)'/, Str::Single
    rule /:(?:#{ID_REGEX}|(?:[-+\/%!~^]|\*\*?|\|\|?|&&?|<=>|<<?|>>?|==?|!~)|"(?:\\.|.)*?")/, Str::Symbol
    rule /`/, Str::Backtick, :backtick

    rule /[0-9][0-9_]*\.[0-9_]*(?:[eE][-+][0-9]+)?(?:f32|f64)?/, Num::Float
    rule /0b[01_]+(?:[iu](?:8|16|32|64|128))?/, Num::Bin
    rule /0o[0-7_]+(?:[iu](?:8|16|32|64|128))?/, Num::Oct
    rule /0x[0-9a-fA-F_]+(?:[iu](?:8|16|32|64|128))?/, Num::Hex
    rule /[0-9][0-9_]*(f32|f64)/, Num::Float
    rule /[0-9][0-9_]*(?:[iu](?:8|16|32|64|128))?/, Num::Integer

    rule /@\[/, Punctuation
    rule /\=>/, Punctuation, :follow_literal

    rule /(&?)(\.)(#{ID_REGEX})/ do |m|
      case m[3]
      when "is_a?", "nil?", "as", "as?"
        m.groups Punctuation, Punctuation, Keyword
      when
        m.groups Punctuation, Punctuation, Name::Function
      end
      m.push :follow_literal
    end

    rule /\.{2,3}/, Operator, :follow_literal
    rule /(?:[-+\/%!~^]|\*\*?|\|\|?|&&?|<=>|<<?|>>?|==?)=?|!~/, Operator, :follow_literal

    rule /{/ do |m|
      m.token Punctuation
      m.push :root
      m.push :begin_block_arg
    end
    rule /}/ do |m|
      m.token Punctuation
      m.pop! if m.stack.size > 1
    end
    rule /[,;,?:\\({[]/, Punctuation, :follow_literal
    rule /[\])}]/, Punctuation
  end

  state :follow_literal do
    rule /\s+/, Text

    rule /\/(?=[^ ])/, Str::Regex, :regex

    rule /(%)([iqQrxw]?)(\S)/ do |m|
      type = m[2]
      has_interpolation = true
      case type
      when "i"
        type = Str::Other
      when "q"
        type = Str::Single
        has_interpolation = false
      when "Q"
        type = Str::Double
      when "r"
        type = Str::Regex
      when "x"
        type = Str::Backtick
      when "w"
        type = Str::Other
      else # only ""
        type = Str::Double
      end

      m.token type

      open = m[3]
      case open
      when "("
        close = ")"
      when "["
        close = "]"
      when "{"
        close = "}"
      when "<"
        close = ">"
      else
        close = open
      end

      open = Regex.escape(open)
      close = Regex.escape(close)

      m.push do
        if type == Str::Regex
          rule /#{close}[mix]*/, type, :pop!
        else
          rule /#{close}/, type, :pop!
        end
        rule /#{open}/, type, :push if open != close
        mixin :has_interpolation if has_interpolation
        rule /[^#{open}#{close}\\#]+|\\./, type
        rule /[#{open}#{close}\\#]/, type
      end
    end

    rule //, Text, :pop!
  end

  state :string do
    rule /"/, Str::Double, :pop!
    rule /\\./, Str::Double
    mixin :has_interpolation
    rule /[^"\\#]+/, Str::Double
    rule /["\\#]/, Str::Double
  end

  state :backtick do
    rule /`/, Str::Backtick, :pop!
    rule /\\./, Str::Backtick
    mixin :has_interpolation
    rule /[^`\\#]+/, Str::Backtick
    rule /[`\\#]/, Str::Backtick
  end

  state :regex do
    rule /\/[imx]*/, Str::Regex, :pop!
    rule /\\./, Str::Regex
    mixin :has_interpolation
    rule /[^\/\\#]+/, Str::Regex
    rule /[\/\\#]/, Str::Regex
  end

  state :has_interpolation do
    rule /\#{/, Str::Interpol, :interpolation
  end

  state :interpolation do
    rule /}/, Str::Interpol, :pop!
    mixin :root
  end

  state :def do
    rule /\s+/, Text

    rule %r(
      (?:([a-zA-Z_][\w_]*)(\.))?
      (
        #{ID_REGEX} |
        (?:[-+/%~^]|\*\*?|\||&|<=>|<[<=]?|>[>=]?|===?|=~|![~=]?) |
        \[\][?=]?
      )
    )x do |m|
      m.groups Name::Class, Operator, Name::Function
      m.pop!
    end

    rule //, &.pop!
  end

  state :begin_block_arg do
    rule /\|/, Punctuation, :in_block_arg
    mixin :follow_literal
  end

  state :in_block_arg do
    rule /\|/, Punctuation, :pop!
    rule /\s+/, Text
    rule /[(),]/, Punctuation
    rule /[a-z_]\w*/, Name::Variable
    rule //, Text, :pop!
  end
end
