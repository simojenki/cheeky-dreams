$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cheeky-dreams'

require 'rainbow'

include CheekyDreams

light = Light.new ansi_driver
light.auditor = stderr_auditor
light.go :purple
light.crazy 10, 20

sleep 100

