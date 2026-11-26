--!strict
-- Plays the authored anticipation / smear / contact / recovery row for a move.
-- Class idles are separate stances. There is no shared punch cycle.

local MoveAnims = require(game:GetService("ReplicatedStorage").FightingClasses.Shared.MoveAnims)

local PoseLibrary = {}

type Pose = { [string]: CFrame }

local function ang(x: number, y: number, z: number): CFrame
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function fromRow(row: { number }): Pose
	local wx, wy, rs, re, ls, le, rh, lh = row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8]
	return {
		Waist = ang(wx, wy, 0),
		Neck = ang(-wx * 0.25, -wy * 0.15, 0),
		RightShoulder = ang(rs, 0, 22),
		LeftShoulder = ang(ls, 0, -22),
		RightElbow = ang(re, 0, 0),
		LeftElbow = ang(le, 0, 0),
		RightHip = ang(rh, 0, 6),
		LeftHip = ang(lh, 0, -6),
		RightKnee = ang(math.min(0, rh * 0.35), 0, 0),
		LeftKnee = ang(math.min(0, lh * 0.35), 0, 0),
	}
end

local function mix(a: Pose, b: Pose, alpha: number): Pose
	local out: Pose = {}
	for name, cf in a do
		out[name] = cf:Lerp(b[name] or CFrame.new(), alpha)
	end
	return out
end

local function easeIn(alpha: number): number
	return alpha * alpha
end

local function easeOut(alpha: number): number
	local inv = 1 - alpha
	return 1 - inv * inv
end

local STANCE: { [string]: { number } } = {
	-- Ki: wide, both fists chambered.
	KiWarrior = { 6, 0, -18, -78, -18, -78, 14, 14 },
	-- Brawler: low lead shoulder, rear hand at the cheek.
	Brawler = { 12, -18, 28, -88, 8, -42, 22, 10 },
	-- Speedster: high guard, light knees.
	Speedster = { 4, 8, 42, -70, 48, -74, 16, 18 },
	-- Elemental: one hand offered, the other at the chest.
	Elemental = { 4, 10, 55, -28, 20, -80, 8, 12 },
	-- Ninja: crouch, rear hand loaded.
	Ninja = { 16, 20, -24, -96, 30, -60, 24, 18 },
	-- Superhero: chest tall, fists low and ready.
	Superhero = { -4, 0, 8, -28, 8, -28, 6, 6 },
}

function PoseLibrary.Stance(classId: string): Pose
	return fromRow(STANCE[classId] or STANCE.KiWarrior)
end

function PoseLibrary.Sample(name: string, elapsed: number): Pose?
	local row = MoveAnims[name]
	if not row then
		return nil
	end
	local phases = row.phases
	local antic = row.anticipation
	local smearEnd = antic + row.smear
	local contactEnd = smearEnd + row.contact
	local poses = {
		fromRow(phases[1]),
		fromRow(phases[2]),
		fromRow(phases[3]),
		fromRow(phases[4]),
	}
	if elapsed <= 0 then
		return poses[1]
	end
	if elapsed < antic then
		-- Ease into the coil. Do not start on the idle pose.
		return mix(poses[4], poses[1], easeIn(elapsed / math.max(antic, 0.001)))
	end
	if elapsed < smearEnd then
		-- Linear snap through the overshoot. No ease into the hit.
		local alpha = (elapsed - antic) / math.max(row.smear, 0.001)
		return mix(poses[1], poses[2], alpha)
	end
	if elapsed < contactEnd then
		-- Hold the contact key. Hitstop freezes the clock on top of this.
		return poses[3]
	end
	local alpha = (elapsed - contactEnd) / math.max(row.recovery, 0.001)
	return mix(poses[3], poses[4], easeOut(math.clamp(alpha, 0, 1)))
end

function PoseLibrary.InSmear(name: string, elapsed: number): boolean
	local row = MoveAnims[name]
	if not row then
		return false
	end
	return elapsed >= row.anticipation and elapsed < row.anticipation + row.smear
end

return PoseLibrary
