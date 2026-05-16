local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")

local DashModule = require(game.ReplicatedStorage:WaitForChild("Modules"):WaitForChild("DashModule"))

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")
local humanoidRootPart  = character:WaitForChild("HumanoidRootPart")
local camera    = workspace.CurrentCamera

local animator = humanoid:WaitForChild("Animator")
local dashAnimation = game.ReplicatedStorage:WaitForChild("Animations"):WaitForChild("DashForward")
local dashAnim = animator:LoadAnimation(dashAnimation)

-- ── Config ───────────────────────────────────────────────────────────
local DASH_KEY      = Enum.KeyCode.Q
local DASH_FORCE    = 80
local DASH_DURATION = 0.25
local DASH_COOLDOWN = 1.0
-- ─────────────────────────────────────────────────────────────────────

local canDash = true

local function isGrounded()
    return humanoid.FloorMaterial ~= Enum.Material.Air
end

-- Ground dash: flat WASD relative to camera yaw only
local function getGroundDirection()
    local forward = UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0
    local back    = UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0
    local left    = UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0
    local right   = UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0

    local inputVec = Vector3.new(right - left, 0, back - forward)
    if inputVec.Magnitude < 0.1 then
        inputVec = Vector3.new(0, 0, -1)  -- default: forward
    end

    -- Strip camera pitch — yaw only
    local camYaw = CFrame.new(Vector3.zero, Vector3.new(
        camera.CFrame.LookVector.X,
        0,
        camera.CFrame.LookVector.Z
    ))

    return (camYaw:VectorToWorldSpace(inputVec)).Unit
end

-- Aerial dash: full 3D WASD relative to camera including pitch
-- W  → along camera LookVector  (up if cam tilted up)
-- S  → opposite of LookVector   (down if cam tilted up)
-- A  → camera left              (always flat)
-- D  → camera right             (always flat)
-- Diagonals combine all three axes and are normalized
local function getAerialDirection()
    local camCF = camera.CFrame

    -- Camera axes in world space
    local look  =  camCF.LookVector          -- W direction
    local right =  camCF.RightVector         -- D direction
    -- Up/Down is not a separate key here; pitch is baked into look/back

    local forward = UIS:IsKeyDown(Enum.KeyCode.W) and 1 or 0
    local back    = UIS:IsKeyDown(Enum.KeyCode.S) and 1 or 0
    local leftKey = UIS:IsKeyDown(Enum.KeyCode.A) and 1 or 0
    local rightKey= UIS:IsKeyDown(Enum.KeyCode.D) and 1 or 0

    local dir = (look * (forward - back))
              + (right * (rightKey - leftKey))

    if dir.Magnitude < 0.1 then
        dir = look  -- default: straight along camera
    end

    return dir.Unit
end

local function onDash()
    if not canDash then return end
    if humanoid.Health <= 0 then return end

    canDash = false

    local dir
    if isGrounded() then
        dir = getGroundDirection()
    else
        dir = getAerialDirection()
    end

    DashModule.Dash(humanoidRootPart, humanoid, dir, DASH_FORCE, DASH_DURATION)
    dashAnim:Play()

    task.delay(DASH_COOLDOWN, function()
        canDash = true
    end)
end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end

    local canAttack = humanoidRootPart:GetAttribute("CanAttack")
    if not canAttack then return end

    if input.KeyCode == DASH_KEY then
        onDash()
    end
end)