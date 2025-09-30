local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.TestEZ)
local Joist = require(ReplicatedStorage.Joist)

local TestsFolder = ReplicatedStorage.Tests

TestEZ.TestBootstrap:run({ TestsFolder })

print()

local LiveTestFolder = TestsFolder["SimplestPossibleTestWithPlayers.spec"]
local LiveTestApi = LiveTestFolder.MockApis.Api1
local LiveTestMockTestsFolder = LiveTestFolder.MockTests

Joist.runTests(LiveTestApi, LiveTestMockTestsFolder, {
    OnlyTestSpecModules =  false,
})
