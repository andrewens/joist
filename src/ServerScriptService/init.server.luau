local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.TestEZ)
local Joist = require(ReplicatedStorage.Joist)

local TestsFolder = ReplicatedStorage.Tests
local LiveTestingFolder = ReplicatedStorage.LiveTesting

TestEZ.TestBootstrap:run({ TestsFolder })

print()

Joist.runTests(LiveTestingFolder.FakeApi, LiveTestingFolder.FakeTests)

