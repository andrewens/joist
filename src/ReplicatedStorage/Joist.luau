-- const
local INFO_PRE_MESSAGE = "[JOIST]: "

-- private
local function log(message, MessageArray)
	if MessageArray then
		table.insert(MessageArray, message)

		return MessageArray
	end

	print(INFO_PRE_MESSAGE .. message)
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

	local success, Api = pcall(require, ApiModuleScript)
	if not success then
		return log(`Failed to require {ApiModuleScript} with error:\n{Api}\n{debug.traceback()}`, MessageArray)
	end

	local numTestsRan = 0
	local numTestsPassed = 0
	for _, TestModuleScript in TestsFolder:GetChildren() do
		local moduleName = TestModuleScript.Name
		if string.sub(moduleName, moduleName:len() - 4, moduleName:len()) ~= ".spec" then
			continue
		end

		if not TestModuleScript:IsA("ModuleScript") then
			continue
		end

		numTestsRan += 1

		local s, testFunction = pcall(require, TestModuleScript)
		if not s then
			log(`(#{numTestsRan}) Failed to require TestModule "{moduleName}" with error:\n{testFunction}`, MessageArray)
			continue
		end

		log(`(#{numTestsRan}) Test "{moduleName}" passed`, MessageArray)
		numTestsPassed += 1
	end

	if numTestsRan <= 0 then
		return log(`No tests to run!`, MessageArray)
	end

	log(`{numTestsPassed} / {numTestsRan} tests passed`, MessageArray)

	return MessageArray
end

function Joist.initializeJoist()

end

return Joist
