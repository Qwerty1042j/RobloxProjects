local TweenService = game:GetService("TweenService")
local _RunService   = game:GetService("RunService")

local DashModule = {}

-- Optional: VFX / trail hook — swap nil for your particle/trail object
local TRAIL_TEMPLATE = nil  -- e.g. game.ReplicatedStorage.DashTrail

-- Applies a velocity boost to the character in `direction`
-- rootPart  : HumanoidRootPart
-- humanoid  : Humanoid
-- direction : Vector3 (unit vector)
-- force     : studs per second
-- duration  : seconds the LinearVelocity is active
function DashModule.Dash(rootPart, humanoid, direction, force, duration)
	-- Disable default hip-height correction briefly so dash feels smooth
	local _prevHipHeight = humanoid.HipHeight

	-- ── Apply velocity via LinearVelocity (modern constraint) ────────
	local attachment = Instance.new("Attachment")
	attachment.Parent = rootPart

	local lv = Instance.new("LinearVelocity")
	lv.Attachment0         = attachment
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	lv.MaxForce            = 1e5         -- high enough to override friction
	lv.RelativeTo          = Enum.ActuatorRelativeTo.World
	lv.VectorVelocity      = direction * force
	lv.Parent              = rootPart 

	-- ── Optional trail ───────────────────────────────────────────────
	local trail
	if TRAIL_TEMPLATE then
		trail = TRAIL_TEMPLATE:Clone()
		trail.Parent = rootPart
		trail.Enabled = true
	end

	-- ── Tween force to zero (smooth stop) ───────────────────────────
	local fadeInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(lv, fadeInfo, {
		VectorVelocity = direction * 0
	})
	tween:Play()

	-- ── Cleanup ──────────────────────────────────────────────────────
	tween.Completed:Connect(function()
		lv:Destroy()
		attachment:Destroy()
		if trail then
			trail.Enabled = false
			task.delay(1, function() trail:Destroy() end)
		end
	end)
end

return DashModule