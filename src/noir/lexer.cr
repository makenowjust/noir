require "./formatter"
require "./lexers"
require "./scanner"
require "./token"

abstract class Noir::Lexer
  include Tokens

  class_getter! tag : String
  class_getter aliases = [] of String
  class_getter filenames = [] of String
  class_getter mimetypes = [] of String

  def self.tag(@@tag : String)
    Lexers.register(tag, self)
  end

  def self.aliases(aliases : Array(String))
    @@aliases.concat aliases

    aliases.each do |name|
      Lexers.register(name, self)
    end
  end

  def self.filenames(filenames : Array(String))
    @@filenames.concat filenames
  end

  def self.mimetypes(mimetypes : Array(String))
    @@mimetypes.concat mimetypes
  end

  record TokenCallback,
    token : Token do
    def call(m : DSL) : Nil
      m.token token
    end
  end

  record PopCallback,
    token : Token do
    def call(m : DSL) : Nil
      m.token token
      m.pop!
    end
  end

  record PushCallback,
    token : Token,
    next_state : Symbol? do
    def call(m : DSL)
      m.token token
      m.push next_state
    end
  end

  alias ProcCallback = DSL -> Nil

  alias Callback = TokenCallback | PopCallback | PushCallback | ProcCallback

  record RegexRule,
    re : Regex,
    callback : Callback

  record MixinRule,
    state_name : Symbol

  alias Rule = RegexRule | MixinRule

  record State,
    name : Symbol?,
    rules : Array(Rule) do
    # :nodoc:
    def self.build(name : Symbol? = nil)
      builder = Builder.new([] of Rule)
      with builder yield
      new(name, builder.rules)
    end

    # :nodoc:
    def self.prepend(name : Symbol?, state : State)
      builder = Builder.new(state.rules.dup)
      with builder yield
      new(name, builder.rules)
    end

    # :nodoc:
    def self.append(name : Symbol?, state : State)
      builder = Builder.new([] of Rule)
      with builder yield
      new(name, builder.rules.concat(state.rules))
    end

    class Builder
      # :nodoc:
      getter rules

      # :nodoc:
      def initialize(@rules : Array(Rule))
      end

      private def rule(re : Regex, callback : Callback)
        rules << RegexRule.new(re, callback)
      end

      def rule(re : Regex, &callback : DSL -> Nil) : Nil
        rule re, callback
      end

      def rule(re : Regex, token : Token)
        rule re, TokenCallback.new(token)
      end

      def rule(re : Regex, token : Token, next_state : Symbol)
        callback = case next_state
                   when :pop!
                     PopCallback.new token
                   when :push
                     PushCallback.new token, nil
                   else
                     PushCallback.new token, next_state
                   end

        rule re, callback
      end

      def mixin(state_name : Symbol)
        @rules << MixinRule.new(state_name)
      end
    end
  end

  @@states = {} of Symbol => State

  def self.state(name : Symbol)
    @@states.fetch(name) do
      if (klass = {{@type.superclass}}).responds_to?(:state)
        klass.state(name)
      else
        raise "undefined state: #{name}"
      end
    end
  end

  def self.state(name : Symbol, &block)
    @@states[name] = State.build(name) do
      with itself yield
    end
  end

  def self.prepend(name, &block)
    state = state(name)
    @@states[name] = State.prepend(name, state) do
      with itself yield
    end
  end

  def self.append(name, &block)
    state = state(name)
    @@states[name] = State.append(name, state) do
      with itself yield
    end
  end

  getter stack

  def initialize
    @stack = Deque(State).new
    @stack.push state(:root)

    @null_scans = 0
  end

  def lex_all(input : String, output : Formatter)
    lex_all Scanner.new(input), output, finish: true
  end

  protected def lex_all(input : Scanner, output : Formatter, finish : Bool)
    while input.has_next?
      success = lex input, output

      unless success
        output.yield_token Tokens::Error, input.current_char
        input.next_char
      end
    end

    output.finish if finish
  end

  MAX_NULL_SCANS = 5

  private def lex(input, output, state = current_state)
    state.rules.each do |rule|
      case rule
      when MixinRule
        return true if lex(input, output, state(rule.state_name))
      when RegexRule
        if m = input.scan(rule.re)
          rule.callback.call DSL.new(self, input, output, m)

          if m.byte_begin(0) == m.byte_end(0)
            @null_scans += 1
            return false if @null_scans > MAX_NULL_SCANS
          else
            @null_scans = 0
          end

          return true
        end
      else
        raise "BUG: unreachable"
      end
    end

    false
  end

  def current_state
    stack.last
  end

  def state(name)
    self.class.state(name)
  end

  record DSL,
    lexer : Lexer,
    input : Scanner,
    output : Formatter,
    last_match : Regex::MatchData do
    def token(token : Token, value : String? = last_match[0]) : Nil
      output.yield_token token, value
    end

    def groups(*tokens : Token) : Nil
      tokens.each_with_index do |token, i|
        token token, last_match[i + 1]?
      end
    end

    def delegate(lexer : Lexer, text = last_match[0]) : Nil
      lexer.lex_all(Scanner.new(text), output, finish: false)
    end

    def push(&block) : Nil
      state = State.build do
        with itself yield
      end
      stack.push state
    end

    def push(state_name : Symbol) : Nil
      stack.push lexer.state(state_name)
    end

    def push(state_name : Nil = nil) : Nil
      stack.push current_state
    end

    def pop!(times = 1) : Nil
      stack.pop times
    end

    def goto(state_name) : Nil
      stack[-1] = lexer.state(state_name)
    end

    def reset_stack : Nil
      stack.clear
      stack.push lexer.state(state_name)
    end

    def in_state?(state_name) : Bool
      stack.any? &.name.==(state_name)
    end

    def state?(state_name) : Bool
      current_state.name == state_name
    end

    # delegate to `lexer`

    def stack : Deque(State)
      lexer.stack
    end

    def current_state : State
      lexer.current_state
    end

    # delegate to `last_match`

    def [](i)
      last_match[i]
    end

    def []?(i)
      last_match[i]?
    end
  end
end
