require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CheekyDreams do
  
  include CheekyDreams
  
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
  
  describe "rgb_for" do
    it "should return rgb array for simple colours" do
      rgb_for(:red).should == [255, 0, 0]
      rgb_for(:green).should == [0, 255, 0]
      rgb_for(:blue).should == [0, 0, 255]
    end
    
    it "should return an rgb array when given one" do
      rgb_for([11, 34, 111]).should == [11, 34, 111]
    end
    
    it "should blow up when given meaningless symbol" do
      lambda { rgb_for(:purple_patch) }.should raise_error "Unknown colour 'purple_patch'"
    end
    
    it "should blow up when given array that isnt rgb" do
      lambda { rgb_for([1]) }.should raise_error "Invalid rgb [1]"
      lambda { rgb_for([1, 2, 3, 4]) }.should raise_error "Invalid rgb [1, 2, 3, 4]"
      lambda { rgb_for(["a", "b", "c"]) }.should raise_error 'Invalid rgb ["a", "b", "c"]'
    end
    
    it "should blow up when given invalid rgb values" do
      lambda { rgb_for([0, 256,   0]) }.should raise_error "Invalid rgb value 0, 256, 0"
      lambda { rgb_for([-1,  0,   0]) }.should raise_error "Invalid rgb value -1, 0, 0"
      lambda { rgb_for([0,   0, 256]) }.should raise_error "Invalid rgb value 0, 0, 256"
    end
  end
end

module CheekyDreams::Effect
  
  include CheekyDreams
  
  describe Solid do
    describe "when is symbols" do
      before :each do
        @solid = Solid.new :purple
      end

      it "should return rgb every time called" do
        @solid.next.should == COLOURS[:purple]
        @solid.next.should == COLOURS[:purple]
        @solid.next.should == COLOURS[:purple]
      end
    end
    
    describe "when is random rgb value" do
      before :each do
        @solid = Solid.new [123, 123, 123]
      end

      it "should return rgb every time called" do
        @solid.next.should == [123, 123, 123]
        @solid.next.should == [123, 123, 123]
        @solid.next.should == [123, 123, 123]
      end
    end
  end
  
  describe Cycle do
    before :each do
      @cycle = Cycle.new [:red, :blue, [211, 192, 101]], 22
    end
    
    it "should have a frequency" do
      @cycle.freq.should == 22
    end
    
    it "should cycle through the colours as rgb" do
      @cycle.next.should == [255,   0,  0]
      @cycle.next.should == [  0,   0,255]
      @cycle.next.should == [211, 192, 101]
      
      @cycle.next.should == [255,   0,  0]
      @cycle.next.should == [  0,   0,255]
      @cycle.next.should == [211, 192, 101]
      
      @cycle.next.should == [255,   0,  0]
      @cycle.next.should == [  0,   0,255]
      @cycle.next.should == [211, 192, 101]
    end
  end
  
  describe Fade do
    describe "fading between two symbols" do
      before :each do
        @fade = Fade.new :blue, :green, 1, 5
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
        @fade = Fade.new [100, 100, 100], [110, 90, 0], 10, 2
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
end

describe Light do
  
  include CheekyDreams
  include Within
  
  before :each do
    @driver = StubDriver.new
    @light = Light.new @driver
  end
  
  describe "unhandled errors" do
    before :each do
      @error = RuntimeError.new "On purpose error"
      @effect = StubEffect.new(20) { raise @error }
      @auditor = CollectingAuditor.new
      @light.auditor = @auditor
    end
    
    it 'should notify the auditor' do
      @light.go @effect
      within(1, "auditor should have received '#{@error}'") { [@auditor.has_received?(@error), @auditor.errors] }
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
      lambda { @light.go :pink_with_polka_dots }.should raise_error "Unknown colour 'pink_with_polka_dots'"
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
      @light.go fade([100, 100, 0], [105, 95, 0], 1)
      @driver.should_become [101, 98, 0]
      @driver.should_become [102, 97, 0]      
      @driver.should_become [103, 96, 0]      
      @driver.should_become [104, 95, 0]      
      @driver.should_become [105, 95, 0]      
    end
    
    it "should be able to fade from current colour to a new colour" do
      @light.go [100, 100, 0]
      @driver.should_become [100, 100, 0]
      @light.go fade_to([105, 95, 0], 1)
      @driver.should_become [101, 98, 0]
      @driver.should_become [102, 97, 0]      
      @driver.should_become [103, 96, 0]      
      @driver.should_become [104, 95, 0]      
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
    
  end
end

describe "RGB" do
  include CheekyDreams
  
  describe "creating with values out of range" do
    it "should blow up" do
      lambda {  rgb(-1, 0, 0) }.should raise_error "Invalid rgb value -1, 0, 0"
      lambda {  rgb(256, 0, 0) }.should raise_error "Invalid rgb value 256, 0, 0"
      lambda {  rgb(0, -1, 0) }.should raise_error "Invalid rgb value 0, -1, 0"
      lambda {  rgb(0, 256, 0) }.should raise_error "Invalid rgb value 0, 256, 0"
      lambda {  rgb(0, 0, -1) }.should raise_error "Invalid rgb value 0, 0, -1"
      lambda {  rgb(0, 0, 256) }.should raise_error "Invalid rgb value 0, 0, 256"
    end
  end
end
