require 'thread'

module CheekyDreams

  def self.rgb r, g, b
    [r, g, b].each { |c| raise "Invalid rgb value #{r}, #{g}, #{b}" if c < 0 || c > 255}
    [r, g, b]
  end
  def rgb r, g, b
    CheekyDreams::rgb(r, g, b)
  end

  COLOURS = { 
    :red => CheekyDreams::rgb(255, 0, 0),
    :green => CheekyDreams::rgb(0, 255, 0),
    :blue => CheekyDreams::rgb(0, 0, 255)
  }
  
  def self.rgb_for colour
    case colour
    when Symbol
      raise "Unknown colour '#{colour}'" unless COLOURS.has_key?(colour)
      COLOURS[colour]
    when Array
      colour
    else 
      raise "Unsupported colour type #{colour}"
    end
  end
  
  def stdout_driver
    Class.new do
      def go rgb
        puts rgb.class
      end
    end.new
  end
  
  def ansi_driver
    require 'rainbow'
    Class.new do
      def go rgb
        print "     ".background(rgb_for(rgb))
        print "\r"
      end
    end.new
  end
  
  def cycle colours, freq
    Effect::Cycle.new colours, freq
  end
  
  def solid colour
    Effect::Solid.new colour
  end
  
  module Effect
    class Effect
    end
    
    class Solid < Effect
      def initialize colour
        @rgb = CheekyDreams::rgb_for(colour)
      end
      def next
        @rgb
      end
    end
    
    class Cycle < Effect
      def initialize colours, freq
        @colours, @freq, @last_change = colours.cycle, freq, Time.at(0)
      end
      
      def next
        if (Time.now - @last_change) >= (1/@freq)
          @last_change = Time.now
          @current = CheekyDreams::rgb_for(@colours.next)
        end
        @current
      end
    end
  end
end

class Light
  
  include CheekyDreams
  
  def initialize driver, freq = 5
    @driver = driver
    @lock = Mutex.new
    @effect = nil
    @on = false
    @freq = freq
  end
  
  def go colour
    @lock.synchronize {
      case colour
        when Symbol
          @effect = solid(colour)
        when Array
          @effect = solid(colour)
        when Effect::Effect
          @effect = colour
        else
          raise "Im sorry dave, I'm afraid I can't do that. #{colour}"
      end
    }
  end
  
  def on
    @on = true
    t = Thread.new do
      last_colour = nil
      while @on
        begin
          @lock.synchronize {
            if @effect
              new_colour = @effect.next 
              if new_colour != last_colour
                @driver.go new_colour
                last_colour = new_colour
              end
            end
          }
        rescue => e
          puts e
        end
        sleep (1/@freq)
      end
    end
  end
  
end
