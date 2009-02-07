# begin
#   require "osx/cocoa"
# rescue Exception=>e
#   puts "Caught an exception"
# end
def actionProperty
  return "label-click"
end

def actionEnable(withValue, forValue)
  return true
end

def actionTitle(withValue, forValue)
  return "Ruby example"
end

def actionPerform(withValue, forValue)
  puts withValue
end