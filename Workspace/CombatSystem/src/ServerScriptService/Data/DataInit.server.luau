-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ProfileStore
local ProfileStore = require(ServerScriptService.Libraries.ProfileStore)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local Template = require(ServerScriptService.Data.Template)
local DataManager = require(ServerScriptService.Data.DataManager)

local PlayerProfileStore = ProfileStore.New(GetStoreName(), Template)

-----------------------------------------------------------
-- 	   Add leaderstats and synchronize player data
-----------------------------------------------------------
local function Initialize(player: Player, profile)
	
	-- Create leaderstats
	local leaderStats = Instance.new("Folder")
	leaderStats.Name = "leaderstats"
	leaderStats.Parent = player
	
	local kills = Instance.new("IntValue")
	kills.Name = "Kills"
	kills.Value = profile.Data.Kills
	kills.Parent = leaderStats
	
	local deaths = Instance.new("IntValue")
	deaths.Name = "Deaths"
	deaths.Value = profile.Data.Deaths
	deaths.Parent = leaderStats
	
	-- Sync data
	ReplicatedStorage.DataUpdate.UpdateKills:FireClient(player, profile.Data.Kills)
	ReplicatedStorage.DataUpdate.UpdateDeaths:FireClient(player, profile.Data.Deaths)
	
end

-----------------------------------------------------------
-- 			    Create and store profile
-----------------------------------------------------------
local function PlayerAdded(player: Player)
	
	-- Start new session
	local profile = PlayerProfileStore:StartSessionAsync("Player: ".. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	-- Profile check
	task.wait(3)
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		
		-- Handle session-locking
		profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data issue, please rejoin.")
		end)
		
		-- Save profile for later use
		if player.Parent == Players then
			DataManager.Profiles[player] = profile
			Initialize(player, profile)
		else
			profile:EndSession()
		end
		
	else
		-- Server shuts down while player is joining
		player:Kick("Data issue, please rejoin.")
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile:EndSession()
	DataManager.Profiles[player] = nil
end)