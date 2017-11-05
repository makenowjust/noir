module Noir
  # :nodoc:
  TOKEN_NAMES = [] of String

  macro finished
    alias Token = {{ TOKEN_NAMES.map { |t| "#{t.id}.class".id }.join(" | ").id }}
  end

  module Tokens
    def self.each_token
      {% for const in @type.constants %}
        yield {{const}}
        {{const}}.each_sub_token_all do |t|
          yield t
        end
      {% end %}
    end

    private macro def_token(name, short_name, parent = "", token_chain = [] of Token)
      def_token({{name}}, {{short_name}}, {{parent}}, {{token_chain}}) { }
    end

    # :nodoc:
    macro def_token(name, short_name, parent = "", token_chain = [] of Token, &block)
      {% qualified_name = parent + name.stringify %}
      {% ::Noir::TOKEN_NAMES.push "Tokens::#{qualified_name.id}" %}

      {%
        token_chain = token_chain
          .join(",")
          .split(",")
          .select { |x| !x.empty? }
          .map(&.id)
      %}
      {% token_chain.unshift "Tokens::#{qualified_name.id}.as(Token)".id %}

      module {{name}}
        def self.name
          {{name}}
        end

        def self.short_name
          {{short_name}}
        end

        def self.qualified_name
          {{qualified_name}}
        end

        def self.token_chain : Array(Token)
          {{token_chain}}
        end

        def self.each_sub_token
          \{% for const in @type.constants %}
            yield \{{const}}
          \{% end %}
        end

        def self.each_sub_token_all
          each_sub_token do |t|
            yield t
            t.each_sub_token_all do |t|
              yield t
            end
          end
        end

        def self.to_s(io)
          io << "#<Token #{qualified_name}>"
        end

        private macro def_token(name, short_name)
          def_token(\{{name}}, \{{short_name}}) { }
        end

        private macro def_token(name, short_name, &block)
          ::Noir::Tokens.def_token(\{{name}}, \{{short_name}}, {{"#{qualified_name.id}::"}}, {{token_chain}}) do
            \{{yield}}
          end
        end

        {{yield}}
      end
    end

    def_token Text, "" do
      def_token Whitespace, "w"
    end

    def_token Error, "err"
    def_token Other, "x"

    def_token Keyword, "k" do
      def_token Constant, "kc"
      def_token Declaration, "kd"
      def_token Namespace, "kn"
      def_token Pseudo, "kp"
      def_token Reserved, "kr"
      def_token Type, "kt"
      def_token Variable, "kv"
    end

    def_token Name, "n" do
      def_token Attribute, "na"
      def_token Builtin, "nb" do
        def_token Pseudo, "bp"
      end
      def_token Class, "nc"
      def_token Constant, "no"
      def_token Decorator, "nd"
      def_token Entity, "ni"
      def_token Exception, "ne"
      def_token Function, "nf"
      def_token Property, "py"
      def_token Label, "nl"
      def_token Namespace, "nn"
      def_token Other, "nx"
      def_token Tag, "nt"
      def_token Variable, "nv" do
        def_token Class, "vc"
        def_token Global, "vg"
        def_token Instance, "vi"
      end
    end

    def_token Literal, "l" do
      def_token Date, "ld"

      def_token String, "s" do
        def_token Backtick, "sb"
        def_token Char, "sc"
        def_token Doc, "sd"
        def_token Double, "s2"
        def_token Escape, "se"
        def_token Heredoc, "sh"
        def_token Interpol, "si"
        def_token Other, "sx"
        def_token Regex, "sr"
        def_token Single, "s1"
        def_token Symbol, "ss"
      end

      def_token Number, "m" do
        def_token Float, "mf"
        def_token Hex, "mh"
        def_token Integer, "mi" do
          def_token Long, "il"
        end
        def_token Oct, "mo"
        def_token Bin, "mb"
        def_token Other, "mx"
      end
    end

    def_token Operator, "o" do
      def_token Word, "ow"
    end

    def_token Punctuation, "p" do
      def_token Indicator, "pi"
    end

    def_token Comment, "c" do
      def_token Doc, "cd"
      def_token Multiline, "cm"
      def_token Preproc, "cp"
      def_token Single, "c1"
      def_token Special, "cs"
    end

    def_token Generic, "g" do
      def_token Deleted, "gd"
      def_token Emph, "ge"
      def_token Error, "gr"
      def_token Heading, "gh"
      def_token Inserted, "gi"
      def_token Output, "go"
      def_token Prompt, "gp"
      def_token Strong, "gs"
      def_token Subheading, "gu"
      def_token Traceback, "gt"
      def_token Lineno, "gl"
    end

    # convenience

    alias Num = Literal::Number
    alias Str = Literal::String
  end
end
