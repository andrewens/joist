-- Server
local ServerMethods = {}
local ServerMetatable = { __index = ServerMethods }

function ServerMethods.GetTestVariable(self)
    return self._TestVariable
end

function ServerMethods.SetTestVariable(self, newTestVariable)
    if not (typeof(newTestVariable) == "number") then
        error(`{newTestVariable} is not a number!`)
    end

    if not self._Toggle then
        return
    end

    self._Toggle = false
    self._TestVariable = newTestVariable
end

ServerMethods.TestAction = ServerMethods.SetTestVariable

-- API
local function newServer()
    local self = {}
    self._TestVariable = 0
    self._Toggle = true
    setmetatable(self, ServerMetatable)

    return self
end

return {
    newServer = newServer,
}
