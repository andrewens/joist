local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.TestEZ)
local Joist = require(ReplicatedStorage.Joist)

local TestsFolder = ReplicatedStorage.Tests

TestEZ.TestBootstrap:run({ TestsFolder })

print()

Joist.runTests(TestsFolder["Test1.spec"].MockApis.Api3, TestsFolder["Test1.spec"].MockTests, {
    OnlyTestSpecModules =  false,
})

