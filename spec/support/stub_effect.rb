class PreStuffedEffect < CheekyDreams::Effects::Effect
  def initialize *results
    @results = results
  end
  
  def next last_colour = nil
    result = @results.delete_at 0
    raise 'no more results in the prestuff effect!' unless result
    result
  end
end

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
  
  def next last_colour = nil
    @asked_for_colour_count += 1
    @block.yield
  end
end