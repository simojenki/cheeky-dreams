require 'thread'
require 'set'

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

  class ForwardingAuditor
    def initialize rules
      @rules = rules
    end
    
    def audit type, message
      @rules[type].audit(type, message) if @rules.has_key?(type)
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
  
  AuditEvent = Struct.new(:type, :message)
  
  class SuppressDuplicatesAuditor
    def initialize auditor
      @auditor, @audits = auditor, Set.new
    end
    
    def audit type, message
      event = AuditEvent.new type, message
      unless @audits.include?(event)
        @auditor.audit(type, message)
        @audits << event
      end
    end
  end
  
  def suppress_duplicates auditor
    SuppressDuplicatesAuditor.new auditor
  end
  
  def forward rules
    ForwardingAuditor.new rules
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

  def func &block
    Effects::Func.new &block
  end

  def throb freq, from, to
    Effects::Throb.new freq, from, to
  end
  
  def throbbing colour, freq = 10
    rgb_colour = rgb(colour)
    Effects::Throb.new freq, rgb_colour, [max(rgb_colour[0] - 200, 0), max(rgb_colour[1] - 200, 0), max(rgb_colour[2] - 200, 0)]
  end
  
  def max a, b
    a > b ? a : b
  end
  
  def crazy freq = 10, new_effect_freq = 10
  	Effects::Crazy.new(freq, new_effect_freq)
  end
  
  def light_show *effects
    Effects::LightShow.new effects
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
    end
    
    class LightShow < Effect
      def initialize effects
        @effects, @current, @last_freq = effects, nil, nil
      end
      
      def next current_colour = nil
        @current = @effects.delete_at(0) unless @current
        colour, freq = @current.next current_colour
        if (freq == 0 && !@effects.empty?)
          @current = @effects.delete_at(0)
        elsif (freq == 0 && @effects.empty?)
          @last_freq = 0
        else
          @last_freq = freq
        end
        [colour, @last_freq]
      end
    end
    
    class Throb2 < Effect      
      def initialize freq, amplitude, centre
        @freq, @amplitude, @centre, @count = freq, amplitude, centre, 1
      end
      
      def next current_colour
        x = @freq * (@count += 1)
        v = sin(x) * @amplitude + @centre
        [[v, 0, 0], @freq]
      end
    end

    class Throb < Effect
      attr_reader :r_amp, :r_centre, :g_amp, :g_centre, :b_amp, :b_centre
            
      def initialize freq, from, to
        @freq = freq
        @r_centre, @r_amp = centre_and_amp from[0], to[0]
        @g_centre, @g_amp = centre_and_amp from[1], to[1]
        @b_centre, @b_amp = centre_and_amp from[2], to[2]
        @sin_freq = 3.14 / freq.to_f
        @count = (1.57 / @sin_freq).floor
      end
      
      def next current_colour
        x = sin(@sin_freq * @count)
        r = x * r_amp + r_centre
        g = x * g_amp + g_centre
        b = x * b_amp + b_centre
        # x = freq * (@count += 1)
        # v = sin(x) * @amplitude + @centre
        # [v, 0, 0]
        
        @count += 1
        [[r.floor, g.floor, b.floor], @freq]
      end
      
      private 
      def centre_and_amp from, to
        amp = ((from - to).abs / 2.0).floor
        centre = max(from, to) - amp
        [centre, amp]
      end
    end

    class Crazy < Effect 
			def initialize freq, new_effect_freq
				@freq, @new_effect_freq = freq, new_effect_freq
        @count, @fade = 0, nil
			end

			def next current_colour
				if @count % @new_effect_freq == 0
					@fade = FadeTo.new([rand(255), rand(255), rand(255)], @new_effect_freq, @freq)
			  end
				@count += 1
				[@fade.next(current_colour)[0], @freq]
			end
    end
    
    class Func < Effect
      def initialize &block
        @block = block
      end
      
      def next current_colour = nil
        colour, freq = @block.yield(current_colour)
        [rgb(colour), freq]
      end
    end
    
    class Solid < Effect
      def initialize colour
        @rgb = rgb(colour)
      end
      
      def next current_colour = nil
        [@rgb, 0]
      end
    end
    
    class Cycle < Effect
      def initialize colours, freq
        @freq, @cycle = freq, colours.cycle
      end
      
      def next current_colour = nil
        [rgb(@cycle.next), @freq]
      end
    end
    
    class Fade < Effect
      def initialize from, to, steps, freq
        @freq, @rgb_from, @rgb_to = freq, rgb(from), rgb(to)
        @fade = [@rgb_from]
        (1..(steps-1)).each { |i| @fade << rgb_between(@rgb_from, @rgb_to, i / steps.to_f) }
        @fade << @rgb_to
        @index = 0
      end
      
      def next current_colour = nil
        return [@rgb_to, 0] if @index >= @fade.length
        next_colour = @fade[@index]
        @index += 1
        [next_colour, next_colour == @rgb_to ? 0 : @freq]
      end
    end
    
    class FadeTo < Effect
      def initialize to, steps, freq
        @freq, @to, @steps = freq, to, steps
        @fade = nil
      end
      
      def next current_colour
        @fade = Fade.new(current_colour, @to, @steps, @freq) unless @fade        
        @fade.next(current_colour)
      end
    end
  end
end

class Light
  
  attr_accessor :freq, :auditor
  
  include CheekyDreams
  
  def initialize driver
    @driver, @auditor, @effect = driver, dev_null, solid(:off)
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
    @on = true
    @run_thread = Thread.new do
      last_colour, current_effect, freq = COLOURS[:off], nil, nil
      while @on
        start = Time.now
        @lock.synchronize { current_effect = @effect }
        begin
          new_colour, freq = current_effect.next last_colour
          @driver.go new_colour
          @auditor.audit :colour_change, new_colour.to_s
          last_colour = new_colour
        rescue => e
          auditor.audit :error, "#{e.message}"
        end
        if freq > 0
          sleep_until (start + (1 / freq.to_f))
        else
          sleep
        end
      end      
    end
  end
  
  def wakeup
    @run_thread.run if @run_thread
  end
end
