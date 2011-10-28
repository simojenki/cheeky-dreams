
class StubDriver

  def initialize 
    @lock = Mutex.new
    @colours = []
  end

  def go colour
    @lock.synchronize {
      @colour = colour
      @colours << colour
    }
  end
  
  def should_become expected_colour
    rgb = expected_colour.is_a?(Symbol) ? CheekyDreams::COLOURS[expected_colour] : expected_colour
    start, match = Time.now, false
    while (((Time.now - start) < 1) && !match) do
      @lock.synchronize {
        match = (rgb == @colour)
      }
    end
    raise "Expected driver to become #{rgb}, and didn't, instead is #{@colour}, having been #{@colours}" unless match
  end
end
