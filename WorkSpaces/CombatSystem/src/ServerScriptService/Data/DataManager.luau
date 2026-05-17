local DataManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Store profiles from profile store
DataManager.Profiles = {}

function DataManager.AddKill(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Kills += amount
	player.leaderstats.Kills.Value = profile.Data.Kills
	ReplicatedStorage.DataUpdate.UpdateKills:FireClient(player, profile.Data.Kills)
end

function DataManager.AddDeath(player: Player, amount: number)
	local profile = DataManager.Profiles[player]
	if not profile then return end
	
	profile.Data.Deaths += amount
	player.leaderstats.Deaths.Value = profile.Data.Deaths
	ReplicatedStorage.DataUpdate.UpdateDeaths:FireClient(player, profile.Data.Deaths)
end

return DataManager
