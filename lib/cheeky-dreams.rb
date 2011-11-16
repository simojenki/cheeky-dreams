require 'thread'

module CheekyDreams
  
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
  
  def rgb_between a, b, ratio
    [
      position_between(a[0], b[0], ratio),
      position_between(a[1], b[1], ratio),
      position_between(a[2], b[2], ratio),
      ]
  end
  
  def sleep_until time
    zzz_time = time - Time.now
    sleep(zzz_time) if zzz_time > 0
  end
  
  def position_between a, b, ratio
    return b if ratio >= 1.0
    (((b - a) * ratio) + a).floor
  end

  def rgb *rgb_args
    raise 'Cannot give rgb for nil!' unless rgb_args
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

  class FilteringAuditor
    def initialize auditor, including
      @auditor, @including = auditor, Set.new(including)
    end
    
    def audit type, message
      @auditor.audit(type, message) if @including.include?(type)
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
  
  def filtering including, auditor
    FilteringAuditor.new auditor, including
  end
  
  def audit_to *auditors
    CompositeAuditor.new *auditors
  end
  
  class CompositeAuditor
    def initialize *auditors
      @auditors = auditors
    end
    
    def audit type, message
      @auditors.each { |auditor| auditor.audit type, message }
    end
  end

  def stdio_audit out = STDOUT, err = STDERR
    StdIOAuditor.new(out, err)
  end
  
  def dev_null
    Dev::Null.new
  end
  
  def stdout_driver
  	Dev::IO.new
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
    Dev::DreamCheeky.new(File.dirname(Dir.glob('/sys/devices/**/red').first))
  end

  def off
    solid :off
  end
   
  def solid colour
    Effects::Solid.new(colour)
  end

  def cycle colours, freq = 1
    Effects::Cycle.new(colours, freq)
  end

  def fade from, to, steps = 10, freq = 1
    Effects::Fade.new from, to, steps, freq
  end

  def fade_to to, steps = 10, freq = 1
    Effects::FadeTo.new to, steps, freq
  end

  def func freq = 1, &block
    Effects::Func.new freq, &block
  end

  def throb freq, amplitude, centre
    Effects::Throb.new freq, amplitude, centre
  end
  
  def crazy freq = 1, new_effect_freq = 2
  	Effects::Crazy.new(freq, new_effect_freq)
  end
   
  module Dev
    class Null
      def audit type, message
      end
    end
    
    class IO
    	def initialize io = $stdout
    		@io, @last = io, nil
    	end
    	
    	def go rgb
    		@io.puts "[#{rgb.join(',')}]" unless rgb == @last
    		@last = rgb
    	end
    end
    
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
  
  module Effects
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

    class Crazy < Effect 
			def initialize freq, new_effect_freq
				super freq
				@new_effect_freq = new_effect_freq
        @count, @effect = 0, nil
			end

			def next current_colour
				if @count % @new_effect_freq == 0
					@effect = FadeTo.new([rand(255), rand(255), rand(255)], @new_effect_freq, freq)
			  end
				@count += 1
				@effect.next current_colour
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
        super 0.1
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
        @fade = Fade.new(current_colour, @to, @steps, freq) unless @fade        
        @fade.next current_colour
      end
    end
  end
end

class Light
  
  attr_accessor :freq, :auditor
  
  include CheekyDreams
  
  def initialize driver
    @driver, @freq, @auditor, @effect = driver, 50, dev_null, solid(:off)
    @lock, @wake_up = Mutex.new, ConditionVariable.new
    @on = false
  end
  
  def go effect
    @lock.synchronize {
      case effect
        when Symbol
          @effect = solid(effect)
        when Array
          @effect = solid(effect)
        when CheekyDreams::Effects::Effect
          @effect = effect
        else
          raise "Im sorry dave, I'm afraid I can't do that. #{effect}"
      end
    }
    wakeup
    turn_on unless @on    
  end
  
  def off
    @on = false
  end
  
  private
  def turn_on
    @on, current_effect = true, nil
    @run_thread = Thread.new do
      last_colour = COLOURS[:off]
      while @on
        start = Time.now
        @lock.synchronize { current_effect = @effect }
        begin
          new_colour = current_effect.next last_colour
          @driver.go new_colour
          @auditor.audit :colour_change, new_colour.to_s
          last_colour = new_colour
        rescue => e
          auditor.audit :error, e.message
        end
        sleep_until (start + (1 / current_effect.freq.to_f))
      end      
    end
  end
  
  def wakeup
    @run_thread.run if @run_thread
  end
  
  def do_in seconds, &to_do
    sleep seconds if seconds > 0
    Thread.new do
      to_do.yield
    end 
  end
end
