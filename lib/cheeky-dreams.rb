require 'thread'

module CheekyDreams
  
  def rgb_between a, b, ratio
    [
      position_between(a[0], b[0], ratio),
      position_between(a[1], b[1], ratio),
      position_between(a[2], b[2], ratio),
      ]
  end
  
  def position_between a, b, ratio
    return b if ratio >= 1.0
    (((b - a) * ratio) + a).floor
  end

  COLOURS = { 
    :off => [0, 0, 0],
    :red => [255, 0, 0],
    :green => [0, 255, 0],
    :blue => [0, 0, 255],
    :yellow => [255,255,0],
    :aqua => [0,255,255],
    :purple => [255,0,255],
    :grey => [192,192,192],
    :white => [255,255,255]
  }
  
  def rgb *rgb_args
    args = rgb_args.flatten
    if args.length == 1 && args[0].is_a?(Symbol)
      raise "Unknown colour '#{args[0]}'" unless COLOURS.has_key?(args[0])
      COLOURS[args[0]]
    elsif (args.length == 3 && args.all? { |c| c.is_a? Numeric })
      r, g, b = args[0].floor, args[1].floor, args[2].floor
      [r, g, b].each { |c| raise "Invalid rgb value #{r}, #{g}, #{b}" if c < 0 || c > 255}
      [r, g, b]
    else 
      raise "Invalid rgb #{args}"
    end
  end

  class StdIOAuditor
    def initialize out = STDOUT, err = STDERR
      @out, @err = out, err
    end
    
    def audit type, message
      case type
      when :error
        @err.puts "#{type} - #{message}"
      else
        @out.puts "#{type} - #{message}"
      end
    end
  end

  def stdio_audit out = STDOUT, err = STDERR
    StdIOAuditor.new(out, err)
  end
  
  def dev_null_auditor
    Class.new do
      def unhandled_error e
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
  
  def find_dream_cheeky_usb_device
    Device::DreamCheeky.new(File.dirname(Dir.glob('/sys/devices/**/red').first))
  end
  
  module Device
    class DreamCheeky
      attr_reader :path
      def initialize path, max_threshold = 50
        @path, @max_threshold = path, max_threshold
      end
      
      def go rgb
        worked = system "echo #{using_threshold(rgb[0])} > #{path}/red"
        raise "Failed to update #{path}/red, do you have permissions to write to that file??" unless worked
        system "echo #{using_threshold(rgb[1])} > #{path}/green"
        system "echo #{using_threshold(rgb[2])} > #{path}/blue"
      end
      
      private 
      def using_threshold colour
        colour if @threshold == 255
        ((colour / 255.to_f) * @max_threshold).floor
      end 
    end
  end
  
  module Effect
    class Effect
      include CheekyDreams    
      include Math
      
      attr_reader :freq
      
      def initialize freq
        @freq = freq
      end
    end
    
    class Throb2 < Effect      
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

    class Throb < Effect
      attr_reader :r_amp, :r_centre, :g_amp, :g_centre, :b_amp, :b_centre
            
      def initialize freq, from, to
        super freq
        @r_centre, @r_amp = centre_and_amp from[0], to[0]
        @g_centre, @g_amp = centre_and_amp from[1], to[1]
        @b_centre, @b_amp = centre_and_amp from[2], to[2]
        @count = 1
      end
      
      def next current_colour
        x = sin(freq * @count)
        r = x * r_amp + r_centre
        g = x * g_amp + g_centre
        b = x * b_amp + b_centre
        # x = freq * (@count += 1)
        # v = sin(x) * @amplitude + @centre
        # [v, 0, 0]
        
        @count += 1
        [r, g, b]
      end
      
      private 
      def centre_and_amp from, to
        amp = ((from - to).abs / 2.0).floor
        centre = max(from, to) - amp
        [centre, amp]
      end
      
      def max a, b
        a > b ? a : b
      end
    end

    
    class Func < Effect
      def initialize freq, &block
        super freq
        @block = block
      end
      
      def next current_colour = nil
        rgb(@block.yield(current_colour))
      end
    end
    
    class Solid < Effect
      def initialize colour
        super 1
        @rgb = rgb(colour)
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
        rgb(@cycle.next)
      end
    end
    
    class Fade < Effect
      def initialize from, to, steps, freq
        super freq
        @rgb_from, @rgb_to = rgb(from), rgb(to)
        @fade = [@rgb_from]
        (1..(steps-1)).each { |i| @fade << rgb_between(@rgb_from, @rgb_to, i / steps.to_f) }
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
      def initialize to, steps, freq
        super freq
        @to, @steps = to, steps
        @fade = nil
      end
      
      def next current_colour
        unless @fade
          @fade = Fade.new(current_colour, @to, @steps, freq)
          @fade.next current_colour
        end
        @fade.next current_colour
      end
    end
  end
end

class Light
  
  include CheekyDreams
  
  attr_accessor :freq, :auditor
  
  def initialize driver
    @driver, @freq, @auditor = driver, 100, dev_null_auditor
    @lock = Mutex.new
    @effect = nil
    @on = false
  end
  
  def cycle colours, freq = 1
    go(Effect::Cycle.new(colours, freq))
  end
  
  def solid colour
    go(Effect::Solid.new(colour))
  end
  
  def fade from, to, steps = 10, freq = 1
    go Effect::Fade.new from, to, steps, freq
  end

  def fade_to to, steps = 10, freq = 1
    go Effect::FadeTo.new to, steps, freq
  end
  
  def func freq = 1, &block
    go Effect::Func.new freq, &block
  end
  
  def throb freq, amplitude, centre
    go Effect::Throb.new freq, amplitude, centre
  end
  
  def test
    @driver.test
  end
  
  def go effect
    @lock.synchronize {
      case effect
        when Symbol
          @effect = Effect::Solid.new(effect)
        when Array
          @effect = Effect::Solid.new(effect)
        when Effect::Effect
          @effect = effect
        else
          raise "Im sorry dave, I'm afraid I can't do that. #{effect}"
      end
    }
    turn_on unless @on    
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
              @auditor.audit :colour_change, new_colour.to_s
              last_colour = new_colour
              next_colour_time = Time.now + (1 / current_effect.freq.to_f)
            end
          end
        rescue => e
          auditor.audit :error, e.message
        end
        sleep (1 / freq.to_f)
      end
    end
  end
end
