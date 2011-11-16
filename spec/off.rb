$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cheeky-dreams'

include CheekyDreams

light = Light.new find_dream_cheeky_usb_device

light.go [255,0,0]
