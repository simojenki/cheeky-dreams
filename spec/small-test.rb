$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'cheeky-dreams'

require 'rainbow'
# http://www.krazydad.com/makecolors.php
include CheekyDreams

light = Light.new ansi_driver
# light.auditor = stdio_audit
light.go :purple
light.go throb 10, [100,0,0], [255,0,0]

sleep 100

