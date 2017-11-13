class Etnoir::Exit < Exception
  getter status

  def initialize(@status = 0)
    super("BUG: etnoir exit status: #{status}")
  end
end
