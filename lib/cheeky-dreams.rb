module CheekyDreams
  class Rgb
    attr_reader :r, :g, :b
    
    def initialize r, g, b
      @r, @g, @b = r, g, b
      raise "Invalid rgb value #{r}, #{g}, #{b}" if [r, g, b].any? { |colour| colour < 0 || colour > 255 }
    end
    
    def == other
      return false unless other
      r == other.r && g == other.g && b == other.b
    end
    
    def to_s
      "RGB:#{r},#{g},#{b}"
    end
  end
  
  def self.rgb r, g, b
    Rgb.new r, g, b
  end
  def rgb r, g, b
    RGB::rgb r, g, b
  end
end

class Light
  
  include CheekyDreams::RGB
  
  COLOURS = { 
    :red => CheekyDreams::RGB::rgb(255, 0, 0),
    :green => CheekyDreams::RGB::rgb(0, 255, 0),
    :blue => CheekyDreams::RGB::rgb(0, 0, 255)
  }
  
  def initialize driver
    @driver = driver
  end
  
  def go colour
    if colour.is_a? CheekyDreams::Rgb
      @driver.go colour
    elsif COLOURS.has_key? colour
      @driver.go(COLOURS[colour])
    else
      raise "Unknown colour '#{colour}'"
    end
  end
end
