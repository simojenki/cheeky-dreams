$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cheeky-dreams'

require 'rainbow'

include CheekyDreams

light = Light.new(ansi_driver, 10)
light.on

puts "colours"
[:red, :green, :blue, CheekyDreams::rgb(155, 155, 155)].each do |colour|
  light.go colour 
  sleep 0.5
end

puts "cycle"
light.go(cycle(CheekyDreams::COLOURS.keys, 2))
sleep 5

puts "fade"
light.go(fade(:green, :red, 2))
sleep 3
light.go(fade(:red, :green, 2))
sleep 3

puts "fade from current to somewhere"

puts "shouldnt need to turn the light on"

puts "colour on block"
cycle = [:blue, :purple].cycle
light.go(func(2) { cycle.next })
sleep 3

puts "fake cpu cycles"
green = 100
light.go(func(2) { [0, green+=20, 0] })
sleep 3

puts "done"
