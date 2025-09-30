-- Network (would normally use RemoteEvents)
local Network = {}

function Network.onServerEventConnect(Server, remoteEventName, callback)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	if Server._RemoteEventCallbacks[remoteEventName] == nil then
		Server._RemoteEventCallbacks[remoteEventName] = {}
	end

	Server._RemoteEventCallbacks[remoteEventName][callback] = true

	return {
		Disconnect = function()
			Server._RemoteEventCallbacks[remoteEventName][callback] = nil
		end,
	}
end

function Network.onClientEventConnect(Client, remoteEventName, callback)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!`)
	end
	if not (typeof(callback) == "function") then
		error(`{callback} is not a function!`)
	end

	if Client._RemoteEventCallbacks[remoteEventName] == nil then
		Client._RemoteEventCallbacks[remoteEventName] = {}
	end

	Client._RemoteEventCallbacks[remoteEventName][callback] = true

	return {
		Disconnect = function()
			Client._RemoteEventCallbacks[remoteEventName][callback] = nil
		end,
	}
end

function Network.onServerInvokeConnect(Server, remoteEventName, callback)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!`)
	end
	if not (typeof(callback) == "function" or callback == nil) then
		error(`{callback} is not a function!`)
	end

	Server._RemoteFunctionCallbacks[remoteEventName] = callback
end

function Network.clientInvokeServer(Client, remoteEventName, ...)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!\n{debug.traceback()}`)
	end

	local connectedServerId = Client._ConnectedServerId
	local Server = GameAPI.getServerFromId(connectedServerId)

	if Server == nil then
		return
	end

	local callback = Server._RemoteFunctionCallbacks[remoteEventName]
	if callback then
		return callback(Server, Client._PlayerObjectId, ...)
	end
end

function Network.serverFireClient(Server, remoteEventName, playerId, ...)
	local clientId = Server._PlayerIdToClientId[playerId]
	if clientId == nil then
		return
	end

	local Client = GameAPI.getClientFromId(clientId)
	if Client == nil then
		return -- TODO: should not happen
	end

	local RemoteEventCallbacks = Client._RemoteEventCallbacks[remoteEventName]
	if RemoteEventCallbacks == nil then
		return
	end

	for callback, _ in RemoteEventCallbacks do
		callback(Client, ...)
	end
end

function Network.serverFireAllClients(Server, remoteEventName, ...)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!`)
	end

	for playerId, clientId in Server._PlayerIdToClientId do
		Network.serverFireClient(Server, remoteEventName, playerId, ...)
	end
end

function Network.clientFireServer(Client, remoteEventName, ...)
	if not (typeof(remoteEventName) == "string") then
		error(`{remoteEventName} is not a string!`)
	end

	local playerId = Client._PlayerObjectId
	if playerId == nil then
		return
	end

	local connectedServerId = Client._ConnectedServerId
	if connectedServerId == nil then
		return
	end

	local Server = GameAPI.getServerFromId(connectedServerId)
	if Server == nil then
		return
	end

	local RemoteEventCallbacks = Server._RemoteEventCallbacks[remoteEventName]
	if RemoteEventCallbacks == nil then
		return
	end

	for callback, _ in RemoteEventCallbacks do
		callback(playerId, ...)
	end
end

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

	Network.serverFireAllClients(self, "ReplicatePlayerUserId", objectId, userId) -- TODO: hate this; should be all at once and should be constant
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

	Network.serverFireAllClients(self, "ReplicatePlayerName", objectId, name)
end

function ServerMethods.GetPlayerUserId(self, objectId)
	return self._ObjectIdToPlayerUserId[objectId]
end

function ServerMethods.GetPlayerName(self, objectId)
	return self._ObjectIdToPlayerName[objectId]
end

function ServerMethods._ClientConnectToServer(self, playerObjectId, clientId, userId, playerName)
	-- playerObjectId starts at -1 because we have to assign it here
	playerObjectId = self:NewObject("Player") -- TODO: when you make this support constants, remember that self._PlayerIdToClientId has to be populated before RemoteEvents can go to this client
	self._PlayerIdToClientId[playerObjectId] = clientId

	self:SetPlayerName(playerObjectId, playerName) -- TODO: shouldn't be state?
	self:SetPlayerUserId(playerObjectId, userId)

	-- DO NOT FORGET TO REPLICATE ALL THE OTHER PLAYERS TO THIS CLIENT!!!!
	for otherPlayerId, _ in self._PlayerIdToClientId do
		if otherPlayerId == playerObjectId then -- you might need to get rid of this
			continue
		end

		local otherUserId = self._ObjectIdToPlayerUserId[otherPlayerId]
		local otherName = self._ObjectIdToPlayerName[otherPlayerId]

		Network.serverFireClient(self, "ReplicatePlayerUserId", playerObjectId, otherPlayerId, otherUserId)
		Network.serverFireClient(self, "ReplicatePlayerName", playerObjectId, otherPlayerId, otherName)
	end

	return playerObjectId
end

-- Client
local ClientMethods = {}
local ClientMetatable = { __index = ClientMethods }

function ClientMethods.GetLocalPlayerObjectId(self)
	return self._PlayerObjectId
end

function ClientMethods.GetLocalPlayerName(self) -- TODO: is this too extra?
	return self._PlayerName
end

function ClientMethods.GetLocalPlayerUserId(self)
	return self._UserId
end

function ClientMethods.ConnectToServer(self, serverId)
	if not (typeof(serverId) == "number") then
		error(`{serverId} is not a number!`)
	end

	self._ConnectedServerId = serverId -- must be before calling remote events b/c Network module needs it

	local playerObjectId =
		Network.clientInvokeServer(self, "ClientConnectToServer", self._ClientId, self._UserId, self._PlayerName)

	if playerObjectId == nil then
		self._ConnectedServerId = nil
		return false
	end

	self._PlayerObjectId = playerObjectId

	return true
end

function ClientMethods.GetPlayerUserId(self, playerId)
	return self._ObjectIdToPlayerUserId[playerId]
end

function ClientMethods.GetPlayerName(self, playerId)
	return self._ObjectIdToPlayerName[playerId]
end

function ClientMethods._ReplicatePlayerUserId(self, playerId, userId)
	self._ObjectIdToPlayerUserId[playerId] = userId
end

function ClientMethods._ReplicatePlayerName(self, playerId, name)
	self._ObjectIdToPlayerName[playerId] = name
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
	setmetatable(self, ServerMetatable)

	-- behind the scenes
	self._RemoteEventCallbacks = {} -- string remoteEventName --> callback --> true
	self._RemoteFunctionCallbacks = {} -- string remoteEventName --> callback
	self._PlayerIdToClientId = {} -- int playerObjectId --> int clientId
	self._ServerId = serverCount

	-- Server state
	self._TestVariable = 0

	serverCount += 1
	ServerIdToServer[self._ServerId] = self

	-- Player state
	self._ObjectIdToPlayerName = {} -- int --> string
	self._ObjectIdToPlayerUserId = {} -- int --> int
	self._ObjectIdCounter = 0 -- int

	-- initialize Server
	Network.onServerInvokeConnect(self, "ClientConnectToServer", self._ClientConnectToServer)

	return self
end

function GameAPI.newClient(PlayerData)
	local self = {}
	setmetatable(self, ClientMetatable)

	-- behind the scenes
	self._RemoteEventCallbacks = {}
	self._ClientId = clientCount
	self._ConnectedServerId = -1

	-- Client Player
	self._UserId = PlayerData.UserId
	self._PlayerName = PlayerData.Name
	self._PlayerObjectId = -1

	clientCount += 1
	ClientIdToClient[self._ClientId] = self

	-- Player state
	self._ObjectIdToPlayerUserId = {}
	self._ObjectIdToPlayerName = {}

	-- Server state
	self._TestVariable = 0

	-- initialize Client
	Network.onClientEventConnect(self, "ReplicatePlayerName", self._ReplicatePlayerName)
	Network.onClientEventConnect(self, "ReplicatePlayerUserId", self._ReplicatePlayerUserId)

	return self
end

return GameAPI
