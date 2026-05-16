local players = game:GetService("Players")

local function onCharacterAppearanceLoaded(character)
	-- When characters is fully load	
	local _player = players:GetPlayerFromCharacter(character)
	local _hum = character:WaitForChild("Humanoid")
	local humRootPart = character:WaitForChild("HumanoidRootPart")
	
	-- Default Settings
	humRootPart:SetAttribute("CanAttack", true)

	-- Find accessories
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				-- Disable Canquery, CanCollide, CanTouch
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
				handle.AudioCanCollide = false
				handle.CollisionGroup = "NonDefault"
			end
		end
	end
end

-- Connect the function to the event for the current character
local character = script.Parent
if character and character:IsA("Model") then
	local player = players:GetPlayerFromCharacter(character)
	if player then
		-- Wait for the character's appearance to be fully loaded
		player.CharacterAppearanceLoaded:Connect(onCharacterAppearanceLoaded)
		-- Also run it immediately for the initial load if already loaded
		if player:HasAppearanceLoaded() then
			onCharacterAppearanceLoaded(character)
		end
	end
end

-- For characters added later in the game session
players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(onCharacterAppearanceLoaded)
end)