require "./token"

abstract class Noir::Formatter
  @last_token : Token?
  @value : IO::Memory = IO::Memory.new

  def yield_token(token : Token, value) : Nil
    return unless value
    return if value.is_a?(String) && value.empty?

    if token != @last_token
      if @last_token
        format @last_token, @value.to_s
        @value.clear
      end
      @last_token = token
    end

    @value << value
  end

  def finish
    value = @value.to_s
    format @last_token, value unless value.empty?
  end

  abstract def format(token : Token?, value : String) : Nil
end
