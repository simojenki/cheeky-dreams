require 'within'

class StubDriver

  include Within

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
    within 5, "driver to become #{rgb}" do
      @lock.synchronize {
        [@colours.include?(rgb), "current colour = #{@colour}, has been #{@colours}"]
      }
    end
  end
end
