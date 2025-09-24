local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.TestEZ)
local TestsFolder = ReplicatedStorage.Tests

TestEZ.TestBootstrap:run({ TestsFolder })
