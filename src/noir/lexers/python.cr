require "../lexer"

class Noir::Lexers::Python < Noir::Lexer
  tag "python"
  aliases %w(py)
  filenames %w(
    *.py *.pyw
    *.sc SConstruct SConscript *.tac
  )
  mimetypes %w(
    text/x-python application/x-python
  )

  KEYWORDS = Set.new %w(
    assert break continue del elif else except exec
    finally for global if lambda pass print raise
    return try while yield as with from import yield
    async await
  )

  BUILTINS = Set.new %w(
    __import__ abs all any apply basestring bin bool buffer
    bytearray bytes callable chr classmethod cmp coerce compile
    complex delattr dict dir divmod enumerate eval execfile exit
    file filter float frozenset getattr globals hasattr hash hex id
    input int intern isinstance issubclass iter len list locals
    long map max min next object oct open ord pow property range
    raw_input reduce reload repr reversed round set setattr slice
    sorted staticmethod str sum super tuple type unichr unicode
    vars xrange zip
  )

  BUILTINS_PSEUDO = Set.new %w(self None Ellipsis NotImplemented False True)

  EXCEPTIONS = Set.new %w(
    ArithmeticError AssertionError AttributeError
    BaseException DeprecationWarning EOFError EnvironmentError
    Exception FloatingPointError FutureWarning GeneratorExit IOError
    ImportError ImportWarning IndentationError IndexError KeyError
    KeyboardInterrupt LookupError MemoryError NameError
    NotImplemented NotImplementedError OSError OverflowError
    OverflowWarning PendingDeprecationWarning ReferenceError
    RuntimeError RuntimeWarning StandardError StopIteration
    SyntaxError SyntaxWarning SystemError SystemExit TabError
    TypeError UnboundLocalError UnicodeDecodeError
    UnicodeEncodeError UnicodeError UnicodeTranslateError
    UnicodeWarning UserWarning ValueError VMSError Warning
    WindowsError ZeroDivisionError
  )

  IDENTIFIER =        /[a-z_][a-z0-9_]*/i
  DOTTED_IDENTIFIER = /[a-z_.][a-z0-9_.]*/i

  state :root do
    rule /\n+/m, Text
    rule /^(:)(\s*)([ru]{,2}""".*?""")/mi, &.groups Punctuation, Text, Str::Doc

    rule /[^\S\n]+/, Text
    rule /#.*$/, Comment
    rule /[\[\]{}:(),;]/, Punctuation
    rule /\\\n/, Text
    rule /\\/, Text

    rule /(in|is|and|or|not)\b/, Operator::Word
    rule /!=|==|<<|>>|[-~+\/*%=<>&^|.]/, Operator

    rule /(from)((?:\\\s|\s)+)(#{DOTTED_IDENTIFIER})((?:\\\s|\s)+)(import)/, &.groups Keyword::Namespace,
      Text,
      Name::Namespace,
      Text,
      Keyword::Namespace

    rule /(import)(\s+)(#{DOTTED_IDENTIFIER})/, &.groups Keyword::Namespace, Text, Name::Namespace

    rule /(def)((?:\s|\\\s)+)/ do |m|
      m.groups Keyword, Text
      m.push :funcname
    end

    rule /(class)((?:\s|\\\s)+)/ do |m|
      m.groups Keyword, Text
      m.push :classname
    end

    # TODO: not in python 3
    rule /`.*?`/, Str::Backtick
    rule /(?:r|ur|ru)"""/i, Str, :raw_tdqs
    rule /(?:r|ur|ru)'''/i, Str, :raw_tsqs
    rule /(?:r|ur|ru)"/i,   Str, :raw_dqs
    rule /(?:r|ur|ru)'/i,   Str, :raw_sqs
    rule /u?"""/i,          Str, :tdqs
    rule /u?'''/i,          Str, :tsqs
    rule /u?"/i,            Str, :dqs
    rule /u?'/i,            Str, :sqs

    rule /@#{DOTTED_IDENTIFIER}/i, Name::Decorator

    # using negative lookbehind so we don't match property names
    rule /(?<!\.)#{IDENTIFIER}/ do |m|
      if KEYWORDS.includes? m[0]
        m.token Keyword
      elsif EXCEPTIONS.includes? m[0]
        m.token Name::Builtin
      elsif BUILTINS.includes? m[0]
        m.token Name::Builtin
      elsif BUILTINS_PSEUDO.includes? m[0]
        m.token Name::Builtin::Pseudo
      else
        m.token Name
      end
    end

    rule IDENTIFIER, Name

    rule /(\d+\.\d*|\d*\.\d+)(e[+-]?[0-9]+)?/i, Num::Float
    rule /\d+e[+-]?[0-9]+/i, Num::Float
    rule /0[0-7]+/, Num::Oct
    rule /0x[a-f0-9]+/i, Num::Hex
    rule /\d+L/, Num::Integer::Long
    rule /\d+/, Num::Integer
  end

  state :funcname do
    rule IDENTIFIER, Name::Function, :pop!
  end

  state :classname do
    rule IDENTIFIER, Name::Class, :pop!
  end

  state :raise do
    rule /from\b/, Keyword
    rule /raise\b/, Keyword
    rule /yield\b/, Keyword
    rule /\n/, Text, :pop!
    rule(/;/, Punctuation, :pop!)
    mixin :root
  end

  state :yield do
    mixin :raise
  end

  state :strings do
    rule /%(\([a-z0-9_]+\))?[-#0 +]*([0-9]+|[*])?(\.([0-9]+|[*]))?/i, Str::Interpol
  end

  state :strings_double do
    rule /[^\\"%\n]+/, Str
    mixin :strings
  end

  state :strings_single do
    rule /[^\\'%\n]+/, Str
    mixin :strings
  end

  state :nl do
    rule /\n/, Str
  end

  state :escape do
    rule %r(\\
    ( [\\abfnrtv"']
     | \n
     | N{[a-zA-z][a-zA-Z ]+[a-zA-Z]}
     | u[a-fA-F0-9]{4}
     | U[a-fA-F0-9]{8}
     | x[a-fA-F0-9]{2}
     | [0-7]{1,3}
    )
    )x, Str::Escape
  end

  state :raw_escape do
    rule /\\./, Str
  end

  state :dqs do
    rule /"/, Str, :pop!
    mixin :escape
    mixin :strings_double
  end

  state :sqs do
    rule /'/, Str, :pop!
    mixin :escape
    mixin :strings_single
  end

  state :tdqs do
    rule /"""/, Str, :pop!
    rule /"/, Str
    mixin :escape
    mixin :strings_double
    mixin :nl
  end

  state :tsqs do
    rule /'''/, Str, :pop!
    rule /'/, Str
    mixin :escape
    mixin :strings_single
    mixin :nl
  end

  {% for qtype in %w(tdqs tsqs dqs sqs) %}
    state {{"raw_#{qtype.id}".id.symbolize}} do
      mixin :raw_escape
      mixin {{qtype.id.symbolize}}
    end
  {% end %}
end
