
class StubEffect < CheekyDreams::Effects::Effect
  
  attr_reader :freq, :asked_for_colour_count
  
  def initialize freq, &block
    @freq, @asked_for_colour_count = freq, 0
    if block
      @block = block
    else
      @block = proc { [0,0,0] }
    end
  end
  
  def next last_colour
    @asked_for_colour_count += 1
    @block.yield
  end
end