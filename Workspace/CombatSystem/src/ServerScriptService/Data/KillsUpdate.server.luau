local DataManager = require(game.ServerScriptService.Data.DataManager)

local UpdateDeaths = game.ReplicatedStorage.DataUpdate.DeathUpdate

UpdateDeaths.Event:Connect(function(player)
    DataManager.AddDeath(player, 1)
end)