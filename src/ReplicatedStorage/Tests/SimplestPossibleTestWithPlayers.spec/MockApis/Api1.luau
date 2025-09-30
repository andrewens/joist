-- Server
local ServerMethods = {}
local ServerMetatable = { __index = ServerMethods }

function ServerMethods.GetServerId(self)
    return self._ServerId
end

function ServerMethods.GetTestVariable(self)
    return self._TestVariable
end

function ServerMethods.SetTestVariable(self, newTestVariable)
    if not (typeof(newTestVariable) == "number") then
        error(`{newTestVariable} is not a number!`)
    end

    self._TestVariable = newTestVariable
end

ServerMethods.TestAction = ServerMethods.SetTestVariable

function ServerMethods.NewObject(self, objectTypeName)
    if not (typeof(objectTypeName) == "string") then
        error(`{objectTypeName} is not a string!`)
    end

    if not (objectTypeName == "Player") then
        error(`{objectTypeName} is not supported`)
    end

    self._ObjectIdCounter += 1
    local id = self._ObjectIdCounter

    self._ObjectIdToPlayerUserId[id] = -1
    self._ObjectIdToPlayerName[id] = "NewPlayer"

    return id
end

function ServerMethods.ObjectToString(self, objectId)
    return self._ObjectIdToPlayerName[objectId]
end

function ServerMethods.SetPlayerUserId(self, objectId, userId)
    if not (typeof(objectId) == "number") then
        error(`{objectId} is not a number!`)
    end
    if not (typeof(userId) == "number") then
        error(`{userId} is not a number!`)
    end

    if self._ObjectIdToPlayerUserId[objectId] == nil then
        error(`There is no object #{objectId}!`)
    end

    self._ObjectIdToPlayerUserId[objectId] = userId
end

function ServerMethods.SetPlayerName(self, objectId, name)
     if not (typeof(objectId) == "number") then
        error(`{objectId} is not a number!`)
    end
    if not (typeof(name) == "string") then
        error(`{name} is not a string!`)
    end

    if self._ObjectIdToPlayerName[objectId] == nil then
        error(`There is no object #{objectId}!`)
    end

    self._ObjectIdToPlayerName[objectId] = name
end

function ServerMethods.GetPlayerUserId(self, objectId)
     return self._ObjectIdToPlayerUserId[objectId]
end

function ServerMethods.GetPlayerName(self, objectId)
    return self._ObjectIdToPlayerName[objectId]
end

-- Network
local function connectClientToServer(Client, serverId, userId, playerName)
    local Server = GameAPI.getServerFromId(serverId)
    if Server == nil then
        return
    end

    local playerId = Server:NewObject("Player")
    Server:SetPlayerName(playerId, playerName) -- TODO: shouldn't be state?
    Server:SetPlayerUserId(playerId, userId)

    return playerId
end

-- Client
local ClientMethods = {}
local ClientMetatable = { __index = ClientMethods }

function ClientMethods.GetLocalPlayerObjectId(self)
    return self._PlayerObjectId
end

function ClientMethods.ConnectToServer(self, serverId)
    local playerId = connectClientToServer(self, serverId, self._UserId, self._PlayerName)
    if playerId == nil then
        return false
    end

    self._PlayerObjectId = playerId

    return true
end

-- Game API
local serverCount = 0
local ServerIdToServer = {}

local clientCount = 0
local ClientIdToClient = {}

GameAPI = {}

function GameAPI.getServerFromId(id)
    return ServerIdToServer[id]
end

function GameAPI.getClientFromId(id)
    return ClientIdToClient[id]
end

function GameAPI.newServer()
    local self = {}

    -- Server state
    self._ServerId = serverCount
    self._TestVariable = 0

    serverCount += 1
    ServerIdToServer[self._ServerId] = self

    -- Player state
    self._ObjectIdToPlayerName = {} -- int --> string
    self._ObjectIdToPlayerUserId = {} -- int --> int
    self._ObjectIdCounter = 0 -- int

    setmetatable(self, ServerMetatable)

    return self
end

function GameAPI.newClient(PlayerData)
    local self = {}

    -- Client state
    self._ClientId = clientCount
    self._UserId = PlayerData.UserId
    self._PlayerName = PlayerData.Name
    self._PlayerObjectId = 1

    clientCount += 1
    ClientIdToClient[self._ClientId] = self

    setmetatable(self, ClientMetatable)

    return self
end

return GameAPI
