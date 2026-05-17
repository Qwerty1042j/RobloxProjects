local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local _DashModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DashModule"))

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local rootPart  = character:WaitForChild("HumanoidRootPart")
local camera    = workspace.CurrentCamera

local animator = humanoid:WaitForChild("Animator")
local dashAnimation = game.ReplicatedStorage:WaitForChild("Animations"):WaitForChild("DashForward")
local dashAnim = animator:LoadAnimation(dashAnimation)

-- ── Config ───────────────────────────────────────────────────────────
local DASH_KEY      = Enum.KeyCode.Q
local DASH_FORCE    = 60
local DASH_DURATION = 0.35   -- how long the dash lasts after pressing Q
local DASH_COOLDOWN = 1.5
-- ─────────────────────────────────────────────────────────────────────

local canDash = true

local function isGrounded()
    return humanoid.FloorMaterial ~= Enum.Material.Air
end

local function getDashDirection()
    local camCF = camera.CFrame

    local forward  = UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0
    local back     = UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0
    local leftKey  = UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0
    local rightKey = UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0

    if isGrounded() then
        local camYaw = CFrame.new(Vector3.zero, Vector3.new(
            camCF.LookVector.X, 0, camCF.LookVector.Z
        ))
        local inputVec = Vector3.new(rightKey - leftKey, 0, back - forward)
        if inputVec.Magnitude < 0.1 then inputVec = Vector3.new(0, 0, -1) end
        return (camYaw:VectorToWorldSpace(inputVec)).Unit
    else
        local dir = (camCF.LookVector  * (forward - back))
                  + (camCF.RightVector * (rightKey - leftKey))
        if dir.Magnitude < 0.1 then dir = camCF.LookVector end
        return dir.Unit
    end
end

local function startDash()
    if not canDash then return end
    if humanoid.Health <= 0 then return end

    rootPart:SetAttribute("CanAttack", false)
    task.delay(DASH_DURATION, function()
        rootPart:SetAttribute("CanAttack", true)
    end)
    
    dashAnim:Play()
    canDash = false

    -- Create the constraint once
    local attachment = Instance.new("Attachment")
    attachment.Parent = rootPart

    local lv = Instance.new("LinearVelocity")
    lv.Attachment0            = attachment
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
    lv.MaxForce               = 1e5
    lv.RelativeTo             = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity         = getDashDirection() * DASH_FORCE
    lv.Parent                 = rootPart

    local elapsed = 0

    -- Steer the dash every frame for DASH_DURATION seconds
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        elapsed += dt

        if elapsed >= DASH_DURATION or humanoid.Health <= 0 then
            conn:Disconnect()

            -- Smooth stop
            lv.VectorVelocity = Vector3.zero
            task.wait()
            lv:Destroy()
            attachment:Destroy()

            task.delay(DASH_COOLDOWN, function()
                canDash = true
            end)
            return
        end

        -- Update direction live every frame
        lv.VectorVelocity = getDashDirection() * DASH_FORCE
    end)
end

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == DASH_KEY then
        startDash()
    end
end)