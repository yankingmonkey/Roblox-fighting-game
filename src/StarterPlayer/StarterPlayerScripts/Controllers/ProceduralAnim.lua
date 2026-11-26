--!strict
-- Fight poses built from joint offsets, so the game animates with no uploaded ids.
-- If Shared/AnimationConfig.lua has an id for a pose, the server plays that clip
-- instead and this script leaves the body alone for that action.
-- Tweak the CFrames in the pose functions if a limb bends the wrong way.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AnimationConfig = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.AnimationConfig)
local Util = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.Util)
local PoseLibrary = require(script.Parent.PoseLibrary)

local MOTOR_NAMES = {
	"Waist",
	"Neck",
	"LeftShoulder",
	"RightShoulder",
	"LeftElbow",
	"RightElbow",
	"LeftHip",
	"RightHip",
	"LeftKnee",
	"RightKnee",
}

type Pose = { [string]: CFrame }

local function motorsOf(character: Model): { [string]: Motor6D }
	local found: { [string]: Motor6D } = {}
	for _, name in MOTOR_NAMES do
		local motor = character:FindFirstChild(name, true)
		if motor and motor:IsA("Motor6D") then
			found[name] = motor
		end
	end
	return found
end

local function mix(windup: Pose, strike: Pose, alpha: number): Pose
	local out: Pose = {}
	local keys = {
		Waist = true,
		Neck = true,
		LeftShoulder = true,
		RightShoulder = true,
		LeftElbow = true,
		RightElbow = true,
		LeftHip = true,
		RightHip = true,
		LeftKnee = true,
		RightKnee = true,
	}
	for name in keys do
		local a = windup[name] or CFrame.new()
		local b = strike[name] or CFrame.new()
		out[name] = a:Lerp(b, alpha)
	end
	return out
end

local function guard(): Pose
	return {
		Waist = CFrame.Angles(math.rad(8), math.rad(-12), 0),
		Neck = CFrame.Angles(math.rad(-8), math.rad(10), 0),
		LeftShoulder = CFrame.Angles(math.rad(25), 0, math.rad(-40)),
		RightShoulder = CFrame.Angles(math.rad(30), 0, math.rad(50)),
		LeftElbow = CFrame.Angles(math.rad(-55), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-80), 0, 0),
		LeftHip = CFrame.Angles(math.rad(12), 0, math.rad(-6)),
		RightHip = CFrame.Angles(math.rad(16), 0, math.rad(6)),
		LeftKnee = CFrame.Angles(math.rad(-18), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-20), 0, 0),
	}
end

local function jab(side: number): (Pose, Pose)
	local wind = {
		Waist = CFrame.Angles(0, math.rad(18 * side), 0),
		RightShoulder = CFrame.Angles(math.rad(10), 0, math.rad(30)),
		LeftShoulder = CFrame.Angles(math.rad(10), 0, math.rad(-30)),
		RightElbow = CFrame.Angles(math.rad(-90), 0, 0),
		LeftElbow = CFrame.Angles(math.rad(-90), 0, 0),
	}
	local hit = {
		Waist = CFrame.Angles(math.rad(12), math.rad(-25 * side), 0),
		Neck = CFrame.Angles(math.rad(-6), 0, 0),
		RightShoulder = if side > 0 then CFrame.Angles(math.rad(80), 0, math.rad(20)) else CFrame.Angles(math.rad(20), 0, math.rad(40)),
		LeftShoulder = if side > 0 then CFrame.Angles(math.rad(20), 0, math.rad(-40)) else CFrame.Angles(math.rad(80), 0, math.rad(-20)),
		RightElbow = if side > 0 then CFrame.Angles(math.rad(-15), 0, 0) else CFrame.Angles(math.rad(-70), 0, 0),
		LeftElbow = if side > 0 then CFrame.Angles(math.rad(-70), 0, 0) else CFrame.Angles(math.rad(-15), 0, 0),
		LeftKnee = CFrame.Angles(math.rad(-12), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-8), 0, 0),
	}
	return wind, hit
end

local function kick(): (Pose, Pose)
	return {
		Waist = CFrame.Angles(math.rad(-8), 0, 0),
		RightHip = CFrame.Angles(math.rad(30), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-80), 0, 0),
	}, {
		Waist = CFrame.Angles(math.rad(16), math.rad(-10), 0),
		RightHip = CFrame.Angles(math.rad(-70), 0, math.rad(8)),
		RightKnee = CFrame.Angles(math.rad(-10), 0, 0),
		LeftKnee = CFrame.Angles(math.rad(-20), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(20), 0, math.rad(-30)),
		RightShoulder = CFrame.Angles(math.rad(20), 0, math.rad(30)),
	}
end

local function castPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(6), math.rad(8), 0),
		LeftShoulder = CFrame.Angles(math.rad(75), 0, math.rad(-25)),
		RightShoulder = CFrame.Angles(math.rad(80), 0, math.rad(30)),
		LeftElbow = CFrame.Angles(math.rad(-20), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-25), 0, 0),
	}
end

local function chargePose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(-8), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(40), math.rad(20), math.rad(-50)),
		RightShoulder = CFrame.Angles(math.rad(40), math.rad(-20), math.rad(50)),
		LeftElbow = CFrame.Angles(math.rad(-100), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-100), 0, 0),
		LeftKnee = CFrame.Angles(math.rad(-25), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-25), 0, 0),
	}
end

local function dashPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(28), 0, 0),
		Neck = CFrame.Angles(math.rad(-12), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(-30), 0, math.rad(-15)),
		RightShoulder = CFrame.Angles(math.rad(-30), 0, math.rad(15)),
		LeftHip = CFrame.Angles(math.rad(20), 0, 0),
		RightHip = CFrame.Angles(math.rad(-10), 0, 0),
	}
end

local function stompPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(20), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(-40), 0, math.rad(-20)),
		RightShoulder = CFrame.Angles(math.rad(-40), 0, math.rad(20)),
		LeftHip = CFrame.Angles(math.rad(10), 0, 0),
		RightHip = CFrame.Angles(math.rad(40), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-15), 0, 0),
	}
end

local function flightPose(moving: boolean): Pose
	local pitch = if moving then 78 else 25
	return {
		Waist = CFrame.Angles(math.rad(pitch), 0, 0),
		Neck = CFrame.Angles(math.rad(-pitch * 0.35), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(pitch * 0.9), 0, math.rad(-18)),
		RightShoulder = CFrame.Angles(math.rad(pitch * 0.9), 0, math.rad(18)),
		LeftElbow = CFrame.Angles(math.rad(-12), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-12), 0, 0),
		LeftHip = CFrame.Angles(math.rad(-18), 0, math.rad(-6)),
		RightHip = CFrame.Angles(math.rad(-18), 0, math.rad(6)),
		LeftKnee = CFrame.Angles(math.rad(-8), 0, 0),
		RightKnee = CFrame.Angles(math.rad(-8), 0, 0),
	}
end

local function hitPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(-18), math.rad(12), 0),
		Neck = CFrame.Angles(math.rad(16), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(-20), 0, math.rad(-15)),
		RightShoulder = CFrame.Angles(math.rad(-20), 0, math.rad(15)),
	}
end

local function knockPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(-40), math.rad(20), math.rad(10)),
		Neck = CFrame.Angles(math.rad(24), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(-50), 0, math.rad(-30)),
		RightShoulder = CFrame.Angles(math.rad(-40), 0, math.rad(40)),
		LeftHip = CFrame.Angles(math.rad(20), 0, 0),
		RightHip = CFrame.Angles(math.rad(-15), 0, 0),
	}
end

local function blockPose(): Pose
	return {
		Waist = CFrame.Angles(math.rad(6), 0, 0),
		LeftShoulder = CFrame.Angles(math.rad(50), 0, math.rad(-55)),
		RightShoulder = CFrame.Angles(math.rad(50), 0, math.rad(55)),
		LeftElbow = CFrame.Angles(math.rad(-90), 0, 0),
		RightElbow = CFrame.Angles(math.rad(-90), 0, 0),
	}
end

local function poseNow(name: string, alpha: number, moving: boolean): Pose?
	if name == "Punch1" or name == "Punch3" then
		local wind, hit = jab(1)
		return mix(wind, hit, alpha)
	elseif name == "Punch2" or name == "Flurry" then
		local wind, hit = jab(-1)
		return mix(wind, hit, alpha)
	elseif name == "Punch4" then
		local wind, hit = kick()
		return mix(wind, hit, alpha)
	elseif name == "Cast" or name == "Ult" then
		return mix(guard(), castPose(), alpha)
	elseif name == "Charge" then
		return mix(guard(), chargePose(), alpha)
	elseif name == "Dash" then
		return mix(guard(), dashPose(), math.clamp(alpha * 1.4, 0, 1))
	elseif name == "Stomp" then
		return mix(guard(), stompPose(), alpha)
	elseif name == "Flight" then
		return flightPose(moving)
	elseif name == "Hit" then
		return mix({}, hitPose(), alpha)
	elseif name == "Knockback" then
		return knockPose()
	elseif name == "Block" then
		return blockPose()
	elseif name == "Idle" then
		return guard()
	end
	return nil
end

type Clock = {
	token: number,
	elapsed: number,
	pausedUntil: number,
	smeared: boolean,
}

local clocks: { [Model]: Clock } = {}

local function smearGhost(character: Model)
	local folder = workspace:FindFirstChild("FightingClassVfx")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "FightingClassVfx"
		folder.Parent = workspace
	end
	for _, limbName in { "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm" } do
		local limb = character:FindFirstChild(limbName)
		if limb and limb:IsA("BasePart") then
			local ghost = Instance.new("Part")
			ghost.Name = "Smear"
			ghost.Size = limb.Size
			ghost.CFrame = limb.CFrame
			ghost.Color = limb.Color
			ghost.Material = Enum.Material.Neon
			ghost.Transparency = 0.55
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.CanQuery = false
			ghost.CanTouch = false
			ghost.Parent = folder
			Debris:AddItem(ghost, 0.045)
		end
	end
end

local ProceduralAnim = {}

function ProceduralAnim.Pause(character: Model, seconds: number)
	local clock = clocks[character]
	if not clock then
		clock = { token = -999, elapsed = 0, pausedUntil = 0, smeared = false }
		clocks[character] = clock
	end
	clock.pausedUntil = math.max(clock.pausedUntil, os.clock() + seconds)
end

local function weightFor(character: Model, active: boolean): number
	if character:GetAttribute("Ragdoll") == true then
		return 0.9
	end
	if active then
		return 0.92
	end
	if character:GetAttribute("Flying") == true then
		return 1
	end
	if character:GetAttribute("Blocking") == true and AnimationConfig.Clip("Block") == "" then
		return 0.85
	end
	local root = Util.Root(character)
	local speed = if root then Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude else 0
	local player = Players:GetPlayerFromCharacter(character)
	local inCombat = player ~= nil and player:GetAttribute("InCombat") == true
	if inCombat and speed < 3 and AnimationConfig.Clip("Idle") == "" then
		return 0.8
	end
	return 0
end

local function apply(character: Model, dt: number)
	local poseName = character:GetAttribute("Pose")
	local tokenAttr = character:GetAttribute("PoseToken")
	local duration = character:GetAttribute("PoseDuration")
	local token = if typeof(tokenAttr) == "number" then tokenAttr else 0
	local clock = clocks[character]
	if not clock or clock.token ~= token then
		clock = { token = token, elapsed = 0, pausedUntil = 0, smeared = false }
		clocks[character] = clock
	end
	if os.clock() >= clock.pausedUntil then
		clock.elapsed += dt
	end
	local elapsed = clock.elapsed
	local active = false
	local alpha = 1
	if typeof(poseName) == "string" and poseName ~= "" and typeof(duration) == "number" and AnimationConfig.Clip(poseName) == "" then
		if elapsed <= duration then
			active = true
			alpha = math.clamp(elapsed / math.max(duration, 0.05), 0, 1)
		end
	end
	if character:GetAttribute("Ragdoll") == true then
		poseName = "Knockback"
		active = true
		alpha = 1
	elseif character:GetAttribute("Flying") == true and not active then
		poseName = "Flight"
		active = true
	elseif character:GetAttribute("Blocking") == true and not active then
		poseName = "Block"
		active = true
		alpha = 1
	elseif not active then
		poseName = "Idle"
	end
	local name = if typeof(poseName) == "string" then poseName else ""
	local weight = weightFor(character, name ~= "Idle")
	if weight <= 0 then
		return
	end
	local root = Util.Root(character)
	local moving = root ~= nil and root.AssemblyLinearVelocity.Magnitude > 10
	local owner = Players:GetPlayerFromCharacter(character)
	local classId = if owner then Util.ReadString(owner:GetAttribute("ClassId"), "") else ""
	local pose = if name == "Idle" then PoseLibrary.Stance(classId) else PoseLibrary.Sample(name, elapsed)
	if not pose then
		pose = poseNow(name, alpha, moving)
	end
	if not pose then
		return
	end
	if (name == "Hit" or name == "Knockback") and root then
		local from = character:GetAttribute("HitFrom")
		if typeof(from) == "Vector3" then
			local flat = Vector3.new(from.X - root.Position.X, 0, from.Z - root.Position.Z)
			local side = root.CFrame.RightVector
			if flat.Magnitude > 0.2 then
				local yaw = math.clamp(flat.Unit:Dot(side), -1, 1) * 0.7
				local waist = pose.Waist or CFrame.new()
				pose.Waist = waist * CFrame.Angles(0.4, yaw, 0)
			end
		end
	end
	if PoseLibrary.InSmear(name, elapsed) then
		if not clock.smeared then
			clock.smeared = true
			smearGhost(character)
		end
	else
		clock.smeared = false
	end
	local joints = motorsOf(character)
	local snap = PoseLibrary.InSmear(name, elapsed)
	local blend = if snap then 1 else math.clamp(weight * (0.55 + (1 - math.exp(-dt * 16))), 0, 1)
	for motorName, motor in joints do
		local goal = pose[motorName] or CFrame.new()
		motor.Transform = motor.Transform:Lerp(goal, blend)
	end
end

function ProceduralAnim.Start()
	RunService.BindToRenderStep("FightingPoses", Enum.RenderPriority.Last.Value, function(dt)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				apply(character, dt)
			end
		end
	end)
end

return ProceduralAnim
