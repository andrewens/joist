local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Joist = require(ReplicatedStorage.Joist)

local MockTestsFolder = script.MockTests
local MockApi = script.MockApi

return function()
    describe("Sup", function()
        it("Does something", function()
            local Output = Joist.runTests(MockApi, MockTestsFolder, {
                OutputMode = "ReturnTable",
            })

            --assert(Output[1] == "")
        end)
    end)
end
