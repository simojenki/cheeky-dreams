require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Light do
  
  include CheekyDreams
  
  describe "changing colour" do
    before :each do
      @driver = mock('driver')
      @light = Light.new @driver
    end
    
    it "should go red" do
      @driver.should_receive(:go).with([255,0,0])
      @light.go :red
    end
    
    it "should go green" do
      @driver.should_receive(:go).with([0,255,0])
      @light.go :green
    end
    
    it "should go blue" do
      @driver.should_receive(:go).with([0,0,255])
      @light.go :blue
    end
    
    it "should blow up if you give it a symbol it doesnt understand" do
      lambda { @light.go :pink_with_polka_dots }.should raise_error "Unknown colour 'pink_with_polka_dots'"
    end
    
    it "should be able to go any rgb" do
      @driver.should_receive(:go).with([211, 222, 0])
      @light.go rgb(211, 222, 0)
    end
    
    it "should be able to go any rgb as just numbers" do
      @driver.should_receive(:go).with([222, 111, 0])
      @light.go [222, 111, 0]
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
