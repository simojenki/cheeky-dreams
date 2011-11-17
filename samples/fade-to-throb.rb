$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'cheeky-dreams'

include CheekyDreams

light = Light.new ansi_driver
light.auditor = forward(:error => suppress_duplicates(stdio_audit))
light.go crazy
sleep 10
light.go(light_show(fade_to(:red), throbbing(:red)))
sleep 100

