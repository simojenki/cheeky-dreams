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
  def rgb_between a, b, ratio
    CheekyDreams::rgb_between a, b, ratio
  end
  
  def self.position_between a, b, ratio
    return b if ratio >= 1.0
    (((b - a) * ratio) + a).floor
  end
  def position_between a, b, ratio
    CheekyDreams::position_between a, b, ratio
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
      raise "Invalid rgb #{colour}" unless colour.length == 3 && colour.all? { |c| c.is_a? Fixnum }
      rgb(colour[0], colour[1], colour[2])
    else 
      raise "Unsupported colour type #{colour}"
    end
  end
  def rgb_for colour
    CheekyDreams::rgb_for colour
  end
  
  def stderr_auditor
    Class.new do
      def unhandled_error e
        STDERR.puts e.message
        STDERR.puts e.backtrace.join("\n")
      end
    end.new
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
  
  def cycle colours, freq = 1
    Effect::Cycle.new colours, freq
  end
  
  def solid colour
    Effect::Solid.new colour
  end
  
  def fade from, to, steps = 10, over_how_long = 1
    Effect::Fade.new from, to, steps, over_how_long
  end

  def fade_to to, over_how_long = 1
    Effect::FadeTo.new to, over_how_long
  end
  
  def func freq = 1, &block
    Effect::Func.new freq, block
  end
  
  def throb freq, amplitude, centre
    Effect::Throb.new freq, amplitude, centre
  end
  
  module Effect
    class Effect
      include Flt
      include CheekyDreams    
      include Math
      
      attr_reader :freq
      
      def initialize freq
        @freq = freq
      end
    end
    
    class Throb < Effect      
      def initialize freq, amplitude, centre
        super freq
        @amplitude, @centre, @count = amplitude, centre, 1
      end
      
      def next current_colour
        x = freq * (@count += 1)
        v = sin(x) * @amplitude + @centre
        [v, 0, 0]
      end
    end
    
    class Func < Effect
      def initialize freq, block
        super freq
        @block, @last_change = block, Time.at(0)
      end
      
      def next current_colour
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
        super 1
        @rgb = rgb_for(colour)
      end
      
      def next current_colour = nil
        @rgb
      end
    end
    
    class Cycle < Effect
      def initialize colours, freq
        super freq
        @cycle = colours.cycle
      end
      
      def next current_colour = nil
        rgb_for(@cycle.next)
      end
    end
    
    class Fade < Effect
      def initialize from, to, steps, freq
        super freq
        @rgb_from, @rgb_to = rgb_for(from), rgb_for(to)
        @fade = [@rgb_from]
        (1..(steps-1)).each do |i|
          @fade << rgb_between(@rgb_from, @rgb_to, DecNum(i)/DecNum(steps))
        end
        @fade << @rgb_to
        @index = 0
      end
      
      def next current_colour = nil
        return @rgb_to if @index >= @fade.length
        next_colour = @fade[@index]
        @index += 1
        next_colour
      end
    end
    
    class FadeTo < Effect
      def initialize to, over_how_long
        @to, @over_how_long = to, over_how_long
        @fade = nil
      end
      
      def next current_colour
        @fade = Fade.new(current_colour, @to, @over_how_long) unless @fade
        @fade.next current_colour
      end
    end
  end
end

class Light
  
  include CheekyDreams
  include Flt
  
  attr_accessor :freq, :auditor
  
  def initialize driver
    @driver, @freq, @auditor = driver, 100, stderr_auditor
    @lock = Mutex.new
    @effect = nil
    @on = false
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
      current_effect = nil
      last_colour = nil
      next_colour_time = nil
      while @on
        begin
          @lock.synchronize {
            if @effect && current_effect != @effect
              current_effect = @effect
              next_colour_time = Time.at(0)
            end
          }
          if current_effect
            if Time.now > next_colour_time
              new_colour = current_effect.next(last_colour)
              @driver.go new_colour
              last_colour = new_colour
              next_colour_time = Time.now + (1 / current_effect.freq.to_f)
            end
          end
        rescue => e
          auditor.unhandled_error e
        end
        sleep (1 / freq.to_f)
      end
    end
  end
end
