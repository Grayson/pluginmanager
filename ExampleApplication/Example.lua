function actionProperty()
	return "label-click"
end

function actionEnable( withValue, forValue )
	return true
end

function actionTitle( withValue, forValue )
	return "Lua test"
end

function actionPerform( withValue, forValue )
	print(withValue:description())
end