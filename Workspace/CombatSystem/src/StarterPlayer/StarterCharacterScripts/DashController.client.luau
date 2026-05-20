local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local _DashModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DashModule"))

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local humanoidRootPart  = character:WaitForChild("HumanoidRootPart")
local camera    = workspace.CurrentCamera

local animator      = humanoid:WaitForChild("Animator")
local dashAnimation = game.ReplicatedStorage:WaitForChild("Animations"):WaitForChild("DashForward")
local dashAnim      = animator:LoadAnimation(dashAnimation)

-- Config
local DASH_KEY      = Enum.KeyCode.Q
local DASH_FORCE    = 60
local DASH_DURATION = 0.35
local DASH_COOLDOWN = 1.5
local STOP_DURATION = 0.25

local canDash = true

local function isGrounded()
    return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function getCameraYaw()
    local camCF = camera.CFrame
    return CFrame.new(Vector3.zero, Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z))
end

local function getCurrentDirection(inputVec)
    local camCF = camera.CFrame
    if isGrounded() then
        return getCameraYaw():VectorToWorldSpace(inputVec).Unit
    else
        local fwd   = -inputVec.Z
        local right =  inputVec.X
        local dir = (camCF.LookVector * fwd) + (camCF.RightVector * right)
        if dir.Magnitude < 0.1 then dir = camCF.LookVector end
        return dir.Unit
    end
end

local function startDash()
    local CanDash = humanoidRootPart:GetAttribute("CanDash")
    if CanDash == false then return end
    if not canDash then return end
    if humanoid.Health <= 0 then return end

    local fwd = UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0
    local bk  = UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0
    local lk  = UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0
    local rk  = UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0

    local inputVec = Vector3.new(rk - lk, 0, bk - fwd)
    if inputVec.Magnitude < 0.1 then
        inputVec = Vector3.new(0, 0, -1)
    else
        inputVec = inputVec.Unit
    end

    local function getCurrentDir()
        return getCurrentDirection(inputVec)
    end

    humanoidRootPart:SetAttribute("CanAttack", false)
    task.delay(DASH_DURATION, function()
        humanoidRootPart:SetAttribute("CanAttack", true)
    end)

    dashAnim:Play()
    canDash = false
    humanoid.JumpHeight = 0

    local attachment = Instance.new("Attachment")
    attachment.Parent = humanoidRootPart

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0            = attachment
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.MaxForce               = 1e5
    lv.RelativeTo             = Enum.ActuatorRelativeTo.World
    lv.Parent                 = humanoidRootPart

    local elapsed = 0

    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt

        if elapsed >= DASH_DURATION or humanoid.Health <= 0 then
            conn:Disconnect()

            local stopStartVelocity = getCurrentDir() * DASH_FORCE
            lv:Destroy()
            attachment:Destroy()

            local stopElapsed = 0
            local stopConn
            stopConn = RunService.RenderStepped:Connect(function(dt2)
                stopElapsed += dt2
                local alpha = math.min(stopElapsed / STOP_DURATION, 1)

                local currentVel = stopStartVelocity * (1 - alpha)

                -- for air dash preserve Y separately, for ground keep Y from gravity
                humanoidRootPart.AssemblyLinearVelocity = Vector3.new(
                    currentVel.X,
                    humanoidRootPart.AssemblyLinearVelocity.Y,
                    currentVel.Z
                )

                if alpha >= 1 then
                    stopConn:Disconnect()
                    humanoid.JumpHeight = 5
                end
            end)

            task.delay(DASH_COOLDOWN, function()
                canDash = true
            end)
            return
        end

        lv.VectorVelocity = getCurrentDir() * DASH_FORCE
    end)
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == DASH_KEY then
        startDash()
    end
end)