local UpdateDeaths = game.ReplicatedStorage.DataUpdate.DeathUpdate
local Players = game:GetService("Players")

local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local player = Players:GetPlayerFromCharacter(character)

local canFire = true

humanoid.HealthChanged:Connect(function(newHealth)
	if not canFire then return end

	if newHealth < 1 then
		canFire = false
		UpdateDeaths:Fire(player)
		task.wait(3)
		canFire = true
	end
end)