require 'osx/cocoa'

def actionProperty()
  return "label-click"
end

def actionEnable(withValue, forValue)
  return true
end

def actionTitle(withValue, forValue)
  return "Ruby example"
end

def actionEnable(withValue, forValue)
  puts withValue
end
