$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cheeky-dreams'

require 'rainbow'

include CheekyDreams

light = Light.new(ansi_driver)

puts "is it red"
light.go [255,0,0]
sleep 1


puts "colours"
[:red, :green, :blue, CheekyDreams::rgb(155, 155, 155)].each do |colour|
  light.go colour 
  sleep 0.5
end

puts "cycle"
light.go(cycle(CheekyDreams::COLOURS.keys, 2))
sleep 5

puts "fade"
light.go(fade(:green, :red, 20, 2))
sleep 3
light.go(fade(:red, :green, 20, 2))
sleep 3

puts "fade from current to somewhere"
light.go :red
sleep 2
light.go fade_to :green, 20, 2
sleep 2
light.go fade_to :red, 20, 2
sleep 2

puts "colour on block"
cycle = [:blue, :purple].cycle
light.go(func(2) { cycle.next })
sleep 3

puts "fake cpu cycles"
green = 100
light.go(func(2) { [0, green+=20, 0] })
sleep 3


puts "throbbing"
light.go(throb(1, 127, 128))
sleep 10

puts "done"
