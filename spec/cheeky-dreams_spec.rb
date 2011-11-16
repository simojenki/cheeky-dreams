require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CheekyDreams do
  
  include CheekyDreams
  
  describe 'sleep_until' do
    describe 'when until is in the past' do
      it "should not sleep" do
        finish = Time.at(0)
        Time.should_receive(:now).and_return(Time.at(1))
        sleep_until finish
      end
    end
    
    describe 'when until is in the future' do
      it "should sleep for expected time" do
        finish = Time.at(13.1)
        Time.should_receive(:now).and_return(Time.at(3.2))
        should_receive(:sleep).with(9.9)
        sleep_until finish
      end
    end
  end
  
  describe "find_dream_cheeky_usb_device" do
    it "should locate the rgb files and return the driver" do
      Dir.should_receive(:glob).with('/sys/devices/**/red').and_return(["/sys/devices/some-crazy-pci-bus-stuff/red"])
      driver = find_dream_cheeky_usb_device
      driver.path.should == "/sys/devices/some-crazy-pci-bus-stuff"
    end
  end
  
  describe "position_between" do
    it "should calculate the position as hole numbers" do
      position_between(100, 102, 0.25).should == 100
      position_between(100, 102, 0.5).should == 101
      position_between(100, 102, 0.75).should == 101
      position_between(100, 102, 1).should == 102
    end
    
    it "should calculate the position" do
      position_between(100, 110, 0.5).should == 105
      position_between(110, 100, 0.5).should == 105
      position_between(100, 0, 0.2).should == 80
      position_between(100, 0, 0.25).should == 75
      position_between(100, 0, 1).should == 0
    end
    
    it "should return the end point when the ration goes above 1" do
      position_between(100, 1, 1.01).should == 1
      position_between(96, 99, 999).should == 99
    end
  end
  
  describe "rgb_between" do
    it "should calculate the position" do
      rgb_between([100, 50, 0], [110, 20, 0], 0.1).should == [101, 47, 0]
    end
  end
  
  describe "rgb" do
    it "should return rgb array for simple colour symbols" do
      rgb(:off).should == [0, 0, 0]
      rgb(:red).should == [255, 0, 0]
      rgb(:green).should == [0, 255, 0]
      rgb(:blue).should == [0, 0, 255]
    end
    
    it "should return an rgb array when given one" do
      rgb([11, 34, 111]).should == [11, 34, 111]
    end

    it "should take var args and return an rgb array" do
      rgb(11, 34, 111).should == [11, 34, 111]
    end
    
    it "should blow up when given meaningless symbol" do
      proc { rgb(:purple_patch) }.should raise_error "Unknown colour 'purple_patch'"
    end
    
    it "should blow up when given array that isnt rgb" do
      proc { rgb(1, 2) }.should raise_error "Invalid rgb [1, 2]"
      proc { rgb([1, 2, 3, 4]) }.should raise_error "Invalid rgb [1, 2, 3, 4]"
      proc { rgb(["a", "b", "c"]) }.should raise_error 'Invalid rgb ["a", "b", "c"]'
    end
    
    it "should blow up when given invalid rgb values" do
      proc { rgb([0, 256,   0]) }.should raise_error "Invalid rgb value 0, 256, 0"
      proc { rgb([-1,  0,   0]) }.should raise_error "Invalid rgb value -1, 0, 0"
      proc { rgb([0,   0, 256]) }.should raise_error "Invalid rgb value 0, 0, 256"
    end
    
    it "should floor values" do
      rgb(2.4, 0.1, 255.3).should == [2, 0, 255]
    end
    
    describe "creating with values out of range" do
      it "should blow up" do
        proc {  rgb(-1, 0, 0) }.should raise_error "Invalid rgb value -1, 0, 0"
        proc {  rgb(256, 0, 0) }.should raise_error "Invalid rgb value 256, 0, 0"
        proc {  rgb(0, -1, 0) }.should raise_error "Invalid rgb value 0, -1, 0"
        proc {  rgb(0, 256, 0) }.should raise_error "Invalid rgb value 0, 256, 0"
        proc {  rgb(0, 0, -1) }.should raise_error "Invalid rgb value 0, 0, -1"
        proc {  rgb(0, 0, 256) }.should raise_error "Invalid rgb value 0, 0, 256"
      end
    end    
  end
  
  describe 'effects' do

    include CheekyDreams
    
    describe 'off' do
      before :each do
        @off = off
      end

      it "should return [0,0,0] every time called" do
        @off.next.should == COLOURS[:off]
        @off.next.should == COLOURS[:off]
        @off.next.should == COLOURS[:off]
      end
    end

    describe CheekyDreams::Effects::Solid, 'solid' do
      describe "when is symbols" do
        before :each do
          @solid = solid :purple
        end

        it "should return rgb every time called" do
          @solid.next.should == COLOURS[:purple]
          @solid.next.should == COLOURS[:purple]
          @solid.next.should == COLOURS[:purple]
        end
      end

      describe "when is random rgb value" do
        before :each do
          @solid = solid [123, 123, 123]
        end

        it "should return rgb every time called" do
          @solid.next.should == [123, 123, 123]
          @solid.next.should == [123, 123, 123]
          @solid.next.should == [123, 123, 123]
        end
      end
    end

    describe CheekyDreams::Effects::Cycle do
      before :each do
        @cycle = cycle [:red, :blue, [211, 192, 101]], 22
      end

      it "should have a frequency" do
        @cycle.freq.should == 22
      end

      it "should cycle through the colours as rgb" do
        @cycle.next.should == [255,   0,   0]
        @cycle.next.should == [  0,   0, 255]
        @cycle.next.should == [211, 192, 101]

        @cycle.next.should == [255,   0,   0]
        @cycle.next.should == [  0,   0, 255]
        @cycle.next.should == [211, 192, 101]

        @cycle.next.should == [255,   0,   0]
        @cycle.next.should == [  0,   0, 255]
        @cycle.next.should == [211, 192, 101]
      end
    end

    describe CheekyDreams::Effects::Fade do
      describe "fading between two symbols" do
        before :each do
          @fade = fade :blue, :green, 1, 5
        end

        it "should have a freq of 2" do
          @fade.freq.should == 5
        end

        it "should be able to provide the steps when asked" do
          @fade.next.should == [  0,   0, 255]
          @fade.next.should == [  0, 255,   0]
          @fade.next.should == [  0, 255,   0]
          @fade.next.should == [  0, 255,   0]
        end
      end

      describe "fading between two arbitary rgb values" do
        before :each do
          @fade = fade [100, 100, 100], [110, 90, 0], 10, 2
        end

        it "should have a freq of 2" do
          @fade.freq.should == 2
        end

        it "should be able to provide the steps when asked" do
          @fade.next.should == [100, 100, 100]
          @fade.next.should == [101,  99,  90]
          @fade.next.should == [102,  98,  80]
          @fade.next.should == [103,  97,  70]
          @fade.next.should == [104,  96,  60]
          @fade.next.should == [105,  95,  50]
          @fade.next.should == [106,  94,  40]
          @fade.next.should == [107,  93,  30]
          @fade.next.should == [108,  92,  20]
          @fade.next.should == [109,  91,  10]
          @fade.next.should == [110,  90,   0]
          # and then continue to provide the same colour
          @fade.next.should == [110,  90,   0]
          @fade.next.should == [110,  90,   0]
        end  
      end
    end

    describe CheekyDreams::Effects::FadeTo do
      describe "fading to a symbol" do
        before :each do
          @fade_to = fade_to :green, 11, 2
        end

        it "should have a freq of 2" do
          @fade_to.freq.should == 2
        end

        it "should be able to gradually go to colour when asked" do
          @fade_to.next([0, 145, 0]).should == [0, 145, 0]
          @fade_to.next([0, 155, 0]).should == [0, 155, 0]
          @fade_to.next([0, 165, 0]).should == [0, 165, 0]
          @fade_to.next([0, 165, 0]).should == [0, 175, 0]
          @fade_to.next([0, 175, 0]).should == [0, 185, 0]
          @fade_to.next([0, 185, 0]).should == [0, 195, 0]
          @fade_to.next([0, 195, 0]).should == [0, 205, 0]
          @fade_to.next([0, 205, 0]).should == [0, 215, 0]
          @fade_to.next([0, 215, 0]).should == [0, 225, 0]
          @fade_to.next([0, 225, 0]).should == [0, 235, 0]
          @fade_to.next([0, 235, 0]).should == [0, 245, 0]
          @fade_to.next([0, 245, 0]).should == [0, 255, 0]
        end
      end

      describe "fading to a random rgb" do
        before :each do
          @fade_to = fade_to [130, 80, 170], 3, 20
        end

        it "should have a freq of 20" do
          @fade_to.freq.should == 20
        end

        it "should be able to gradually go to colour when asked" do
          @fade_to.next([190, 77, 140]).should == [190, 77, 140]
          @fade_to.next([190, 77, 140]).should == [170, 78, 150]
          @fade_to.next([170, 78, 150]).should == [150, 79, 160]
          @fade_to.next([150, 79, 160]).should == [130, 80, 170]
        end
      end
    end

    describe CheekyDreams::Effects::Func do
      describe "when the block return rgb values" do
        before :each do
          @func = func(22) { |current_colour| [current_colour[0] + 1, current_colour[1] + 1, current_colour[2] + 1] }
        end

        it "should have a freq of 22" do
          @func.freq.should == 22
        end

        it "should return the given rgb plus 1 to each of r, g, and b" do
          @func.next([2, 5, 6]).should == [3, 6, 7]
        end
      end

      describe "when the block return symbol" do
        before :each do
          @func = func(22) { |current_colour| :purple }
        end

        it "should return the rgb for the symbol" do
          @func.next([2, 5, 6]).should == COLOURS[:purple]
        end
      end
    end

    describe CheekyDreams::Effects::Throb do
      before :each do
        @throb = throb 10, [100, 100, 100], [250, 50, 0]
      end

      it "should have r_amp" do
        @throb.r_amp.should == 75
      end

      it "should have r_centre" do
        @throb.r_centre.should == 175
      end

      it "should have g_amp" do
        @throb.g_amp.should == 25
      end

      it "should have g_centre" do
        @throb.g_centre.should == 75
      end

      it "should have b_amp" do
        @throb.b_amp.should == 50
      end

      it "should have b_centre" do
        @throb.b_centre.should == 50
      end
    end
  end
end

module CheekyDreams
  describe FilteringAuditor do
    before :each do
      @delegate = mock('delegate auditor')
      @auditor = FilteringAuditor.new @delegate, [:error]
    end
    
    it 'should allow through audits of type :error' do
      @delegate.should_receive(:audit).with(:error, 'here')
      @auditor.audit :error, 'here'
    end
    
    it 'should not allow through other random audits' do
      @auditor.audit :error1, 'here'
      @auditor.audit :error2, 'here'
    end
  end
  
  describe CompositeAuditor do
    before :each do
      @auditor1, @auditor2 = mock('auditor1'), mock('auditor2')
      @auditor = CompositeAuditor.new @auditor1, @auditor2
    end
    
    it 'should notify both auditors' do
      @auditor1.should_receive(:audit).with(:bob, 'marley')
      @auditor2.should_receive(:audit).with(:bob, 'marley')
      @auditor.audit :bob, 'marley'
    end
  end
  
  describe StdIOAuditor do
    before :each do
      @out, @err = StringIO.new, StringIO.new
      @auditor = StdIOAuditor.new(@out, @err)
    end
    
    it 'should report :error to stderr, with newlines between each one' do
      @auditor.audit :error, "damn"
      @auditor.audit :error, "this"
      @out.string.should == ""
      @err.string.should == "error - damn\nerror - this\n"
    end
    
    it 'should report other symbols to stdout, with newlines between each one' do
      @auditor.audit :mmmm, "beer"
      @auditor.audit :tastes, "good"
      @out.string.should == "mmmm - beer\ntastes - good\n"
      @err.string.should == ""
    end
  end
end

module CheekyDreams::Dev
  
  include CheekyDreams
  
  describe IO do
  	before :each do
  		@io = StringIO.new
  		@device = IO.new @io
  	end
  	
  	it 'should write colour' do
  		@device.go [1, 5, 6]
  		@io.string.should == "[1,5,6]\n"
  	end
  	
   	it 'should write colour only once when doesnt change' do
  		@device.go [1, 5, 6]
  		@device.go [4, 4, 4]
  		@device.go [4, 4, 4]
  		@device.go [2, 3, 4]
  		@io.string.should == "[1,5,6]\n[4,4,4]\n[2,3,4]\n"
  	end
	end
  
  describe DreamCheeky do
    before :each do
      @device_path = "/device"
    end

    describe "when cannot write to the files" do
      before :each do
        @device = DreamCheeky.new @device_path, 255
      end

      describe "making it go 123,34,255" do
        before :each do
          @device.should_receive(:system).with("echo 123 > /device/red").and_return false
        end

        it "should turn the light the correct colours" do
          lambda { @device.go [123, 34, 255] }.should raise_error "Failed to update /device/red, do you have permissions to write to that file??"
        end
      end
    end
    
    describe "when the max threshold is 100" do
      before :each do
        @device = DreamCheeky.new @device_path, 100
      end

      describe "making it go 123,34,255" do
        before :each do
          @device.should_receive(:system).with("echo 48 > /device/red").and_return(true)
          @device.should_receive(:system).with("echo 13 > /device/green").and_return(true)
          @device.should_receive(:system).with("echo 100 > /device/blue").and_return(true)
        end

        it "should turn the light the correct colours" do
          @device.go [123, 34, 255]
        end
      end
      
      describe "making it go 0,1,100" do
        before :each do
          @device.should_receive(:system).with("echo 0 > /device/red").and_return(true)
          @device.should_receive(:system).with("echo 0 > /device/green").and_return(true)
          @device.should_receive(:system).with("echo 39 > /device/blue").and_return(true)
        end

        it "should turn the light the correct colours" do
          @device.go [0, 1, 100]
        end
      end
    end
    
    describe "when the max threshold is 255" do
      before :each do
        @device = DreamCheeky.new @device_path, 255
      end

      describe "making it go 123,34,255" do
        before :each do
          @device.should_receive(:system).with("echo 123 > /device/red").and_return(true)
          @device.should_receive(:system).with("echo 34 > /device/green").and_return(true)
          @device.should_receive(:system).with("echo 255 > /device/blue").and_return(true)
        end

        it "should turn the light the correct colours" do
          @device.go [123, 34, 255]
        end
      end
    end
  end
end

describe Light do
  
  include CheekyDreams
  include Within
  
  before :each do
    @driver = StubDriver.new
    @light = Light.new @driver
    @collecting_auditor = CollectingAuditor.new
    @audit_errors = filtering([:error], stdio_audit)
    @light.auditor = audit_to @audit_errors, @collecting_auditor
  end
  
  after :each do
    @light.off
  end
  
  describe "unhandled errors" do
    before :each do
      @error_message = "On purpose error"
      @error = RuntimeError.new @error_message
      @effect = StubEffect.new(20) { raise @error }
      @light.auditor = @collecting_auditor
    end
    
    it 'should notify the auditor' do
      @light.go @effect
      within(2, "auditor should have received ':error - #{@error_message}'") { [@collecting_auditor.has_received?(:error, @error_message), @collecting_auditor.events] }
    end
  end
  
  describe "frequency of effect" do    
    describe 'when frequency is 1' do
      before :each do      
        @effect = StubEffect.new 1
      end
      
      it 'should call the effect almost immediately, and then about 1 second later' do
        @light.go @effect
        sleep 0.1
        @effect.asked_for_colour_count.should be == 1
        sleep 1
        @effect.asked_for_colour_count.should be == 2
      end
    end
    
    describe 'when frequency is 10' do
      before :each do      
        @effect = StubEffect.new 10
      end
      
      it 'should call the effect between 9 and 11 times in the next second' do
        @light.go @effect
        sleep 1
        count = @effect.asked_for_colour_count  
        count.should be <= 11
        count.should be >= 9
      end
    end
    
    describe 'when frequency is 5' do
      before :each do      
        @effect = StubEffect.new 5
      end
      
      it 'should call the effect 5 times in the next second' do
        @light.go @effect
        sleep 1
        count = @effect.asked_for_colour_count  
        count.should be == 5
      end
    end
  end
  
  describe "changing colour" do
    
    include CheekyDreams
    
    it "should tell the auditor" do
      @light.go [22, 11, 33]
      within(1, "auditor should have received ':colour_change - [22, 11, 33]'") { [@collecting_auditor.has_received?(:colour_change, "[22, 11, 33]"), @collecting_auditor.events] }
    end
    
    it "should go red" do
      @light.go :red
      @driver.should_become [255,0,0]
    end
    
    it "should go green" do
      @light.go :green
      @driver.should_become [0,255,0]
    end
    
    it "should go blue" do
      @light.go :blue
      @driver.should_become [0,0,255]
    end
    
    it "should blow up if you give it a symbol it doesnt understand" do
      proc { @light.go :pink_with_polka_dots }.should raise_error "Unknown colour 'pink_with_polka_dots'"
    end
    
    it "should be able to go any rgb" do
      @light.go rgb(211, 222, 0)
      @driver.should_become [211, 222, 0]
    end
    
    it "should be able to go any rgb as just numbers" do
      @light.go [222, 111, 0]
      @driver.should_become [222, 111, 0]
    end
    
    it "should be able to cycle between colours when specified as rgb" do
      @light.go cycle([[255, 255, 255], [200, 200, 200], [100, 100, 100]], 10)
      @driver.should_become [255, 255, 255]
      @driver.should_become [200, 200, 200]
      @driver.should_become [100, 100, 100]
      @driver.should_become [255, 255, 255]
      @driver.should_become [200, 200, 200]
    end
    
    it "should be able to cycle between colours when specified as symbols" do
      @light.go cycle([:red, :green, :blue], 10)
      @driver.should_become :red
      @driver.should_become :green
      @driver.should_become :blue
      @driver.should_become :red
      @driver.should_become :green
    end
    
    it "should be able to fade from one colour to another" do
      @light.go fade([100, 100, 0], [105, 95, 0], 5, 2)
      @driver.should_become [101, 99, 0]
      @driver.should_become [102, 98, 0]      
      @driver.should_become [103, 97, 0]      
      @driver.should_become [104, 96, 0]      
      @driver.should_become [105, 95, 0]      
    end
    
    it "should be able to fade from current colour to a new colour" do
      @light.go [100, 100, 0]
      @driver.should_become [100, 100, 0]
      
      @light.go fade_to([105, 95, 0], 5, 2)
      @driver.should_become [101, 99, 0]
      @driver.should_become [102, 98, 0]      
      @driver.should_become [103, 97, 0]      
      @driver.should_become [104, 96, 0]      
      @driver.should_become [105, 95, 0]      
    end
    
    it "should be able to go different colours based on a function" do
      cycle = [:blue, :red, :green, :purple, :grey, :aqua].cycle
      @light.go func(10) { cycle.next }
      @driver.should_become :blue
      @driver.should_become :red
      @driver.should_become :green
      @driver.should_become :purple
      @driver.should_become :grey
      @driver.should_become :aqua
    end
    
    it "should not wait for an effect to finish if a new one is provided" do
      @light.go fade([100, 0, 0], [110, 0, 0], 10, 2)
      @driver.should_become [101, 0, 0]
      @light.go :red
      @driver.should_become [255, 0, 0]
    end
  end
end
