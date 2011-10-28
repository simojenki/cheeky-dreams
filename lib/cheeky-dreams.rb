require 'thread'
require 'flt'

module CheekyDreams

  def self.rgb r, g, b
    [r, g, b].each { |c| raise "Invalid rgb value #{r}, #{g}, #{b}" if c < 0 || c > 255}
    [r, g, b]
  end
  def rgb r, g, b
    CheekyDreams::rgb(r, g, b)
  end
  
  def self.rgb_between a, b, ratio
    [
      position_between(a[0], b[0], ratio),
      position_between(a[1], b[1], ratio),
      position_between(a[2], b[2], ratio),
      ]
  end
  
  def self.position_between a, b, ratio
    return b if ratio >= 1.0
    (((b - a) * ratio) + a).floor
  end

  COLOURS = { 
    :red => rgb(255, 0, 0),
    :green => rgb(0, 255, 0),
    :blue => rgb(0, 0, 255),
    :yellow => rgb(255,255,0),
    :aqua => rgb(0,255,255),
    :purple => rgb(255,0,255),
    :grey => rgb(192,192,192),
    :white => rgb(255,255,255)
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
  def rgb_for colour
    CheekyDreams::rgb_for colour
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
  
  def cycle colours, freq
    Effect::Cycle.new colours, freq
  end
  
  def solid colour
    Effect::Solid.new colour
  end
  
  def fade from, to, over_how_long
    Effect::Fade.new from, to, over_how_long
  end
  
  def func freq, &block
    Effect::Func.new freq, block
  end
  
  module Effect
    class Effect
      include Flt
      include CheekyDreams    
    end
    
    class Func < Effect
      def initialize freq, block
        @freq, @block, @last_change = freq, block, Time.at(0)
      end
      
      def next
        now = Time.now
        if (now - @last_change) >= (DecNum(1)/DecNum(@freq))
          @last_change = now
          @current = rgb_for(@block.yield)
        end
        @current
      end
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
        now = Time.now
        if (now - @last_change) >= (DecNum(1)/DecNum(@freq))
          @last_change = now
          @current = rgb_for(@colours.next)
        end
        @current
      end
    end
    
    class Fade < Effect
      def initialize from, to, over_how_long
        @from, @to, @over_how_long = from, to, over_how_long
      end
      
      def next
        now = Time.now
        if @started_at == nil
          @started_at = now
          @from
        else
          ratio_done = (now - @started_at) / @over_how_long
          CheekyDreams.rgb_between(rgb_for(@from), rgb_for(@to), ratio_done)
        end
      end
    end
  end
end

class Light
  
  include CheekyDreams
  include Flt
  
  def initialize driver, freq = 5
    @driver = driver
    @lock = Mutex.new
    @effect = nil
    @on = false
    @freq = freq
  end
  
  def go effect
    turn_on unless @on    
    @lock.synchronize {
      case effect
        when Symbol
          @effect = solid(effect)
        when Array
          @effect = solid(effect)
        when Effect::Effect
          @effect = effect
        else
          raise "Im sorry dave, I'm afraid I can't do that. #{effect}"
      end
    }
  end
  
  private
  def turn_on
    @on = true
    Thread.new do
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
          puts e.message
          puts e.backtrace.join("\n")
        end
        sleep (DecNum(1)/DecNum(@freq))
      end
    end
  end
  
end
