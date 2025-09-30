-- const
local INFO_PRE_MESSAGE = "[JOIST]: "

-- private
local function countDictionary(t)
	local c = 0
	for k, v in t do
		c += 1
	end

	return c
end

local function argToString(v)
	if typeof(v) == "string" then
		local quoteType = if string.find(v, '"') then "'" else '"'
		return quoteType .. v .. quoteType
	end

	return tostring(v)
end

local function argsToString(...) -- TODO: idk if there's a better way to do this lol
	local a1, a2, a3, a4, a5, a6 = ...

	if a6 == nil and a5 == nil and a4 == nil and a3 == nil and a2 == nil then
		return argToString(a1)
	end

	if a6 == nil and a5 == nil and a4 == nil and a3 == nil then
		return argToString(a1) .. ", " .. argToString(a2)
	end

	if a6 == nil and a5 == nil and a4 == nil then
		return argToString(a1) .. ", " .. argToString(a2) .. ", " .. argToString(a3)
	end

	if a6 == nil and a5 == nil then
		return argToString(a1) .. ", " .. argToString(a2) .. ", " .. argToString(a3) .. ", " .. argToString(a4)
	end

	if a6 == nil then
		return argToString(a1)
			.. ", "
			.. argToString(a2)
			.. ", "
			.. argToString(a3)
			.. ", "
			.. argToString(a4)
			.. ", "
			.. argToString(a5)
	end

	return argToString(a1)
		.. ", "
		.. argToString(a2)
		.. ", "
		.. argToString(a3)
		.. ", "
		.. argToString(a4)
		.. ", "
		.. argToString(a5)
		.. ", "
		.. argToString(a6)
end

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

local function doMethod(Interface: table, interfaceName: string, methodName: string, ...)
	-- guards
	if not (typeof(Interface) == "table") then
		error(`{Interface} is not a table!\n{debug.traceback()}`)
	end
	if not (typeof(interfaceName) == "string") then
		error(`{interfaceName} is not a string!\n{debug.traceback()}`)
	end
	if not (typeof(methodName) == "string") then
		error(`{methodName} is not a string!\n{debug.traceback()}`)
	end

	-- stuff
	local method = Interface[methodName]
	if method == nil then
		return false, `{interfaceName} has no method named "{methodName}"!`
	end

	local methodType = typeof(method)
	if methodType ~= "function" then
		return false, `{interfaceName}.{methodName} is not a function! It's a {methodType}`
	end

	local s, result, r2, r3, r4 = pcall(method, ...)
	if not s then
		local firstArg = ...
		local dot = if firstArg == Interface then ":" else "."
		return false, `{interfaceName}{dot}{methodName}({argsToString(...)}) threw error:\n{result}`
	end

	return s, result, r2, r3, r4
end

local function doGameApiMethod(Api, methodName, ...)
	return doMethod(Api, "GameAPI", methodName, ...)
end

local function doServerMethod(Server, methodName, ...)
	return doMethod(Server, "Server", methodName, Server, ...)
end

local function doClientMethod(Client, methodName, ...)
	return doMethod(Client, "Client", methodName, Client, ...)
end

local function assertServerProperty(Server, propertyName, value)
	-- @param: value can be a function of the property, returning boolean if it's correct and an error message string
	-- 			(the error message should complete the phrase "Server:Get{propertyName}() returned {result}, which")

	local s, result = doServerMethod(Server, "Get" .. propertyName)
	if not s then
		return false, result
	end

	if typeof(value) == "function" then
		local s2, errorMessage = value(result)
		if not s2 then
			return false, `Server:Get{propertyName}() returned {argsToString(result)}, which {errorMessage}`
		end

		return true
	end

	if result ~= value then -- TODO: fuzzy and custom equality operations
		return false, `Server:Get{propertyName}() returned {argsToString(result)}, which isn't {argsToString(value)}!`
	end

	return true
end

local function isEqual(expectedValue, actualValue, methodString)
	if typeof(expectedValue) == "function" then
		local s2, errorMessage = expectedValue(actualValue)
		if not s2 then
			return false, `{methodString} returned {argsToString(actualValue)}, which {errorMessage}`
		end

		return true
	end

	if actualValue ~= expectedValue then -- TODO: fuzzy and custom equality operations
		return false, `{methodString} returned {argsToString(actualValue)}, which isn't {argsToString(expectedValue)}!` --{nameErrorMessage}`
	end

	return true
end

local function assertObjectPropertyOnClient(Client, objectId, objectTypeName, propertyName, expectedValue)
	local getterMethodName = "Get" .. objectTypeName .. propertyName
	local s, result = doClientMethod(Client, getterMethodName, objectId)
	if not s then
		return false, result
	end

	local getterMethodNameWithArgs = getterMethodName .. "(" .. argsToString(objectId) .. ")"
	s, result = isEqual(expectedValue, result, `Client:{getterMethodNameWithArgs}`)
	if not s then
		return false, result
	end

	return true
end

local function assertObjectProperty(TestState, objectId, objectTypeName, propertyName, expectedValue)
	local getterMethodName = "Get" .. objectTypeName .. propertyName
	local s, result = doServerMethod(TestState.Server, getterMethodName, objectId)
	if not s then
		return false, result
	end

	-- TODO: support printing object names or metadata or something
	-- property must be same on Server
	local getterMethodNameWithArgs = getterMethodName .. "(" .. argsToString(objectId) .. ")"
	s, result = isEqual(expectedValue, result, `Server:{getterMethodNameWithArgs}`)
	if not s then
		return false, result
	end

	-- TODO: will need to support Server-only or Client-only states at some point
	-- property must be same on all Clients
	for i, Client in TestState.Clients do
		s, result = assertObjectPropertyOnClient(Client, objectId, objectTypeName, propertyName, expectedValue)
		if not s then
			return false, result
		end
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
		return false, `After calling Server:Set{propertyName}({argsToString(value)}), {result}`
	end

	return true
end

local function setObjectProperty(TestState, objectId, objectTypeName, propertyName, value)
	local s, result = doServerMethod(TestState.Server, "Set" .. objectTypeName .. propertyName, objectId, value)
	if not s then
		return false, result
	end

	s, result = assertObjectProperty(TestState, objectId, objectTypeName, propertyName, value)
	if not s then
		local huh = argsToString(objectId, value)
		print("HUH?", huh, "|", objectId, value)
		return false, `After calling Server:Set{objectTypeName}{propertyName}({huh}), {result}`
	end

	return true
end

local function createNewObject(Server, objectTypeName, ...)
	local s, result = doServerMethod(Server, "NewObject", objectTypeName, ...)
	if not s then
		return false, result
	end

	if result == nil then
		return false, `Server:NewObject("{objectTypeName}") returned nil!`
	end

	return true, result
end

local function doCheck(TestState, condition, errorMessage)
	if not (typeof(TestState) == "table" and TestState.numTestConditions and TestState.numConditionsPassed) then
		error(`{TestState} is not a TestState!\n{debug.traceback()}`)
	end
	if not (typeof(condition) == "boolean") then
		error(`{condition} is not a boolean!`)
	end
	if not (typeof(errorMessage) == "string") then
		error(`{errorMessage} is not a string!`)
	end

	TestState.numTestConditions += 1

	if not condition then
		logError(errorMessage, TestState.MessageArray)
		return false
	end

	TestState.numConditionsPassed += 1

	return true
end

local function callFunctionAndDoCheck(TestState: table, method: () -> any, ...)
	if not (typeof(TestState) == "table" and TestState.numTestConditions and TestState.numConditionsPassed) then
		error(`{TestState} is not a TestState!\n{debug.traceback()}`)
	end
	if not (typeof(method) == "function") then
		error(`{method} is not a function!\n{debug.traceback()}`)
	end

	TestState.numTestConditions += 1

	--local s, result = setObjectProperty(TestState, NewObject, objectTypeName, propertyName, value)
	local s, result = method(...)
	if not s then
		logError(result .. "\n" .. debug.traceback(), TestState.MessageArray)
		return false
	end

	TestState.numConditionsPassed += 1

	return true, result
end

local function isString(objectProperty)
	return typeof(objectProperty) == "string", "isn't a string"
end

-- testing API
local function newObjectOfType(TestState, objectTypeName, InitialState)
	if not (typeof(objectTypeName) == "string") then
		error(`{objectTypeName} is not a string!\n{debug.traceback()}`)
	end
	if not (typeof(InitialState) == "table") then
		error(`{InitialState} is not a table!\n{debug.traceback()}`)
	end

	-- all keys in InitialState must be strings
	for propertyName, value in InitialState do
		if not (typeof(propertyName) == "string") then
			error(`{propertyName} is not a string! (in Object.{objectTypeName}[{propertyName}])`)
		end
	end

	-- an objectTypeName of "Game" just refers to the root server's state
	if objectTypeName == "Game" then
		for propertyName, value in InitialState do
			callFunctionAndDoCheck(TestState, setServerProperty, TestState.Server, propertyName, value)
		end

		return
	end

	-- build clients for every player
	if objectTypeName == "Player" then
		-- Clients must receive a Name and UserId for the player they are wrapping
		if not (typeof(InitialState.Name) == "string") then
			error(`Attempt to create Player Object with no Name property: {argsToString(InitialState.Name)}`)
		end
		if not (typeof(InitialState.UserId) == "number") then
			error(`Attempt to create Player Object with no UserId property: {argsToString(InitialState.UserId)}`)
		end

		-- create new Client object
		local s, NewClient = callFunctionAndDoCheck(TestState, doGameApiMethod, TestState.Api, "newClient", {
			Name = InitialState.Name,
			UserId = InitialState.UserId,
		})
		if not s then
			return
		end

		-- TODO: maybe test that client has default server state
		-- TODO: maybe it makes sense to test that the player doesn't already exist on the server

		-- connect Client to Server
		local s2, serverId = callFunctionAndDoCheck(TestState, doServerMethod, TestState.Server, "GetServerId")
		if not s2 then
			return
		end

		local s3, successfullyConnected =
			callFunctionAndDoCheck(TestState, doClientMethod, NewClient, "ConnectToServer", serverId)
		if not s then
			return
		end

		local s4 = doCheck(
			TestState,
			successfullyConnected,
			`Client(UserId = {InitialState.UserId}) failed to connect to server`
		)
		if not s4 then
			return
		end

		table.insert(TestState.Clients, NewClient)

		-- after creating Client, a Player object must have been created and replicated to all Clients connected to the Server
		local s5, playerId = callFunctionAndDoCheck(TestState, doClientMethod, NewClient, "GetLocalPlayerObjectId")
		if not s5 then
			return
		end

		callFunctionAndDoCheck(
			TestState,
			assertObjectProperty,
			TestState,
			playerId,
			"Player",
			"UserId",
			InitialState.UserId
		)
		callFunctionAndDoCheck(
			TestState,
			assertObjectProperty,
			TestState,
			playerId,
			"Player",
			"Name",
			InitialState.Name
		)

		-- and then we set properties for anything other than Name or UserId
		InitialState.Name = nil
		InitialState.UserId = nil

		for propertyName, value in InitialState do
			callFunctionAndDoCheck(
				TestState,
				setObjectProperty,
				TestState,
				playerId,
				objectTypeName,
				propertyName,
				value
			)
		end

		-- all previous Clients' Players must exist on the new Client
		for _, OtherClient in TestState.Clients do
			if OtherClient == NewClient then
				continue
			end

			local s10, otherPlayerObjectId =
				callFunctionAndDoCheck(TestState, doClientMethod, OtherClient, "GetLocalPlayerObjectId")
			if not s10 then
				continue
			end

			local s11, otherPlayerUserId =
				callFunctionAndDoCheck(TestState, doClientMethod, OtherClient, "GetLocalPlayerUserId")
			if not s11 then
				continue
			end

			local s12, otherPlayerUserName =
				callFunctionAndDoCheck(TestState, doClientMethod, OtherClient, "GetLocalPlayerName")
			if not s12 then
				continue
			end

			callFunctionAndDoCheck(
				TestState,
				assertObjectPropertyOnClient,
				NewClient,
				otherPlayerObjectId,
				objectTypeName,
				"UserId",
				otherPlayerUserId
			)

			callFunctionAndDoCheck(
				TestState,
				assertObjectPropertyOnClient,
				NewClient,
				otherPlayerObjectId,
				objectTypeName,
				"Name",
				otherPlayerUserName
			)
		end

		-- TODO: test that Server state has been replicated to client (requires API design manifest to loop over what server state there is)

		return
	end

	-- building standard objects
	local s, result = callFunctionAndDoCheck(TestState, createNewObject, TestState.Server, objectTypeName, "hi mom!")
	if not s then
		TestState.numTestConditions += countDictionary(InitialState)
		return
	end

	local newObjectId = result

	for propertyName, value in InitialState do
		callFunctionAndDoCheck(
			TestState,
			setObjectProperty,
			TestState,
			newObjectId,
			objectTypeName,
			propertyName,
			value
		)
	end

	-- all standard objects must have a Name property!
	if InitialState.Name == nil then
		callFunctionAndDoCheck(
			TestState,
			assertObjectProperty,
			TestState,
			newObjectId,
			objectTypeName,
			"Name",
			isString
		)
	end
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
	TestState.Clients = {} -- int i --> Client
	TestState.Api = Api

	-- load server
	local s, result = doGameApiMethod(Api, "newServer")
	if not s then
		return -1, 0, result
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
