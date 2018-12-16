require "../lexer"

class Noir::Lexers::Ruby < Noir::Lexer
  tag "ruby"
  aliases %w(rb)
  filenames %w(
    *.rb *.ruby *.rbw *.rake *.gemspec *.podspec
    Rakefile Guardfile Gemfile 'Capfile Podfile
    Vagrantfile *.ru *.prawn Berksfile *.arb
  )
  mimetypes %w(text/x-ruby application/x-ruby)

  state :symbols do
    # symbols
    rule %r(
    :  # initial :
    @{0,2} # optional ivar, for :@foo and :@@foo
    [a-z_]\w*[!?]? # the symbol
    )xi, Str::Symbol

    # special symbols
    rule %r(:(?:\*\*|[-+]@|[/\%&\|^`~]|\[\]=?|<<|>>|<=?>|<=?|===?)),
      Str::Symbol

    rule /:'(\\\\|\\'|[^'])*'/, Str::Symbol
    rule /:"/, Str::Symbol, :simple_sym
  end

  state :sigil_strings do
    # %-sigiled strings
    # %(abc), %[abc], %<abc>, %.abc., %r.abc., etc
    delimiter_map = {
      "{" => "}",
      "[" => "]",
      "(" => ")",
      "<" => ">",
    }
    rule /%([rqswQWxiI])?([^\w\s])/ do |m|
      open = Regex.escape(m[2])
      close = Regex.escape(delimiter_map[m[2]]? || m[2])
      interp = /[rQWxI]/ === m[1]?
      toktype = Str::Other

      # regexes
      if m[1]? == "r"
        toktype = Str::Regex
        m.push :regex_flags
      end

      m.token toktype

      m.push do
        rule /\\[##{open}#{close}\\]/, Str::Escape
        # nesting rules only with asymmetric delimiters
        if open != close
          rule /#{open}/ do |m|
            m.token toktype
            m.push
          end
        end
        rule /#{close}/, toktype, :pop!

        if interp
          mixin :string_intp_escaped
          rule /#/, toktype
        else
          rule /[\\#]/, toktype
        end

        rule /[^##{open}#{close}\\]+/m, toktype
      end
    end
  end

  state :strings do
    mixin :symbols
    rule /\b[a-z_]\w*?[?!]?:\s+/, Str::Symbol, :expr_start
    rule /'(\\\\|\\'|[^'])*'/, Str::Single
    rule /"/, Str::Double, :simple_string
    rule /(?<!\.)`/, Str::Backtick, :simple_backtick
  end

  state :regex_flags do
    rule /[mixounse]*/, Str::Regex, :pop!
  end

  # double-quoted string and symbol
  [
    {:simple_string, Str::Double, '"'},
    {:simple_sym, Str::Symbol, '"'},
    {:simple_backtick, Str::Backtick, '`'},
  ].each do |(name, tok, fin)|
    state name do
      mixin :string_intp_escaped
      rule /[^\\#{fin}#]+/m, tok
      rule /[\\#]/, tok
      rule /#{fin}/, tok, :pop!
    end
  end

  keywords = %w(
    BEGIN END alias begin break case defined\? do else elsif end
    ensure for if in next redo rescue raise retry return super then
    undef unless until when while yield
  )

  keywords_pseudo = %w(
    loop include extend raise
    alias_method attr catch throw private module_function
    public protected true false nil __FILE__ __LINE__
  )

  builtins_g = %w(
    attr_reader attr_writer attr_accessor
    __id__ __send__ abort ancestors at_exit autoload binding callcc
    caller catch chomp chop class_eval class_variables clone
    const_defined\? const_get const_missing const_set constants
    display dup eval exec exit extend fail fork format freeze
    getc gets global_variables gsub hash id included_modules
    inspect instance_eval instance_method instance_methods
    instance_variable_get instance_variable_set instance_variables
    lambda load local_variables loop method method_missing
    methods module_eval name object_id open p print printf
    private_class_method private_instance_methods private_methods proc
    protected_instance_methods protected_methods public_class_method
    public_instance_methods public_methods putc puts raise rand
    readline readlines require require_relative scan select self send set_trace_func
    singleton_methods sleep split sprintf srand sub syscall system
    taint test throw to_a to_s trace_var trap untaint untrace_var warn
  )

  builtins_q = %w(
    autoload block_given const_defined eql equal frozen
    include instance_of is_a iterator kind_of method_defined
    nil private_method_defined protected_method_defined
    public_method_defined respond_to tainted
  )

  builtins_b = %w(chomp chop exit gsub sub)

  getter heredoc_queue = [] of {Bool, String}

  def initialize
    super
    @stack.push state(:expr_start)
  end

  state :whitespace do
    mixin :inline_whitespace
    rule /\n\s*/m, Text, :expr_start
    rule /#.*?$/m, Comment::Single

    rule %r(=begin\b.*?\n=end\b)m, Comment::Multiline
  end

  state :inline_whitespace do
    rule /[ \t\r]+/, Text
  end

  state :root do
    mixin :whitespace
    rule /__END__/, Comment::Preproc, :end_part

    rule /0_?[0-7]+(?:_[0-7]+)*/, Num::Oct
    rule /0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*/, Num::Hex
    rule /0b[01]+(?:_[01]+)*/, Num::Bin
    rule /\d+\.\d+(e[\+\-]?\d+)?/, Num::Float
    rule /[\d]+(?:_\d+)*/, Num::Integer

    # names
    rule /@@[a-z_]\w*/i, Name::Variable::Class
    rule /@[a-z_]\w*/i, Name::Variable::Instance
    rule /\$\w+/, Name::Variable::Global
    rule %r(\$[!@&`'+~=/\\,;.<>_*\$?:"]), Name::Variable::Global
    rule /\$-[0adFiIlpvw]/, Name::Variable::Global
    rule /::/, Operator

    mixin :strings

    rule /(?:#{keywords.join('|')})\b/, Keyword, :expr_start
    rule /(?:#{keywords_pseudo.join('|')})\b/, Keyword::Pseudo, :expr_start

    rule %r(
      (module)
      (\s+)
      ([a-zA-Z_][a-zA-Z0-9_]*(::[a-zA-Z_][a-zA-Z0-9_]*)*)
    )x, &.groups Keyword, Text, Name::Namespace

    rule /(def\b)(\s*)/ do |m|
      m.groups Keyword, Text
      m.push :funcname
    end

    rule /(class\b)(\s*)/ do |m|
      m.groups Keyword, Text
      m.push :classname
    end

    rule /(?:#{builtins_q.join('|')})[?]/, Name::Builtin, :expr_start
    rule /(?:#{builtins_b.join('|')})!/, Name::Builtin, :expr_start
    rule /(?<!\.)(?:#{builtins_g.join('|')})\b/,
      Name::Builtin, :method_call

    mixin :has_heredocs

    # `..` and `...` for ranges must have higher priority than `.`
    # Otherwise, they will be parsed as :method_call
    rule /\.{2,3}/, Operator, :expr_start

    rule /[A-Z][a-zA-Z0-9_]*/, Name::Constant, :method_call
    rule /(\.|::)(\s*)([a-z_]\w*[!?]?|[*%&^`~+-\/\[<>=])/ do |m|
      m.groups Punctuation, Text, Name::Function
      m.push :method_call
    end

    rule /[a-zA-Z_]\w*[?!]/, Name, :expr_start
    rule /[a-zA-Z_]\w*/, Name, :method_call
    rule /\*\*|<<?|>>?|>=|<=|<=>|=~|={3}|!~|&&?|\|\||\./,
      Operator, :expr_start
    rule /[-+\/*%=<>&!^|~]=?/, Operator, :expr_start
    rule(/[?]/) do |m|
      m.token Punctuation
      m.push :ternary
      m.push :expr_start
    end
    rule %r<[\[({,:\\;/]>, Punctuation, :expr_start
    rule %r<[\])}]>, Punctuation
  end

  state :has_heredocs do
    rule /(?<!\w)(<<[-~]?)(["`']?)([a-zA-Z_]\w*)(\2)/ do |m|
      m.token Operator, m[1]
      m.token Name::Constant, "#{m[2]}#{m[3]}#{m[4]}"
      m.lexer.as(Ruby).heredoc_queue << {
        {"<<-", "<<~"}.includes?(m[1]),
        m[3],
      }
      m.push :heredoc_queue unless m.state? :heredoc_queue
    end

    rule /(<<[-~]?)(["'])(\2)/ do |m|
      m.token Operator, m[1]
      m.token Name::Constant, "#{m[2]}#{m[3]}#{m[4]}"
      m.lexer.as(Ruby).heredoc_queue << {
        {"<<-", "<<~"}.includes?(m[1]),
        "",
      }
      m.push :heredoc_queue unless m.state? :heredoc_queue
    end
  end

  state :heredoc_queue do
    rule /(?=\n)/ do |m|
      m.goto :resolve_heredocs
    end

    mixin :root
  end

  state :resolve_heredocs do
    mixin :string_intp_escaped

    rule /\n/, Str::Heredoc, :test_heredoc
    rule /[#\\\n]/, Str::Heredoc
    rule /[^#\\\n]+/, Str::Heredoc
  end

  state :test_heredoc do
    rule /[^#\\\n]*$/m do |m|
      ruby = m.lexer.as(Ruby)
      tolerant, heredoc_name = ruby.heredoc_queue.first
      check = tolerant ? m[0].strip : m[0].rstrip

      # check if we found the end of the heredoc
      if check == heredoc_name
        ruby.heredoc_queue.shift
        # if there's no more, we're done looking.
        m.pop! if ruby.heredoc_queue.empty?
        m.token Name::Constant
      else
        m.token Str::Heredoc
      end

      m.pop!
    end

    rule %r(), &.pop!
  end

  state :funcname do
    rule /\s+/, Text
    rule /\(/, Punctuation, :defexpr
    rule %r(
      (?:([a-zA-Z_][\w_]*)(\.))?
      (
        [a-zA-Z_][\w_]*[!?]? |
        \*\*? | [-+]@? | [/%&\|^`~] | \[\]=? |
        <<? | >>? | <=>? | >= | ===?
      )
    )x do |m|
      m.groups Name::Class, Operator, Name::Function
      m.pop!
    end

    rule %r(), &.pop!
  end

  state :classname do
    rule /\s+/, Text
    rule /\(/ do |m|
      m.token Punctuation
      m.push :defexpr
      m.push :expr_start
    end

    # class << expr
    rule /<</ do |m|
      m.token Operator
      m.goto :expr_start
    end

    rule /[A-Z_]\w*/, Name::Class, :pop!

    rule %r(), &.pop!
  end

  state :ternary do
    rule(/:(?!:)/) do |m|
      m.token Punctuation
      m.goto :expr_start
    end

    mixin :root
  end

  state :defexpr do
    rule /(\))(\.|::)?/ do |m|
      m.groups Punctuation, Operator
      m.pop!
    end
    rule /\(/ do |m|
      m.token Punctuation
      m.push :defexpr
      m.push :expr_start
    end

    mixin :root
  end

  state :in_interp do
    rule /}/, Str::Interpol, :pop!
    mixin :root
  end

  state :string_intp do
    rule /[#][{]/, Str::Interpol, :in_interp
    rule /#(@@?|\$)[a-z_]\w*/i, Str::Interpol
  end

  state :string_intp_escaped do
    mixin :string_intp
    rule /\\([\\abefnrstv#"']|x[a-fA-F0-9]{1,2}|[0-7]{1,3})/,
      Str::Escape
    rule /\\./, Str::Escape
  end

  state :method_call do
    rule %r(/) do |m|
      m.token Operator
      m.goto :expr_start
    end

    rule /(?=\n)/, &.pop!

    rule %r(), &.goto :method_call_spaced
  end

  state :method_call_spaced do
    mixin :whitespace

    rule %r([%/]=) do |m|
      m.token Operator
      m.goto :expr_start
    end

    rule %r((/)(?=\S|\s*/)) do |m|
      m.token Str::Regex
      m.goto :slash_regex
    end

    mixin :sigil_strings

    rule %r((?=\s*/)), &.pop!

    rule /\s+/ do |m|
      m.token Text
      m.goto :expr_start
    end
    rule %r(), &.pop!
  end

  state :expr_start do
    mixin :inline_whitespace

    rule %r(/) do |m|
      m.token Str::Regex
      m.goto :slash_regex
    end

    # char operator.  ?x evaulates to "x", unless there's a digit
    # beforehand like x>=0?n[x]:""
    rule %r(
      [?](\\[MC]-)*     # modifiers
      (\\([\\abefnrstv\#"']|x[a-fA-F0-9]{1,2}|[0-7]{1,3})|\S)
      (?!\w)
    )x, Str::Char, :pop!

    # special case for using a single space.  Ruby demands that
    # these be in a single line, otherwise it would make no sense.
    rule /(\s*)(%[rqswQWxiI]? \S* )/ do |m|
      m.groups Text, Str::Other
      m.pop!
    end

    mixin :sigil_strings

    rule %r(), &.pop!
  end

  state :slash_regex do
    mixin :string_intp
    rule %r(\\\\), Str::Regex
    rule %r(\\/), Str::Regex
    rule %r([\\#]), Str::Regex
    rule %r([^\\/#]+)m, Str::Regex
    rule %r(/) do |m|
      m.token Str::Regex
      m.goto :regex_flags
    end
  end

  state :end_part do
    # eat up the rest of the stream as Comment::Preproc
    rule /.+/m, Comment::Preproc, :pop!
  end
end
