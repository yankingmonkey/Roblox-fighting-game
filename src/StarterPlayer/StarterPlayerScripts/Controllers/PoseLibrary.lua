--!strict
-- One pose sequence per move: wind-up, strike, follow-through, recovery.
-- Named moves below are hand-posed. Every other ability id gets its own
-- sequence from a hash, so two moves never share the same motion.
-- Paste an id in AnimationConfig under the ability id to replace the sequence.

local PoseLibrary = {}

type Pose = { [string]: CFrame }
type Frame = { t: number, pose: Pose }

local function ang(x: number, y: number, z: number): CFrame
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end

local function pose(wx: number, wy: number, rsx: number, lsx: number, rex: number, lex: number, rhx: number, lhx: number): Pose
	return {
		Waist = ang(wx, wy, 0),
		Neck = ang(-wx * 0.3, -wy * 0.2, 0),
		RightShoulder = ang(rsx, 0, 25),
		LeftShoulder = ang(lsx, 0, -25),
		RightElbow = ang(rex, 0, 0),
		LeftElbow = ang(lex, 0, 0),
		RightHip = ang(rhx, 0, 6),
		LeftHip = ang(lhx, 0, -6),
		RightKnee = ang(math.min(0, rhx * 0.4), 0, 0),
		LeftKnee = ang(math.min(0, lhx * 0.4), 0, 0),
	}
end

local function frames(a: Pose, b: Pose, c: Pose, d: Pose): { Frame }
	return {
		{ t = 0, pose = a },
		{ t = 0.28, pose = b },
		{ t = 0.52, pose = c },
		{ t = 1, pose = d },
	}
end

local function mix(a: Pose, b: Pose, alpha: number): Pose
	local out: Pose = {}
	for name, cf in a do
		out[name] = cf:Lerp(b[name] or CFrame.new(), alpha)
	end
	for name, cf in b do
		if out[name] == nil then
			out[name] = cf
		end
	end
	return out
end

local function sample(list: { Frame }, alpha: number): Pose
	local previous = list[1]
	for index = 2, #list do
		local nxt = list[index]
		if alpha <= nxt.t then
			local span = math.max(nxt.t - previous.t, 0.001)
			return mix(previous.pose, nxt.pose, (alpha - previous.t) / span)
		end
		previous = nxt
	end
	return list[#list].pose
end

local crafted: { [string]: { Frame } } = {
	Punch1 = frames(pose(4, 20, 15, 20, -80, -50, 8, 10), pose(6, 8, 40, 20, -40, -50, 8, 10), pose(10, -18, 85, 15, -8, -40, 6, 8), pose(4, 0, 30, 20, -40, -40, 6, 8)),
	Punch2 = frames(pose(4, -20, 20, 15, -50, -80, 10, 8), pose(6, -8, 20, 40, -50, -40, 8, 8), pose(10, 18, 15, 85, -40, -8, 8, 6), pose(4, 0, 20, 30, -40, -40, 8, 6)),
	Punch3 = frames(pose(2, 30, 10, 25, -100, -40, 12, 8), pose(-4, 10, 50, 20, -70, -40, 10, 8), pose(8, -40, 70, 10, -20, -30, 6, 10), pose(4, -8, 25, 20, -50, -40, 8, 8)),
	Punch4 = frames(pose(-6, 8, 15, 15, -30, -30, 40, 10), pose(-10, 6, 10, 10, -20, -20, 20, 16), pose(14, -12, 20, 10, -20, -20, -75, 18), pose(6, 0, 15, 15, -30, -30, 10, 12)),
	HeavyPunch = frames(pose(6, 35, -10, 20, -110, -40, 14, 8), pose(-8, 20, 20, 15, -90, -40, 12, 8), pose(16, -45, 100, 10, -5, -30, 4, 12), pose(6, -10, 30, 18, -40, -40, 8, 8)),
	Uppercut = frames(pose(20, 6, 30, 20, -100, -50, 30, 20), pose(28, 4, 10, 15, -80, -40, 36, 18), pose(-12, -8, 120, 10, -15, -20, 8, 10), pose(4, 0, 40, 20, -40, -40, 10, 10)),
	GroundSlam = frames(pose(-20, 0, -30, -30, -20, -20, -10, -10), pose(-35, 0, -50, -50, -10, -10, 10, 10), pose(30, 0, 20, 20, -40, -40, 35, 35), pose(8, 0, 15, 15, -30, -30, 12, 12)),
	GrabToss = frames(pose(12, 10, 70, 70, -20, -20, 10, 10), pose(8, -15, 80, 60, -10, -30, 8, 12), pose(6, 40, 20, 90, -40, -10, 6, 8), pose(4, 8, 25, 25, -50, -50, 8, 8)),
	Lariat = frames(pose(4, -50, 10, 40, -40, -70, 8, 8), pose(6, 10, 40, 20, -20, -40, 6, 6), pose(8, 80, 90, 10, -10, -30, 4, 8), pose(4, 20, 30, 20, -40, -40, 8, 8)),
	ShoulderCharge = frames(pose(20, 0, -20, -20, -30, -30, 25, 10), pose(40, 0, -10, -10, -20, -20, 30, -10), pose(28, 0, 10, 10, -40, -40, 10, 20), pose(8, 0, 15, 15, -30, -30, 8, 8)),
	CraterDrop = frames(pose(-25, 0, -40, -40, -15, -15, -15, -15), pose(-40, 0, -60, -60, -5, -5, 5, 5), pose(34, 0, 25, 25, -50, -50, 40, 40), pose(10, 0, 15, 15, -25, -25, 14, 14)),
	QuakeLine = frames(pose(10, 20, 20, -10, -60, -20, 12, 8), pose(6, -10, 40, 10, -30, -20, 8, 10), pose(22, -30, 70, 15, -10, -30, 20, 12), pose(6, 0, 20, 15, -35, -35, 8, 8)),
	RisingKick = frames(pose(-4, 12, 10, 10, -20, -20, 25, 8), pose(-12, 8, 8, 8, -15, -15, 10, 16), pose(18, -16, 15, 8, -15, -15, -80, 20), pose(4, 0, 12, 12, -25, -25, 8, 10)),
	SpiralPalm = frames(pose(6, -30, 40, 20, -90, -40, 8, 8), pose(4, 0, 70, 15, -40, -30, 6, 6), pose(10, 35, 95, 10, -8, -25, 4, 8), pose(4, 6, 25, 18, -40, -40, 8, 8)),
	PowerPunch = frames(pose(8, 28, 5, 25, -100, -35, 16, 8), pose(-4, 12, 30, 15, -70, -30, 12, 8), pose(14, -30, 105, 8, -4, -25, 4, 10), pose(4, 0, 28, 18, -40, -40, 8, 8)),
	DiveBomb = frames(pose(-30, 0, 80, 80, -10, -10, -20, -20), pose(-10, 0, 40, 40, -20, -20, 10, 10), pose(32, 0, 15, 15, -45, -45, 38, 38), pose(8, 0, 12, 12, -20, -20, 10, 10)),
}

local function hash(id: string): number
	local value = 0
	for index = 1, #id do
		value = (value * 33 + string.byte(id, index)) % 1000003
	end
	return value
end

local function generated(id: string): { Frame }
	local n = hash(id)
	local side = if n % 2 == 0 then 1 else -1
	local mag = 12 + (n % 28)
	local style = n % 6
	if style == 0 then
		return frames(
			pose(4, 10 * side, 20, 15, -70, -40, 8, 8),
			pose(6, 0, 50, 20, -30, -30, 6, 6),
			pose(10, -16 * side, 80 + mag / 5, 20, -8, -25, 4, 8),
			pose(4, 0, 22, 18, -35, -35, 8, 8)
		)
	elseif style == 1 then
		return frames(
			pose(16, 6, 25, 20, -90, -40, 24, 16),
			pose(24, 2, 8, 12, -70, -30, 30, 14),
			pose(-8, -6 * side, 110, 10, -12, -18, 8, 8),
			pose(4, 0, 30, 16, -40, -35, 8, 8)
		)
	elseif style == 2 then
		return frames(
			pose(-8, 8, 10, 10, -20, -20, 30, 10),
			pose(-14, 4, 8, 8, -12, -12, 12, 16),
			pose(16, -10 * side, 12, 8, -12, -12, if side > 0 then -70 else 16, if side > 0 then 16 else -70),
			pose(4, 0, 12, 12, -20, -20, 8, 8)
		)
	elseif style == 3 then
		return frames(
			pose(-16, 0, -20, -20, -15, -15, -8, -8),
			pose(-28, 0, -40, -40, -8, -8, 8, 8),
			pose(26, 0, 18, 18, -36, -36, 32, 32),
			pose(6, 0, 12, 12, -22, -22, 10, 10)
		)
	elseif style == 4 then
		return frames(
			pose(6, -20 * side, 15, 60, -40, -80, 8, 8),
			pose(4, 0, 30, 40, -20, -30, 6, 6),
			pose(8, 24 * side, 20, 90, -30, -8, 6, 6),
			pose(4, 4, 18, 22, -40, -40, 8, 8)
		)
	end
	return frames(
		pose(8, 12, 70, 70, -15, -15, 8, 8),
		pose(4, -8, 85, 40, -8, -30, 6, 8),
		pose(10, 16 * side, 30, 20, -40, -20, 6, 6),
		pose(4, 0, 20, 20, -35, -35, 8, 8)
	)
end

function PoseLibrary.Sample(name: string, alpha: number): Pose?
	if name == "Idle" or name == "Flight" or name == "Block" or name == "Hit" or name == "Knockback" or name == "" then
		return nil
	end
	local list = crafted[name]
	if not list then
		list = generated(name)
		crafted[name] = list
	end
	return sample(list, math.clamp(alpha, 0, 1))
end

return PoseLibrary
