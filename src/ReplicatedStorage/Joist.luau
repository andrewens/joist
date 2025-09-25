-- const
local INFO_PRE_MESSAGE = "[JOIST]: "

-- private
local function logInfo(message, MessageArray)
	if MessageArray then
		table.insert(MessageArray, message)

		return MessageArray
	end

	print(INFO_PRE_MESSAGE .. message)
end

local function logError(message, MessageArray)
	if MessageArray then
		table.insert(MessageArray, message)

		return MessageArray
	end

	warn(INFO_PRE_MESSAGE .. message)
end

local function doServerMethod(Server, methodName, ...)
	local method = Server[methodName]
	if method == nil then
		return false, `Server has no method named "{methodName}"!`
	end

	local methodType = typeof(method)
	if methodType ~= "function" then
		return false, `Server.{methodName} is not a function! It's a {methodType}`
	end

	return pcall(method, Server, ...)
end

local function assertServerProperty(Server, propertyName, value)
	local s, result = doServerMethod(Server, "Get" .. propertyName)
	if not s then
		return false, result
	end

	if result ~= value then -- TODO: fuzzy and custom equality operations
		return false, `Server:Get{propertyName}() returned {result}, which isn't {value}!`
	end

	return true
end

local function setServerProperty(Server, propertyName, value)
	local s, result = doServerMethod(Server, "Set" .. propertyName, value)
	if not s then
		return false, result
	end

	s, result = assertServerProperty(Server, propertyName, value)
	if not s then
		return false, `After calling Server:Set{propertyName}({value}), {result}`
	end

	return true
end

-- testing API
local function newObjectOfType(TestState, objectTypeName, InitialState)
	if not (typeof(objectTypeName) == "string") then
		error(`{objectTypeName} is not a string!\n{debug.traceback()}`)
	end
	if not (typeof(InitialState) == "table") then
		error(`{InitialState} is not a table!\n{debug.traceback()}`)
	end

	if objectTypeName == "Game" then
		for propertyName, value in InitialState do
			if not (typeof(propertyName) == "string") then
				error(`{propertyName} is not a string! (in Object.{objectTypeName}[{propertyName}])`)
			end

			TestState.numTestConditions += 1

			local s, errorMessage = setServerProperty(TestState.Server, propertyName, value)
			if not s then
				logError(errorMessage .. `\n{debug.traceback()}`, TestState.MessageArray)
				continue
			end

			TestState.numConditionsPassed += 1
		end

		return
	end

	if objectTypeName == "Player" then
		return
	end

	-- TODO: all other types
end

local function readObjectState(TestState, objectTypeName, objectId, ExpectedState)
	if not (typeof(objectTypeName) == "string") then
		error(`{objectTypeName} is not a string!\n{debug.traceback()}`)
	end
	if not (typeof(ExpectedState) == "table") then
		error(`{ExpectedState} is not a table!\n{debug.traceback()}`)
	end

	if objectTypeName == "Game" then
		for propertyName, value in ExpectedState do
			if not (typeof(propertyName) == "string") then
				error(`{propertyName} is not a string! (in Object.{objectTypeName}[{propertyName}])`)
			end

			TestState.numTestConditions += 1

			local s, errorMessage = assertServerProperty(TestState.Server, propertyName, value)
			if not s then
				logError(errorMessage .. `\n{debug.traceback()}`, TestState.MessageArray)
				continue
			end

			TestState.numConditionsPassed += 1
		end

		return
	end
end

local function doAction(TestState, actionName, ...)
	TestState.numTestConditions += 1

	local s, result = doServerMethod(TestState.Server, actionName, ...)
	if not s then
		logError(result .. `\n{debug.traceback()}`, TestState.MessageArray)
		return
	end

	TestState.numConditionsPassed += 1
end

local function runTest(MessageArray, Api, testFunction)
	-- test state
	local TestState = {}

	TestState.numTestConditions = 0
	TestState.numConditionsPassed = 0

	TestState.ObjectTypeToIndexToHandle = {} -- string objectType --> int index --> <any> objectHandle
	TestState.ObjectTypeToLastIndexCreated = {} -- string objectType --> int lastIndexCreated
	TestState.ObjectTypeToLastIndexRead = {} -- string objectType --> int lastIndexRead

	TestState.MessageArray = MessageArray

	-- load server
	if typeof(Api.newServer) ~= "function" then
		return -1, 0, `Game API has no method "newServer"!`
	end

	local s, result = pcall(Api.newServer)
	if not s then
		return -1, 0, `Game API newServer() threw error:\n{result}`
	end

	TestState.Server = result

	-- testing interface objects
	local Object = setmetatable({}, {
		__index = function(_, objectTypeName)
			return function(...)
				return readObjectState(TestState, objectTypeName, nil, ...)
			end
		end,
	})

	local NewObject = setmetatable({}, {
		__index = function(_, objectTypeName)
			return function(...)
				return newObjectOfType(TestState, objectTypeName, ...)
			end
		end,
	})

	local ServerAction = setmetatable({}, {
		__index = function(_, actionName)
			return function(...)
				doAction(TestState, actionName, ...)
			end
		end,
	})

	-- run test
	s, result = pcall(testFunction, ServerAction, Object, NewObject)
	local errorMessage = if not s then result else nil

	return TestState.numTestConditions, TestState.numConditionsPassed, errorMessage
end

-- public
local Joist = {}

function Joist.runTests(ApiModuleScript, TestsFolder, Options)
	Options = Options or {}

	if not (typeof(ApiModuleScript) == "Instance" and ApiModuleScript:IsA("ModuleScript")) then
		error(`{ApiModuleScript} is not a ModuleScript!`)
	end
	if not (typeof(TestsFolder) == "Instance" and TestsFolder:IsA("Folder")) then
		error(`{TestsFolder} is not a Folder!`)
	end
	if not (typeof(Options) == "table") then
		error(`{Options} is not a table!`)
	end

	local MessageArray = if Options.OutputMode == "ReturnTable" then {} else nil
	local ONLY_TEST_SPEC_MODULES = if Options.OnlyTestSpecModules == nil then true else Options.OnlyTestSpecModules

	local success, Api = pcall(require, ApiModuleScript)
	if not success then
		return logError(`Failed to require {ApiModuleScript} with error:\n{Api}\n{debug.traceback()}`, MessageArray)
	end

	local numTestsRan = 0
	local numTestsPassed = 0

	for _, TestModuleScript in TestsFolder:GetChildren() do
		local moduleName = TestModuleScript.Name
		if ONLY_TEST_SPEC_MODULES and string.sub(moduleName, moduleName:len() - 4, moduleName:len()) ~= ".spec" then
			continue
		end

		if not TestModuleScript:IsA("ModuleScript") then
			continue
		end

		numTestsRan += 1

		local s, testFunction = pcall(require, TestModuleScript)
		if not s then
			logError(
				`(#{numTestsRan}) Failed to require TestModule "{moduleName}" with error:\n{testFunction}`,
				MessageArray
			)
			continue
		end

		local totalConditions, passedConditions, errorMessage = runTest(MessageArray, Api, testFunction)
		if errorMessage == nil and totalConditions == passedConditions then
			logInfo(`(#{numTestsRan}) Test "{moduleName}" passed! ({totalConditions} checks)`, MessageArray)
			numTestsPassed += 1

			continue
		end

		if errorMessage == nil then
			logInfo(
				`(#{numTestsRan}) Test "{moduleName}" failed ({passedConditions} checks correct, {totalConditions - passedConditions} checks failed)`,
				MessageArray
			)
			continue
		end

		if totalConditions < 0 then
			logError(`(#{numTestsRan}) Test "{moduleName}" failed with error:\n{errorMessage}`, MessageArray)
			continue
		end

		logError(
			`(#{numTestsRan}) Test "{moduleName}" passed {passedConditions} / {totalConditions} conditions and failed to complete with error:\n{errorMessage}`,
			MessageArray
		)
	end

	if numTestsRan <= 0 then
		return numTestsRan, numTestsPassed, logInfo(`No tests to run!`, MessageArray)
	end

	logInfo(`{numTestsPassed} / {numTestsRan} tests passed`, MessageArray)

	return numTestsRan, numTestsPassed, MessageArray
end

function Joist.initializeJoist() end

return Joist
