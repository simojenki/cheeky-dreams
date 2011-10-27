module CheekyDreams
  
  def self.rgb r, g, b
    [r, g, b]
  end
  def rgb r, g, b
    [r, g, b].each { |c| raise "Invalid rgb value #{r}, #{g}, #{b}" if c < 0 || c > 255}
    CheekyDreams::rgb(r, g, b)
  end
  
  def stdout_driver
    Driver::Stdout.new
  end
  
  def ansi_driver
    Driver::Ansi.new
  end

  module Driver
    class Stdout
      def go *rgb
        puts rgb
      end
    end
    
    class Ansi
      def initialize
        require 'rainbow'
      end
      def go *rgb
        print "     ".background(rgb)
        print "\r"
      end
    end
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
  
  def go *colour
    colour = colour.flatten
    if colour.length == 3
      @driver.go colour
    elsif colour.length == 1
      if COLOURS.has_key?(colour[0])
        @driver.go(COLOURS[colour[0]])
      else
        raise "Unknown colour '#{colour[0]}'"
      end
    else
      raise "Im sorry dave, I'm afraid I can't do that. #{colour}"
    end
  end
end
