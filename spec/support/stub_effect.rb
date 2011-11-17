
class StubEffect < CheekyDreams::Effects::Effect
  
  attr_reader :asked_for_colour_count
  
  def initialize &block
    @asked_for_colour_count = 0
    if block
      @block = block
    else
      @block = proc { [[0,0,0], 1] }
    end
  end
  
  def next last_colour
    @asked_for_colour_count += 1
    @block.yield
  end
end