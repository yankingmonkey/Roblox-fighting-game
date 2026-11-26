--!strict
-- Hitstop, impact frames, shake, and a short ultimate camera.
-- Presentation only. Damage stays on the server.
-- Shake is a one-frame offset on top of the camera, then thrown away, so it cannot drift.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Replicated = game:GetService("ReplicatedStorage"):WaitForChild("FightingClasses")
local Actions = require(Replicated.Shared.Actions)
local ClientSettings = require(script.Parent.ClientSettings)
local ProceduralAnim = require(script.Parent.ProceduralAnim)

local CombatFeel = {}

local correction = Instance.new("ColorCorrectionEffect")
correction.Name = "FightingImpact"
correction.Parent = Lighting

local shakeMag = 0
local shakeLeft = 0
local fovLeft = 0
local storedFov: number? = nil
local camToken = 0

local function tracksOf(model: Model): { AnimationTrack }
	local list = {}
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			table.insert(list, track)
		end
	end
	return list
end

local function hitstop(model: Model?, seconds: number)
	if not model or seconds <= 0 then
		return
	end
	ProceduralAnim.Pause(model, seconds)
	local speeds = {}
	for _, track in tracksOf(model) do
		speeds[track] = track.Speed
		track:AdjustSpeed(0)
	end
	task.delay(seconds, function()
		for track, speed in speeds do
			pcall(function()
				track:AdjustSpeed(if speed > 0 then speed else 1)
			end)
		end
	end)
end

local function flash(mode: string, duration: number)
	if not ClientSettings.ImpactFlashes or duration <= 0 then
		return
	end
	if mode == "Black" then
		correction.Saturation = -1
		correction.Contrast = -3
		correction.Brightness = -0.15
		correction.TintColor = Color3.fromRGB(163, 162, 165)
	elseif mode == "Invert" then
		correction.Saturation = -1
		correction.Contrast = -1
		correction.Brightness = 0
		correction.TintColor = Color3.new(1, 1, 1)
	else
		correction.Saturation = -1
		correction.Contrast = 2
		correction.Brightness = 0.35
		correction.TintColor = Color3.fromRGB(220, 220, 225)
	end
	task.delay(duration, function()
		correction.Saturation = 0
		correction.Contrast = 0
		correction.Brightness = 0
		correction.TintColor = Color3.new(1, 1, 1)
	end)
end

function CombatFeel.Shake(amplitude: number, duration: number)
	if not ClientSettings.Shake then
		return
	end
	local scaled = amplitude * ClientSettings.ShakeScale
	shakeMag = math.max(shakeMag, scaled)
	shakeLeft = math.max(shakeLeft, duration)
end

function CombatFeel.Fov(delta: number, duration: number)
	local camera = workspace.CurrentCamera
	if not camera or delta == 0 then
		return
	end
	if storedFov == nil then
		storedFov = camera.FieldOfView
	end
	local base = storedFov
	camera.FieldOfView = math.clamp(base + delta, 1, 120)
	fovLeft = duration
end

local function restoreCamera(token: number)
	if token ~= camToken then
		return
	end
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		if storedFov then
			camera.FieldOfView = storedFov
		end
	end
	storedFov = nil
end

function CombatFeel.UltimateCamera(character: Model)
	if not ClientSettings.UltimateCamera then
		return
	end
	local camera = workspace.CurrentCamera
	local root = character:FindFirstChild("HumanoidRootPart")
	if not camera or not root or not root:IsA("BasePart") then
		return
	end
	camToken += 1
	local token = camToken
	if storedFov == nil then
		storedFov = camera.FieldOfView
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local focus = root.Position + Vector3.new(0, 2, 0)
	local goal = CFrame.new(focus + root.CFrame.RightVector * 8 + Vector3.new(0, 3, 0) - root.CFrame.LookVector * 6, focus)
	camera.Focus = CFrame.new(focus)
	TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = goal }):Play()
	task.spawn(function()
		local elapsed = 0
		while elapsed < 0.7 and token == camToken and character.Parent do
			if character:GetAttribute("Stunned") == true or character:GetAttribute("Ragdoll") == true then
				break
			end
			local step = task.wait()
			elapsed += step
			local live = character:FindFirstChild("HumanoidRootPart")
			if live and live:IsA("BasePart") then
				local look = live.Position + Vector3.new(0, 2, 0)
				camera.Focus = CFrame.new(look)
			end
		end
		restoreCamera(token)
	end)
end

function CombatFeel.Handle(payload: { [string]: any })
	local attacker = if typeof(payload.attackerUserId) == "number"
		then Players:GetPlayerByUserId(payload.attackerUserId)
		else nil
	local victim = if typeof(payload.victimUserId) == "number" then Players:GetPlayerByUserId(payload.victimUserId) else nil
	local attackerChar = attacker and attacker.Character
	local victimChar = victim and victim.Character
	local hitstopTime = if typeof(payload.hitstop) == "number" then payload.hitstop else 0
	local victimTime = if typeof(payload.victimHitstop) == "number" then payload.victimHitstop else hitstopTime
	hitstop(attackerChar, hitstopTime)
	hitstop(victimChar, victimTime)
	if typeof(payload.impactFrame) == "string" then
		local duration = if typeof(payload.impactFrameDuration) == "number" then payload.impactFrameDuration else 0.05
		flash(payload.impactFrame, duration)
	end
	local amp = if typeof(payload.shakeAmplitude) == "number" then payload.shakeAmplitude else 0
	local shakeDur = if typeof(payload.shakeDuration) == "number" then payload.shakeDuration else 0
	if amp > 0 then
		local root = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		local pos = payload.position
		local dist = 0
		if root and root:IsA("BasePart") and typeof(pos) == "Vector3" then
			dist = (root.Position - pos).Magnitude
		end
		if dist < 80 then
			CombatFeel.Shake(amp * (1 - dist / 80), shakeDur)
		end
	end
	local fov = if typeof(payload.fovDelta) == "number" then payload.fovDelta else 0
	local fovDur = if typeof(payload.fovDuration) == "number" then payload.fovDuration else 0.12
	if fov ~= 0 and (attacker == Players.LocalPlayer or victim == Players.LocalPlayer) then
		CombatFeel.Fov(fov, fovDur)
	end
	if payload.ultimateCamera == true and attackerChar and attacker == Players.LocalPlayer then
		CombatFeel.UltimateCamera(attackerChar)
	end
end

function CombatFeel.Start()
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local notify = remotes:WaitForChild("Notify") :: RemoteEvent
	notify.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) == "table" and payload.action == Actions.HitFeel then
			CombatFeel.Handle(payload)
		end
	end)
	RunService:BindToRenderStep("CombatFeelCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		if shakeLeft > 0 and camera.CameraType ~= Enum.CameraType.Scriptable then
			shakeLeft = math.max(0, shakeLeft - dt)
			local mag = shakeMag * math.clamp(shakeLeft * 4, 0, 1)
			local rx = (math.noise(os.clock() * 24) - 0.5) * mag * 0.08
			local ry = (math.noise(os.clock() * 19, 3) - 0.5) * mag * 0.08
			camera.CFrame = camera.CFrame * CFrame.Angles(rx, ry, 0)
			if shakeLeft <= 0 then
				shakeMag = 0
			end
		elseif shakeLeft > 0 then
			shakeLeft = math.max(0, shakeLeft - dt)
		end
		if fovLeft > 0 and storedFov then
			fovLeft = math.max(0, fovLeft - dt)
			if fovLeft <= 0 then
				camera.FieldOfView = storedFov
				storedFov = nil
			end
		end
	end)
end

return CombatFeel
