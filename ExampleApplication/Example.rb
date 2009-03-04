def actionProperty
  puts "Inside actionProperty"
  "label-click"
end

def actionEnable(withValue, forValue)
  true
end

def actionTitle(withValue, forValue)
  return "Ruby example"
end

def actionPerform(withValue, forValue)
  puts withValue
  puts forValue
end
