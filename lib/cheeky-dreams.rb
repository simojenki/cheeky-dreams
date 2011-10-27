module CheekyDreams
  
  def self.rgb r, g, b
    [r, g, b].each { |c| raise "Invalid rgb value #{r}, #{g}, #{b}" if c < 0 || c > 255}
    [r, g, b]
  end
  def rgb r, g, b
    CheekyDreams::rgb(r, g, b)
  end
  
  def stdout_driver
    Class.new do
      def go rgb
        puts rgb
      end
    end.new
  end
  
  def ansi_driver
    require 'rainbow'
    Class.new do
      def go rgb
        print "     ".background(rgb)
        print "\r"
      end
    end.new
  end
end

class Light
  
  include CheekyDreams
  
  COLOURS = { 
    :red => CheekyDreams::rgb(255, 0, 0),
    :green => CheekyDreams::rgb(0, 255, 0),
    :blue => CheekyDreams::rgb(0, 0, 255)
  }
  
  def initialize driver
    @driver = driver
  end
  
  def go colour
    case colour
      when Symbol
        raise "Unknown colour '#{colour}'" unless COLOURS.has_key?(colour)
        @driver.go(COLOURS[colour])
      when Array
        @driver.go colour
      else
        raise "Im sorry dave, I'm afraid I can't do that. #{colour}"
    end
  end
end
