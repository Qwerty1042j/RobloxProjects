local UIS = game:GetService("UserInputService")
local mainEvent = game.ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("MainEvent")
local blockEvent = game.ReplicatedStorage:WaitForChild("CombatEvent"):WaitForChild("BlockEvent")

local player = game.Players.LocalPlayer
local humanoid
local humanoidRootPart

local animations = game.ReplicatedStorage:WaitForChild("Animations")
local m1Anim1, m1Anim2, m1Anim3, m1Anim4, blockAnim

local combo = 1
local coolDown = false
local lastCoolDown = false
local blocking = false

local function loadAnims()
    local character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local animator = humanoid:WaitForChild("Animator")

    m1Anim1 = animator:LoadAnimation(animations:WaitForChild("M1Anim1"))
    m1Anim2 = animator:LoadAnimation(animations:WaitForChild("M1Anim2"))
    m1Anim3 = animator:LoadAnimation(animations:WaitForChild("M1Anim3"))
    m1Anim4 = animator:LoadAnimation(animations:WaitForChild("M1Anim4"))
    blockAnim = animator:LoadAnimation(animations:WaitForChild("BlockAnim"))
end

loadAnims()
player.CharacterAdded:Connect(function()
    combo = 1
    coolDown = false
    lastCoolDown = false
    loadAnims()
end)

local function ResetCombo(Combo)
     task.delay(2, function()
         if combo == Combo then
            combo = 1
        end
    end)
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not humanoid or humanoid.Health <= 0 then return end

    local canAttack = humanoidRootPart:GetAttribute("CanAttack")
    if not canAttack then return end

    if input.KeyCode == Enum.KeyCode.F then
        if coolDown then return end
        blocking = true
        blockEvent:FireServer(blocking)
        blockAnim:Play()
    end
end)

UIS.InputEnded:Connect(function(input, gp)
    if gp then return end
    if not humanoid or humanoid.Health <= 0 then return end

    local canAttack = humanoidRootPart:GetAttribute("CanAttack")
    if not canAttack then return end

    if input.KeyCode == Enum.KeyCode.F then
        blocking = false
        blockEvent:FireServer(blocking)
        blockAnim:Stop()
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if coolDown then return end
        if lastCoolDown then return end
        if blocking then return end

        if combo == 1 then
            mainEvent:FireServer()
            m1Anim1:Play()
            combo += 1
            ResetCombo(combo)
        elseif combo == 2 then
            mainEvent:FireServer()
            m1Anim2:Play()
            combo += 1
            ResetCombo(combo)
        elseif combo == 3 then
            mainEvent:FireServer()
            m1Anim3:Play()
            combo += 1
            ResetCombo(combo)
        elseif combo == 4 then
            mainEvent:FireServer(true)
            m1Anim4:Play()
            combo = 1
            task.spawn(function()
                lastCoolDown = true
                task.wait(1.2)
                lastCoolDown = false
            end)
        end

        task.spawn(function()
            coolDown = true
            humanoidRootPart:SetAttribute("CanDash", false)
            task.wait(0.53)
            coolDown = false
            humanoidRootPart:SetAttribute("CanDash", true)
        end)
    end
end)