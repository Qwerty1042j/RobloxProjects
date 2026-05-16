local debris = game:GetService("Debris")
local mainEvent = game.ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("MainEvent")
local blockEvent = game.ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("BlockEvent")

local ORswingSound = game.SoundService:WaitForChild("Sounds"):WaitForChild("SwingSound")
local ORhitSound = game.SoundService:WaitForChild("Sounds"):WaitForChild("PunchSound")
local ORblockHitSound = game.SoundService:WaitForChild("Sounds"):WaitForChild("BlockHitSound")

blockEvent.OnServerEvent:Connect(function(player, status)
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    humanoidRootPart:SetAttribute("Blocking", status)
    if status then
        humanoid.WalkSpeed = 6
    else
        humanoid.WalkSpeed = 16
    end
end)

mainEvent.OnServerEvent:Connect(function(player, lastHit)
    local character = player.Character
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local swingSound = humanoidRootPart:FindFirstChild("SwingSound")
    if not swingSound then
        swingSound = ORswingSound:Clone()
        swingSound.Parent = character:WaitForChild("HumanoidRootPart")
    end
    
    swingSound:Play()
    
	task.spawn(function()
		humanoid.WalkSpeed = 6
		task.wait(0.53)
		humanoid.WalkSpeed = 16
	end)
	
	task.wait(0.3)
    
    local hitBox = Instance.new("Part")
    hitBox.Parent = workspace
    hitBox.Material = "SmoothPlastic"
    hitBox.CanCollide = false
    hitBox.Anchored = true
    hitBox.Size = Vector3.new(2.5,4,2.5)
    hitBox.BrickColor = BrickColor.new("Really red")
    hitBox.Transparency = 0.8
    hitBox.CFrame = humanoidRootPart.CFrame * CFrame.new(0,0,-2.5)
    debris:AddItem(hitBox, 0.3)

    local alreadyHit = {}

    hitBox.Touched:Connect(function(part)
        local hitCharacter = part.Parent
        if hitCharacter.ClassName ~= "Model" then
            hitCharacter = part.Parent.Parent 
        end
        if not hitCharacter then return end
        if hitCharacter == character then return end

        if alreadyHit[hitCharacter] then return end
        alreadyHit[hitCharacter] = true

        local hitHumanoid = hitCharacter:WaitForChild("Humanoid")
        if not hitHumanoid or hitHumanoid.Health <= 0 then return end
        
        local hitHumanoidRootPart = hitCharacter:WaitForChild("HumanoidRootPart")
		if not hitHumanoidRootPart then return end

        local hitSound = hitHumanoidRootPart:FindFirstChild("PunchSound")
        if not hitSound then
            hitSound = ORhitSound:Clone()
            hitSound.Parent = hitHumanoidRootPart
        end

        local blockHitSound = hitHumanoidRootPart:FindFirstChild("BlockHitSound")
        if not blockHitSound then
            blockHitSound = ORblockHitSound:Clone()
            blockHitSound.Parent = hitHumanoidRootPart
        end

        -------------------------------------------------------------------

        local getHitAnim = hitHumanoid:LoadAnimation(game.ReplicatedStorage:WaitForChild("Animations"):WaitForChild("GetHitAnim"))

        local bodyVelocity = Instance.new("LinearVelocity")
        bodyVelocity.Attachment0 = hitHumanoidRootPart:WaitForChild("RootAttachment")
		bodyVelocity.Parent = hitHumanoidRootPart
		bodyVelocity.MaxForce = math.huge

        local function isHitFromBehind(attackerRootPart, victimRootPart)
            local attackerLook = attackerRootPart.CFrame.LookVector
            local victimLook = victimRootPart.CFrame.LookVector
            --return attackerLook:Dot(victimLook) > 0
            local angle = math.acos(math.clamp(attackerLook.Unit:Dot(victimLook.Unit), -1, 1))
            return angle < 1.3
        end

        local blocking = hitHumanoidRootPart:GetAttribute("Blocking")
        local hitFromBehind = isHitFromBehind(humanoidRootPart, hitHumanoidRootPart)

        if blocking and not hitFromBehind then
            if lastHit then
                bodyVelocity.VectorVelocity = humanoidRootPart.CFrame.LookVector * 3
            else
                bodyVelocity.VectorVelocity = humanoidRootPart.CFrame.LookVector * 0.5
            end

            blockHitSound:Play()
        else
            if lastHit then
                bodyVelocity.VectorVelocity = humanoidRootPart.CFrame.LookVector * 30
            else
                bodyVelocity.VectorVelocity = humanoidRootPart.CFrame.LookVector * 1
            end

            hitSound:Play()
            getHitAnim:Play()
            hitHumanoid:TakeDamage(10)
            hitHumanoid.WalkSpeed = 0
        end

        hitHumanoidRootPart:SetAttribute("CanAttack", false)

        debris:AddItem(bodyVelocity, 0.3)
        task.delay(0.55, function()
            hitHumanoid.WalkSpeed = 16
            hitHumanoidRootPart:SetAttribute("CanAttack", true)
        end)

    end)
end)