require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CheekyDreams do
  describe "position_between" do
    it "should calculate the position as hole numbers" do
      CheekyDreams.position_between(100, 102, 0.25).should == 100
      CheekyDreams.position_between(100, 102, 0.5).should == 101
      CheekyDreams.position_between(100, 102, 0.75).should == 101
      CheekyDreams.position_between(100, 102, 1).should == 102
    end
    
    it "should calculate the position" do
      CheekyDreams.position_between(100, 110, 0.5).should == 105
      CheekyDreams.position_between(110, 100, 0.5).should == 105
      CheekyDreams.position_between(100, 0, 0.2).should == 80
      CheekyDreams.position_between(100, 0, 0.25).should == 75
      CheekyDreams.position_between(100, 0, 1).should == 0
    end
    
    it "should return the end point when the ration goes above 1" do
      CheekyDreams.position_between(100, 1, 1.01).should == 1
      CheekyDreams.position_between(96, 99, 999).should == 99
    end
  end
  
  describe "rgb_between" do
    it "should calculate the position" do
      CheekyDreams.rgb_between([100, 50, 0], [110, 20, 0], 0.1).should == [101, 47, 0]
    end
  end
end

describe Light do
  
  include CheekyDreams
  
  describe "changing colour" do
    before :each do
      @driver = StubDriver.new
      @light = Light.new @driver, 5
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
