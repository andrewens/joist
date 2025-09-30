local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Joist = require(ReplicatedStorage.Joist)

local MockTestsFolder = script.MockTests
local MockApis = script.MockApis

return function()
	describe("The most basic test... WITH PLAYERS", function()
		it("Passes if API is implemented correctly", function()
			local numTests, numSucceeded, Output = Joist.runTests(MockApis.Api1, MockTestsFolder, {
				OutputMode = "ReturnTable",
				OnlyTestSpecModules = false,
			})

			assert(numTests == 1)
			assert(numSucceeded == 1)
		end)
		it("Fails if old Players are not replicated to new Clients", function()
			local numTests, numSucceeded, Output = Joist.runTests(MockApis.Api2, MockTestsFolder, {
				OutputMode = "ReturnTable",
				OnlyTestSpecModules = false,
			})

			assert(numTests == 1)
			assert(numSucceeded == 0)
		end)
		it("Fails if Player Names are not replicated to Clients", function()
			local numTests, numSucceeded, Output = Joist.runTests(MockApis.Api3, MockTestsFolder, {
				OutputMode = "ReturnTable",
				OnlyTestSpecModules = false,
			})

			assert(numTests == 1)
			assert(numSucceeded == 0)
		end)
	end)
end
